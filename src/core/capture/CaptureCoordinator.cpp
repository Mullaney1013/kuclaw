#include "core/capture/CaptureCoordinator.h"

#include <QApplication>
#include <QDateTime>
#include <QDir>
#include <QFileDialog>
#include <QGuiApplication>
#include <QImage>
#include <QPainter>
#include <QScreen>
#include <QStandardPaths>
#include <QWindow>

#include "core/clipboard/ClipboardManager.h"
#include "core/settings/SettingsManager.h"

namespace {

QRect physicalRectForLogicalRect(const QRect& logicalRect,
                                 const CaptureDisplaySegment& segment) {
    const QRect intersection = logicalRect.intersected(segment.logicalRect);
    if (!intersection.isValid() || intersection.isEmpty()) {
        return {};
    }

    const qreal scaleX =
        static_cast<qreal>(segment.pixelRect.width()) / segment.logicalRect.width();
    const qreal scaleY =
        static_cast<qreal>(segment.pixelRect.height()) / segment.logicalRect.height();

    const int left = segment.pixelRect.x()
        + qFloor((intersection.x() - segment.logicalRect.x()) * scaleX);
    const int top = segment.pixelRect.y()
        + qFloor((intersection.y() - segment.logicalRect.y()) * scaleY);
    const int right = segment.pixelRect.x()
        + qCeil((intersection.x() + intersection.width() - segment.logicalRect.x()) * scaleX);
    const int bottom = segment.pixelRect.y()
        + qCeil((intersection.y() + intersection.height() - segment.logicalRect.y()) * scaleY);

    return QRect(left,
                 top,
                 qMax(1, right - left),
                 qMax(1, bottom - top));
}

QString sanitizeFileNamePart(QString text) {
    text = text.trimmed();
    if (text.isEmpty()) {
        return {};
    }

    static const QString invalidCharacters = QStringLiteral("<>:\"/\\|?*");
    for (const QChar ch : invalidCharacters) {
        text.replace(ch, QChar('-'));
    }

    text.replace(QChar(' '), QChar('-'));
    text.replace(QChar('\t'), QChar('-'));
    while (text.contains(QStringLiteral("--"))) {
        text.replace(QStringLiteral("--"), QStringLiteral("-"));
    }

    text.remove(QChar('.'));
    text.remove(QChar('\n'));
    text.remove(QChar('\r'));
    text = text.trimmed();
    if (text.isEmpty()) {
        return {};
    }

    constexpr int kMaxPartLength = 48;
    if (text.size() > kMaxPartLength) {
        text = text.left(kMaxPartLength);
    }

    return text;
}

QString defaultFileBaseNameForResult(const SelectionResult& result) {
    const QString appPart = sanitizeFileNamePart(result.ownerAppName);
    const QString timestamp =
        QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd-HHmmss"));

    if (!appPart.isEmpty()
        && appPart != QStringLiteral("自由框选")
        && appPart != QStringLiteral("当前屏幕")) {
        return QStringLiteral("kuclaw-%1-%2").arg(appPart, timestamp);
    }

    if (result.ownerAppName == QStringLiteral("当前屏幕")) {
        return QStringLiteral("kuclaw-screen-%1").arg(timestamp);
    }

    if (result.ownerAppName == QStringLiteral("自由框选")) {
        return QStringLiteral("kuclaw-selection-%1").arg(timestamp);
    }

    return QStringLiteral("kuclaw-%1").arg(timestamp);
}

}  // namespace

CaptureCoordinator::CaptureCoordinator(std::unique_ptr<INativeScreenHelper> helper,
                                       ClipboardManager* clipboardManager,
                                       SettingsManager* settingsManager,
                                       QObject* parent)
    : QObject(parent),
      helper_(std::move(helper)),
      clipboardManager_(clipboardManager),
      settingsManager_(settingsManager) {
    prepareTimer_.setSingleShot(true);
    prepareTimer_.setInterval(90);
    connect(&prepareTimer_, &QTimer::timeout,
            this, &CaptureCoordinator::performCapture);
}

void CaptureCoordinator::triggerCapture() {
    if (captureActive_ || helper_ == nullptr) {
        return;
    }

    QString errorMessage;
    if (!helper_->ensurePermissions(&errorMessage)) {
        finishError(errorMessage.isEmpty()
                        ? QStringLiteral("截图权限检查失败。")
                        : errorMessage);
        return;
    }

    setCaptureActive(true);

    if (settingsManager_ != nullptr
        && !settingsManager_->keepCurrentWindowOnCapture()) {
        hideOwnWindowsForCapture();
        prepareTimer_.start();
        return;
    }

    performCapture();
}

void CaptureCoordinator::cancelCapture() {
    if (!captureActive_) {
        return;
    }

    emit captureCanceling();

    if (prepareTimer_.isActive()) {
        prepareTimer_.stop();
    }

    closeOverlays();

    finishCanceled();
}

bool CaptureCoordinator::isCaptureActive() const {
    return captureActive_;
}

QString CaptureCoordinator::backendName() const {
    return helper_ == nullptr ? QStringLiteral("unavailable")
                              : helper_->backendName();
}

void CaptureCoordinator::performCapture() {
    if (helper_ == nullptr) {
        finishError(QStringLiteral("Native screen helper unavailable."));
        return;
    }

    currentCapture_ = helper_->captureFrozenDesktop();
    if (currentCapture_.frozenDesktop.isNull()
        || !currentCapture_.virtualDesktopRect.isValid()) {
        finishError(QStringLiteral("冻结桌面抓取失败。"));
        return;
    }

    if (settingsManager_ != nullptr
        && settingsManager_->keepCurrentWindowOnCapture()) {
        hidePrimaryWindowForInteraction();
    }

    const QVector<WindowCandidate> candidates =
        helper_->enumerateWindowCandidates(currentCapture_.virtualDesktopRect);

    closeOverlays();

    QVector<QRect> screenGeometries;
    const auto screens = QGuiApplication::screens();
    screenGeometries.reserve(screens.size());
    for (QScreen* screen : screens) {
        if (screen == nullptr) {
            continue;
        }

        const QRect geometry =
            screen->geometry().intersected(currentCapture_.virtualDesktopRect);
        if (geometry.isValid() && !geometry.isEmpty()) {
            screenGeometries.push_back(geometry);
        }
    }

    if (screenGeometries.isEmpty()) {
        screenGeometries.push_back(currentCapture_.virtualDesktopRect);
    }

    overlays_.reserve(screenGeometries.size());
    for (const QRect& screenGeometry : screenGeometries) {
        auto* overlay = new FreezeOverlayWidget();
        overlay->setCaptureData(currentCapture_, candidates);
        overlay->setScreenGeometry(screenGeometry);
        overlay->setMagnifierEnabled(settingsManager_ == nullptr
                                         ? true
                                         : settingsManager_->magnifierEnabled());
        overlay->setDefaultColorFormat(settingsManager_ == nullptr
                                           ? QStringLiteral("RGB")
                                           : settingsManager_->defaultColorFormat());

        connect(overlay, &FreezeOverlayWidget::selectionConfirmed, this,
                [this](const SelectionResult& result) {
                    completeCopy(result);
                });
        connect(overlay, &FreezeOverlayWidget::selectionSaveRequested, this,
                [this, overlay](const SelectionResult& result) {
                    completeSave(result, overlay);
                });
        connect(overlay, &FreezeOverlayWidget::colorPicked, this,
                [this](const QString& colorValue,
                       const QString& swatchHex,
                       const QPoint& globalPoint) {
                    if (clipboardManager_ != nullptr) {
                        clipboardManager_->setText(colorValue);
                    }
                    emit colorCopied(colorValue, swatchHex, globalPoint);
                });
        connect(overlay, &FreezeOverlayWidget::selectionCanceled, this,
                [this]() {
                    emit captureCanceling();
                    closeOverlays();
                    finishCanceled();
                });

        overlays_.push_back(overlay);
        overlay->show();
        overlay->raise();
        overlay->activateWindow();
    }
}

void CaptureCoordinator::closeOverlays() {
    const auto overlays = overlays_;
    overlays_.clear();

    for (const auto& overlay : overlays) {
        if (overlay == nullptr) {
            continue;
        }

        overlay->close();
    }
}

QImage CaptureCoordinator::selectedImageForResult(const SelectionResult& result) const {
    if (currentCapture_.frozenDesktop.isNull()) {
        return {};
    }

    const QRect globalLogicalRect =
        result.overlayRect.translated(currentCapture_.virtualDesktopRect.topLeft());

    QVector<QRect> sourceRects;
    QRect physicalUnion;
    sourceRects.reserve(currentCapture_.displaySegments.size());
    for (const auto& segment : currentCapture_.displaySegments) {
        const QRect sourceRect = physicalRectForLogicalRect(globalLogicalRect, segment);
        if (!sourceRect.isValid() || sourceRect.isEmpty()) {
            continue;
        }

        sourceRects.push_back(sourceRect);
        physicalUnion = physicalUnion.united(sourceRect);
    }

    if (!physicalUnion.isValid() || physicalUnion.isEmpty()) {
        return {};
    }

    QImage selectedImage(physicalUnion.size(), QImage::Format_ARGB32_Premultiplied);
    selectedImage.fill(Qt::transparent);

    QPainter painter(&selectedImage);
    for (const QRect& sourceRect : sourceRects) {
        const QRect targetRect = sourceRect.translated(-physicalUnion.topLeft());
        painter.drawImage(targetRect, currentCapture_.frozenDesktop, sourceRect);
    }
    painter.end();

    return selectedImage;
}

void CaptureCoordinator::completeCopy(const SelectionResult& result) {
    const QImage selectedImage = selectedImageForResult(result);
    if (selectedImage.isNull()) {
        finishError(QStringLiteral("选区无效，无法导出截图。"));
        return;
    }

    if (clipboardManager_ != nullptr) {
        clipboardManager_->setImage(selectedImage);
    }

    emit captureCompleting();
    finishCompleted(result, selectedImage);
}

void CaptureCoordinator::completeSave(const SelectionResult& result,
                                      QWidget* dialogParent) {
    const QImage selectedImage = selectedImageForResult(result);
    if (selectedImage.isNull()) {
        finishError(QStringLiteral("选区无效，无法导出截图。"));
        return;
    }

    QString picturesDir = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    if (picturesDir.isEmpty()) {
        picturesDir = QDir::homePath();
    }

    const QString defaultPath =
        picturesDir
        + QStringLiteral("/%1.png").arg(defaultFileBaseNameForResult(result));

    const QString selectedPath = QFileDialog::getSaveFileName(
        dialogParent,
        QStringLiteral("保存截图"),
        defaultPath,
        QStringLiteral("PNG Image (*.png)"));

    if (selectedPath.isEmpty()) {
        return;
    }

    if (!selectedImage.save(selectedPath)) {
        emit captureError(QStringLiteral("截图保存失败：%1").arg(selectedPath));
        return;
    }

    emit captureCompleting();
    finishCompleted(result, selectedImage);
}

void CaptureCoordinator::finishCanceled() {
    closeOverlays();
    restoreHiddenWindows(false);
    currentCapture_ = {};
    setCaptureActive(false);
    emit captureCanceled();
}

void CaptureCoordinator::finishError(const QString& message) {
    closeOverlays();
    restoreHiddenWindows(true);
    currentCapture_ = {};
    setCaptureActive(false);
    emit captureError(message);
}

void CaptureCoordinator::finishCompleted(const SelectionResult& result, const QImage& image) {
    closeOverlays();
    restoreHiddenWindows(false);
    currentCapture_ = {};
    setCaptureActive(false);
    emit captureCompleted(result, image);
}

void CaptureCoordinator::hideOwnWindowsForCapture() {
    hiddenWindows_.clear();

    const auto topLevelWindows = QGuiApplication::topLevelWindows();
    for (QWindow* window : topLevelWindows) {
        if (window == nullptr || !window->isVisible()) {
            continue;
        }

        hiddenWindows_.push_back({
            window,
            static_cast<int>(window->visibility()),
            window->objectName() == QStringLiteral("KuclawMainWindow"),
        });
        window->hide();
    }
}

void CaptureCoordinator::hidePrimaryWindowForInteraction() {
    for (const auto& state : hiddenWindows_) {
        if (state.isPrimaryWindow && state.window != nullptr) {
            return;
        }
    }

    const auto topLevelWindows = QGuiApplication::topLevelWindows();
    for (QWindow* window : topLevelWindows) {
        if (window == nullptr
            || !window->isVisible()
            || window->objectName() != QStringLiteral("KuclawMainWindow")) {
            continue;
        }

        hiddenWindows_.push_back({
            window,
            static_cast<int>(window->visibility()),
            true,
        });
        window->hide();
        return;
    }
}

void CaptureCoordinator::restoreHiddenWindows(const bool includePrimaryWindow) {
    for (const auto& state : hiddenWindows_) {
        if (state.window == nullptr) {
            continue;
        }

        if (!includePrimaryWindow && state.isPrimaryWindow) {
            continue;
        }

        switch (static_cast<QWindow::Visibility>(state.visibility)) {
        case QWindow::FullScreen:
            state.window->showFullScreen();
            break;
        case QWindow::Maximized:
            state.window->showMaximized();
            break;
        case QWindow::Minimized:
            state.window->showMinimized();
            break;
        case QWindow::Hidden:
            break;
        case QWindow::AutomaticVisibility:
        case QWindow::Windowed:
        default:
            state.window->show();
            break;
        }
    }

    hiddenWindows_.clear();
}

void CaptureCoordinator::setCaptureActive(const bool active) {
    if (captureActive_ == active) {
        return;
    }

    captureActive_ = active;
    emit captureActiveChanged();
}

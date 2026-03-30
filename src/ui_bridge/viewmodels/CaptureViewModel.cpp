#include "ui_bridge/viewmodels/CaptureViewModel.h"

#include <QDateTime>
#include <QDir>
#include <QUuid>
#include <QStandardPaths>
#include <QVariantMap>

CaptureViewModel::CaptureViewModel(CaptureSessionController* controller,
                                   QObject* parent)
    : QObject(parent),
      controller_(controller) {
    connect(controller_, &CaptureSessionController::stateChanged, this, [this]() {
        refreshSessionPresentation();
        emit overlayVisibleChanged();
    });
    connect(controller_, &CaptureSessionController::selectionRectChanged,
            this, &CaptureViewModel::selectionRectChanged);
    connect(controller_, &CaptureSessionController::magnifierUpdated, this,
            [this](const QImage& image, const QColor& color) {
                const QString nextColor = color.name(QColor::HexRgb);
                if (currentColorString_ != nextColor) {
                    currentColorString_ = nextColor;
                    emit currentColorStringChanged();
                }

                const QUrl nextMagnifierImageUrl = image.isNull()
                    ? QUrl()
                    : writeImageToTempFile("magnifier", image);
                if (magnifierImageUrl_ != nextMagnifierImageUrl) {
                    magnifierImageUrl_ = nextMagnifierImageUrl;
                    emit magnifierImageUrlChanged();
                }
            });

    refreshSessionPresentation();
}

bool CaptureViewModel::overlayVisible() const {
    return controller_->state() != CaptureSessionController::CaptureState::Idle;
}

QRect CaptureViewModel::desktopGeometry() const {
    return desktopGeometry_;
}

QVariantList CaptureViewModel::desktopScreens() const {
    return desktopScreens_;
}

QUrl CaptureViewModel::desktopSnapshotUrl() const {
    return desktopSnapshotUrl_;
}

QUrl CaptureViewModel::magnifierImageUrl() const {
    return magnifierImageUrl_;
}

QRect CaptureViewModel::selectionRect() const {
    return controller_->selectionRect().translated(-desktopGeometry_.topLeft());
}

bool CaptureViewModel::hasSelection() const {
    return !selectionRect().isEmpty();
}

QString CaptureViewModel::currentColorString() const {
    return currentColorString_;
}

void CaptureViewModel::beginCapture() {
    controller_->beginSession();
    refreshSessionPresentation();
}

bool CaptureViewModel::isWindowAutoSelectionEnabled() const {
    return controller_->isWindowAutoSelectionEnabled();
}

void CaptureViewModel::cancelCapture() {
    controller_->cancelSession();
}

void CaptureViewModel::setSelectionRect(int x, int y, int width, int height) {
    controller_->updateSelection(
        QRect(x + desktopGeometry_.x(), y + desktopGeometry_.y(), width, height));
}

void CaptureViewModel::updateCursorPoint(int x, int y, bool trackWindow) {
    controller_->updateCursorPoint(QPoint(x + desktopGeometry_.x(), y + desktopGeometry_.y()),
                                  trackWindow);
}

void CaptureViewModel::moveSelectionBy(int dx, int dy) {
    controller_->nudgeSelection(dx, dy);
}

void CaptureViewModel::moveSelectionTo(int x, int y) {
    controller_->moveSelectionTo(x + desktopGeometry_.x(), y + desktopGeometry_.y());
}

void CaptureViewModel::resizeSelectionBy(int left, int top, int right, int bottom) {
    controller_->resizeSelection(left, top, right, bottom);
}

void CaptureViewModel::copy() {
    controller_->copyResultToClipboard();
}

void CaptureViewModel::copyFullScreen() {
    controller_->copyFullScreen();
}

void CaptureViewModel::save() {
    const QString directory = QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
    QDir dir(directory);
    const QString path = dir.filePath(
        QString("kuclaw-capture-%1.png").arg(QDateTime::currentDateTime().toString("yyyyMMdd-HHmmss")));
    controller_->saveResultToFile(path);
    emit toastRequested(QString("Saved to %1").arg(path));
}

void CaptureViewModel::pin() {
    controller_->pinResult();
}

void CaptureViewModel::refreshSessionPresentation() {
    const QRect nextGeometry = controller_->desktopGeometry();
    if (desktopGeometry_ != nextGeometry) {
        desktopGeometry_ = nextGeometry;
        emit desktopGeometryChanged();
    }

    const QUrl nextSnapshotUrl = controller_->desktopImage().isNull()
        ? QUrl()
        : writeImageToTempFile("desktop", controller_->desktopImage());
    if (desktopSnapshotUrl_ != nextSnapshotUrl) {
        desktopSnapshotUrl_ = nextSnapshotUrl;
        emit desktopSnapshotUrlChanged();
    }

    QVariantList nextScreens;
    const auto screens = controller_->screens();
    nextScreens.reserve(screens.size());
    for (const auto& screen : screens) {
        QVariantMap screenMap;
        screenMap.insert("screenId", screen.screenId);
        screenMap.insert("x", screen.geometry.x());
        screenMap.insert("y", screen.geometry.y());
        screenMap.insert("width", screen.geometry.width());
        screenMap.insert("height", screen.geometry.height());
        screenMap.insert("devicePixelRatio", screen.devicePixelRatio);
        nextScreens.push_back(screenMap);
    }

    if (desktopScreens_ != nextScreens) {
        desktopScreens_ = nextScreens;
        emit desktopScreensChanged();
    }

    if (controller_->state() == CaptureSessionController::CaptureState::Idle) {
        if (!magnifierImageUrl_.isEmpty()) {
            magnifierImageUrl_.clear();
            emit magnifierImageUrlChanged();
        }
    }
}

QUrl CaptureViewModel::writeImageToTempFile(const QString& prefix, const QImage& image) const {
    const QString tempDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation) + "/kuclaw";
    QDir dir;
    dir.mkpath(tempDir);

    const QString filePath = tempDir + "/" + prefix + "-" + QUuid::createUuid().toString(QUuid::WithoutBraces) + ".png";
    image.save(filePath);
    return QUrl::fromLocalFile(filePath);
}

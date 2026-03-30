#include "core/capture/FreezeOverlayWidget.h"

#include <QKeyEvent>
#include <QFrame>
#include <QGuiApplication>
#include <QHBoxLayout>
#include <QLabel>
#include <QList>
#include <QVBoxLayout>
#include <QMouseEvent>
#include <QPaintEvent>
#include <QPainter>
#include <QPainterPath>
#include <QPushButton>
#include <QScreen>
#include <QtGlobal>

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

bool physicalRectForLogicalRect(const QRect& logicalRect,
                                const CaptureResult& capture,
                                QRect* outRect) {
    if (outRect == nullptr) {
        return false;
    }

    for (const auto& segment : capture.displaySegments) {
        const QRect rect = physicalRectForLogicalRect(logicalRect, segment);
        if (rect.isValid() && !rect.isEmpty()) {
            *outRect = rect;
            return true;
        }
    }

    *outRect = {};
    return false;
}

}  // namespace

FreezeOverlayWidget::FreezeOverlayWidget(QWidget* parent)
    : QWidget(parent) {
    setWindowFlags(Qt::FramelessWindowHint
                   | Qt::WindowStaysOnTopHint
                   | Qt::Tool);
    setMouseTracking(true);
    setCursor(Qt::CrossCursor);
    setFocusPolicy(Qt::StrongFocus);
    setAttribute(Qt::WA_DeleteOnClose);

    toolbar_ = new QFrame(this);
    toolbar_->setAttribute(Qt::WA_StyledBackground, true);
    toolbar_->setStyleSheet(
        "QFrame {"
        " background-color: rgba(24, 28, 32, 230);"
        " border: 1px solid rgba(255, 255, 255, 38);"
        " border-radius: 12px;"
        "}"
        "QPushButton {"
        " color: white;"
        " background: transparent;"
        " border: none;"
        " padding: 8px 14px;"
        " font-size: 13px;"
        "}"
        "QPushButton:hover {"
        " background-color: rgba(255, 255, 255, 24);"
        " border-radius: 8px;"
        "}");

    infoPanel_ = new QFrame(this);
    infoPanel_->setAttribute(Qt::WA_StyledBackground, true);
    infoPanel_->setStyleSheet(
        "QFrame {"
        " background-color: rgba(18, 22, 26, 232);"
        " border: 1px solid rgba(255, 255, 255, 42);"
        " border-radius: 10px;"
        "}"
        "QLabel {"
        " color: white;"
        " font-size: 12px;"
        "}");

    auto* infoLayout = new QVBoxLayout(infoPanel_);
    infoLayout->setContentsMargins(10, 8, 10, 8);
    infoLayout->setSpacing(2);

    auto* sizeLabel = new QLabel(QStringLiteral("0 x 0"), infoPanel_);
    sizeLabel->setObjectName(QStringLiteral("selectionSizeLabel"));
    auto* pointLabel = new QLabel(QStringLiteral("X: 0  Y: 0"), infoPanel_);
    pointLabel->setObjectName(QStringLiteral("selectionPointLabel"));
    auto* appLabel = new QLabel(QStringLiteral("应用: --"), infoPanel_);
    appLabel->setObjectName(QStringLiteral("selectionAppLabel"));
    auto* colorLabel = new QLabel(QStringLiteral("颜色: --"), infoPanel_);
    colorLabel->setObjectName(QStringLiteral("selectionColorLabel"));
    copyHintLabel_ = new QLabel(infoPanel_);
    copyHintLabel_->setObjectName(QStringLiteral("selectionCopyHintLabel"));
    copyHintLabel_->setTextFormat(Qt::RichText);
    infoLayout->addWidget(sizeLabel);
    infoLayout->addWidget(pointLabel);
    infoLayout->addWidget(appLabel);
    infoLayout->addWidget(colorLabel);
    infoLayout->addWidget(copyHintLabel_);
    infoPanel_->hide();

    copyHintHoldTimer_.setSingleShot(true);
    copyHintFadeAnimation_.setStartValue(1.0);
    copyHintFadeAnimation_.setEndValue(0.0);
    copyHintFadeAnimation_.setDuration(240);
    connect(&copyHintHoldTimer_, &QTimer::timeout, this, [this]() {
        copyHintFadeAnimation_.stop();
        copyHintFadeAnimation_.start();
    });
    connect(&copyHintFadeAnimation_, &QVariantAnimation::valueChanged, this,
            [this](const QVariant& value) {
                updateCopyHintMarkup(value.toReal());
            });
    updateCopyHintMarkup(0.0);

    auto* toolbarLayout = new QHBoxLayout(toolbar_);
    toolbarLayout->setContentsMargins(8, 8, 8, 8);
    toolbarLayout->setSpacing(4);

    copyButton_ = new QPushButton(QStringLiteral("复制"), toolbar_);
    saveButton_ = new QPushButton(QStringLiteral("保存"), toolbar_);
    cancelButton_ = new QPushButton(QStringLiteral("取消"), toolbar_);
    toolbarLayout->addWidget(copyButton_);
    toolbarLayout->addWidget(saveButton_);
    toolbarLayout->addWidget(cancelButton_);
    toolbar_->hide();

    connect(copyButton_, &QPushButton::clicked, this, [this]() {
        if (!selectionCommitted_) {
            return;
        }

        emit selectionConfirmed(committedSelection_);
        close();
    });
    connect(saveButton_, &QPushButton::clicked, this, [this]() {
        if (!selectionCommitted_) {
            return;
        }

        emit selectionSaveRequested(committedSelection_);
    });
    connect(cancelButton_, &QPushButton::clicked, this, [this]() {
        emit selectionCanceled();
        close();
    });
}

void FreezeOverlayWidget::setCaptureData(const CaptureResult& capture,
                                         QVector<WindowCandidate> candidates) {
    capture_ = capture;
    candidates_ = std::move(candidates);
    leftButtonPressed_ = false;
    manualSelectionActive_ = false;
    pressedCandidateIndex_ = -1;
    pressedScreenFallback_ = false;
    activeSelectionHandle_ = SelectionHandle::None;
    hasPointerOverlayPoint_ = false;
    pointerOverlayPoint_ = {};
    hasPointerColor_ = false;
    pointerColor_ = {};
    lastMagnifierRect_ = {};
    pressOverlayPoint_ = {};
    pressCommittedRect_ = {};
    manualSelectionRect_ = {};
    committedSelection_ = {};
    selectionCommitted_ = false;
    hoverIndex_ = -1;
    hoverUsesScreenFallback_ = false;
    hoverRect_ = {};
    copyHintHoldTimer_.stop();
    copyHintFadeAnimation_.stop();
    updateCopyHintMarkup(0.0);
    setCursor(Qt::CrossCursor);
    infoPanel_->hide();
    toolbar_->hide();
}

void FreezeOverlayWidget::setScreenGeometry(const QRect& screenGeometry) {
    screenGeometry_ = screenGeometry.isValid() ? screenGeometry
                                               : capture_.virtualDesktopRect;
    screenAvailableGeometry_ = screenGeometry_;
    for (QScreen* screen : QGuiApplication::screens()) {
        if (screen == nullptr) {
            continue;
        }

        if (screen->geometry() == screenGeometry_
            || screen->geometry().intersects(screenGeometry_)) {
            screenAvailableGeometry_ =
                screen->availableGeometry().intersected(screenGeometry_);
            break;
        }
    }

    if (!screenAvailableGeometry_.isValid() || screenAvailableGeometry_.isEmpty()) {
        screenAvailableGeometry_ = screenGeometry_;
    }
    setGeometry(screenGeometry_);
}

void FreezeOverlayWidget::setMagnifierEnabled(const bool enabled) {
    if (magnifierEnabled_ == enabled) {
        return;
    }

    magnifierEnabled_ = enabled;
    updateMagnifier();
}

void FreezeOverlayWidget::setDefaultColorFormat(const QString& format) {
    colorFormatHex_ = format.trimmed().compare(QStringLiteral("HEX"), Qt::CaseInsensitive) == 0;
}

QPoint FreezeOverlayWidget::globalToOverlayPoint(const QPointF& globalPoint) const {
    return globalPoint.toPoint() - capture_.virtualDesktopRect.topLeft();
}

QPoint FreezeOverlayWidget::localToOverlayPoint(const QPoint& localPoint) const {
    const QPoint screenTopLeft = screenGeometry_.isValid()
        ? screenGeometry_.topLeft()
        : capture_.virtualDesktopRect.topLeft();
    return localPoint + (screenTopLeft - capture_.virtualDesktopRect.topLeft());
}

QRect FreezeOverlayWidget::overlayToLocalRect(const QRect& overlayRect) const {
    const QPoint screenTopLeft = screenGeometry_.isValid()
        ? screenGeometry_.topLeft()
        : capture_.virtualDesktopRect.topLeft();
    return overlayRect.translated(-(screenTopLeft - capture_.virtualDesktopRect.topLeft()));
}

QRect FreezeOverlayWidget::screenSelectionOverlayRect() const {
    const QRect screenRect = screenGeometry_.isValid()
        ? screenGeometry_
        : capture_.virtualDesktopRect;
    return screenRect.translated(-capture_.virtualDesktopRect.topLeft());
}

QRect FreezeOverlayWidget::visibleHoverRectForIndex(const int index) const {
    if (index < 0 || index >= candidates_.size()) {
        return {};
    }

    return overlayToLocalRect(candidates_.at(index).overlayRect).intersected(rect());
}

QRect FreezeOverlayWidget::visibleScreenSelectionRect() const {
    return overlayToLocalRect(screenSelectionOverlayRect()).intersected(rect());
}

QRect FreezeOverlayWidget::visibleCommittedRect() const {
    if (!selectionCommitted_) {
        return {};
    }

    return overlayToLocalRect(committedSelection_.overlayRect).intersected(rect());
}

QRect FreezeOverlayWidget::visibleInfoRect() const {
    if (selectionCommitted_) {
        return visibleCommittedRect();
    }

    if (manualSelectionActive_) {
        return overlayToLocalRect(manualSelectionRect_).intersected(rect());
    }

    return hoverRect_;
}

QPoint FreezeOverlayWidget::infoAnchorLocalPoint() const {
    if (selectionCommitted_ && activeSelectionHandle_ != SelectionHandle::None) {
        return overlayToLocalRect(committedSelection_.overlayRect).topLeft();
    }

    if (leftButtonPressed_ || manualSelectionActive_) {
        return overlayToLocalRect(QRect(pressOverlayPoint_, QSize(1, 1))).topLeft();
    }

    const QPoint localMouse = mapFromGlobal(QCursor::pos());
    if (rect().contains(localMouse)) {
        return localMouse;
    }

    const QRect activeRect = visibleInfoRect();
    return activeRect.isValid() ? activeRect.topLeft() : QPoint(width() / 2, height() / 2);
}

QRect FreezeOverlayWidget::visibleMagnifierRect() const {
    if (!magnifierEnabled_
        || !hasPointerOverlayPoint_
        || (selectionCommitted_ && !leftButtonPressed_)) {
        return {};
    }

    constexpr int kMagnifierSize = 150;
    const int margin = 14;
    const QPoint anchorPoint = magnifierAnchorLocalPoint();

    int x = anchorPoint.x() + margin;
    int y = anchorPoint.y() - kMagnifierSize - margin;

    if (x + kMagnifierSize > width() - margin) {
        x = anchorPoint.x() - kMagnifierSize - margin;
    }
    if (y < margin) {
        y = anchorPoint.y() + margin;
    }

    x = qBound(margin, x, qMax(margin, width() - kMagnifierSize - margin));
    y = qBound(margin, y, qMax(margin, height() - kMagnifierSize - margin));

    return QRect(x, y, kMagnifierSize, kMagnifierSize);
}

QRect FreezeOverlayWidget::visibleSafeAreaRect() const {
    const QRect safeRect = screenAvailableGeometry_.isValid()
        ? screenAvailableGeometry_
        : screenGeometry_;
    return overlayToLocalRect(safeRect.translated(-capture_.virtualDesktopRect.topLeft())).intersected(rect());
}

QPoint FreezeOverlayWidget::magnifierAnchorLocalPoint() const {
    if (!hasPointerOverlayPoint_) {
        return QPoint(width() / 2, height() / 2);
    }

    return overlayToLocalRect(QRect(pointerOverlayPoint_, QSize(1, 1))).topLeft();
}

bool FreezeOverlayWidget::sampleColorAtOverlayPoint(const QPoint& overlayPoint,
                                                    QColor* outColor) const {
    if (outColor == nullptr || capture_.frozenDesktop.isNull()) {
        return false;
    }

    const QRect logicalSampleRect(
        overlayPoint.x() + capture_.virtualDesktopRect.x(),
        overlayPoint.y() + capture_.virtualDesktopRect.y(),
        1,
        1);
    QRect sourceRect;
    if (!physicalRectForLogicalRect(logicalSampleRect, capture_, &sourceRect)) {
        return false;
    }

    const QRect imageBounds = sourceRect.intersected(capture_.frozenDesktop.rect());
    if (!imageBounds.isValid() || imageBounds.isEmpty()) {
        return false;
    }

    qint64 red = 0;
    qint64 green = 0;
    qint64 blue = 0;
    qint64 alpha = 0;
    qint64 count = 0;
    for (int y = imageBounds.top(); y <= imageBounds.bottom(); ++y) {
        for (int x = imageBounds.left(); x <= imageBounds.right(); ++x) {
            const QColor color = capture_.frozenDesktop.pixelColor(x, y);
            red += color.red();
            green += color.green();
            blue += color.blue();
            alpha += color.alpha();
            ++count;
        }
    }

    if (count <= 0) {
        return false;
    }

    *outColor = QColor(static_cast<int>(red / count),
                       static_cast<int>(green / count),
                       static_cast<int>(blue / count),
                       static_cast<int>(alpha / count));
    return outColor->isValid();
}

QString FreezeOverlayWidget::formattedPointerColor() const {
    if (!hasPointerColor_) {
        return QStringLiteral("--");
    }

    if (colorFormatHex_) {
        return pointerColor_.name(QColor::HexRgb).toUpper();
    }

    return QStringLiteral("RGB(%1, %2, %3)")
        .arg(pointerColor_.red())
        .arg(pointerColor_.green())
        .arg(pointerColor_.blue());
}

QString FreezeOverlayWidget::currentInfoAppName() const {
    if (selectionCommitted_) {
        return committedSelection_.ownerAppName.trimmed();
    }

    if (manualSelectionActive_ || leftButtonPressed_) {
        return QStringLiteral("自由框选");
    }

    if (hoverUsesScreenFallback_) {
        return QStringLiteral("当前屏幕");
    }

    if (hoverIndex_ >= 0 && hoverIndex_ < candidates_.size()) {
        return candidates_.at(hoverIndex_).ownerAppName.trimmed();
    }

    return {};
}

void FreezeOverlayWidget::updateCopyHintMarkup(const qreal emphasis) {
    if (copyHintLabel_ == nullptr) {
        return;
    }

    const qreal clamped = qBound(0.0, emphasis, 1.0);
    const QColor baseTextColor(255, 255, 255, 166);
    const QColor flashTextColor(91, 255, 127, 255);
    const auto blendChannel = [clamped](const int base, const int flash) {
        return qRound(base + (flash - base) * clamped);
    };

    const QColor keyColor(blendChannel(baseTextColor.red(), flashTextColor.red()),
                          blendChannel(baseTextColor.green(), flashTextColor.green()),
                          blendChannel(baseTextColor.blue(), flashTextColor.blue()),
                          blendChannel(baseTextColor.alpha(), flashTextColor.alpha()));
    const int fontWeight = qRound(500 + 200 * clamped);

    copyHintLabel_->setText(QStringLiteral(
        "<span style=\"color:%1;\">Shift 切换 / </span>"
        "<span style=\"color:%2; font-weight:%3;\">C</span>"
        "<span style=\"color:%1;\"> 复制</span>")
            .arg(baseTextColor.name(QColor::HexArgb))
            .arg(keyColor.name(QColor::HexArgb))
            .arg(fontWeight));
}

void FreezeOverlayWidget::triggerCopyHintFlash() {
    copyHintHoldTimer_.stop();
    copyHintFadeAnimation_.stop();
    updateCopyHintMarkup(1.0);
    copyHintHoldTimer_.start(200);
}

QVector<QRect> FreezeOverlayWidget::visibleHandleRects() const {
    QVector<QRect> handleRects;
    const QRect committedRect = visibleCommittedRect();
    if (!committedRect.isValid() || committedRect.isEmpty()) {
        return handleRects;
    }

    constexpr int kHandleSize = 8;
    const int half = kHandleSize / 2;
    const QList<QPoint> handleCenters = {
        committedRect.topLeft(),
        QPoint(committedRect.center().x(), committedRect.top()),
        committedRect.topRight(),
        QPoint(committedRect.left(), committedRect.center().y()),
        QPoint(committedRect.right(), committedRect.center().y()),
        committedRect.bottomLeft(),
        QPoint(committedRect.center().x(), committedRect.bottom()),
        committedRect.bottomRight(),
    };

    handleRects.reserve(handleCenters.size());
    for (const QPoint& center : handleCenters) {
        handleRects.push_back(QRect(center.x() - half,
                                    center.y() - half,
                                    kHandleSize,
                                    kHandleSize));
    }

    return handleRects;
}

QRect FreezeOverlayWidget::normalizedSelectionRect(const QPoint& start, const QPoint& end) const {
    const int left = qMin(start.x(), end.x());
    const int top = qMin(start.y(), end.y());
    const int right = qMax(start.x(), end.x());
    const int bottom = qMax(start.y(), end.y());

    return QRect(left,
                 top,
                 qMax(1, right - left),
                 qMax(1, bottom - top));
}

QRect FreezeOverlayWidget::normalizedBoundsRect(const int left,
                                                const int top,
                                                const int right,
                                                const int bottom) const {
    return QRect(left,
                 top,
                 qMax(1, right - left),
                 qMax(1, bottom - top));
}

int FreezeOverlayWidget::hitTestCandidateIndex(const QPoint& overlayPos) const {
    for (int index = 0; index < candidates_.size(); ++index) {
        const auto& candidate = candidates_.at(index);
        if (candidate.valid && candidate.overlayRect.contains(overlayPos)) {
            return index;
        }
    }

    return -1;
}

void FreezeOverlayWidget::clearCommittedSelection() {
    if (!selectionCommitted_) {
        return;
    }

    selectionCommitted_ = false;
    committedSelection_ = {};
    activeSelectionHandle_ = SelectionHandle::None;
    setCursor(Qt::CrossCursor);
    infoPanel_->hide();
    hasPointerOverlayPoint_ = false;
    pointerOverlayPoint_ = {};
    lastMagnifierRect_ = {};
    toolbar_->hide();
    update();
}

void FreezeOverlayWidget::commitSelection(const SelectionResult& result) {
    committedSelection_ = result;
    selectionCommitted_ = true;
    leftButtonPressed_ = false;
    manualSelectionActive_ = false;
    pressedCandidateIndex_ = -1;
    pressedScreenFallback_ = false;
    activeSelectionHandle_ = SelectionHandle::None;
    setManualSelectionRect({});
    setHoverState(-1, false);
    updateToolbarGeometry();
    updateInfoGeometry();
    updateMagnifier();
    toolbar_->show();
    toolbar_->raise();
    update();
}

void FreezeOverlayWidget::updateCommittedSelectionRect(const QRect& newRect) {
    const QRect previousRect = visibleCommittedRect();
    committedSelection_.overlayRect = newRect;
    committedSelection_.globalLogicalRect =
        newRect.translated(capture_.virtualDesktopRect.topLeft());
    committedSelection_.nativeRect = committedSelection_.globalLogicalRect;
    committedSelection_.nativeId = 0;
    committedSelection_.ownerAppName = QStringLiteral("自由框选");
    committedSelection_.windowTitle.clear();

    const QRect currentRect = visibleCommittedRect();
    QRect dirtyRect = previousRect.united(currentRect);
    if (!dirtyRect.isValid() || dirtyRect.isEmpty()) {
        update();
    } else {
        dirtyRect.adjust(-12, -12, 12, 12);
        update(dirtyRect);
    }

    updateToolbarGeometry();
    updateInfoGeometry();
}

void FreezeOverlayWidget::setManualSelectionRect(const QRect& newRect) {
    const QRect previousRect = overlayToLocalRect(manualSelectionRect_).intersected(rect());
    manualSelectionRect_ = newRect;
    const QRect currentRect = overlayToLocalRect(manualSelectionRect_).intersected(rect());

    QRect dirtyRect = previousRect.united(currentRect);
    if (!dirtyRect.isValid() || dirtyRect.isEmpty()) {
        update();
        return;
    }

    dirtyRect.adjust(-4, -4, 4, 4);
    update(dirtyRect);
    updateInfoGeometry();
    updateMagnifier();
}

void FreezeOverlayWidget::updateToolbarGeometry() {
    if (!selectionCommitted_) {
        toolbar_->hide();
        return;
    }

    const QRect targetRect = visibleCommittedRect();
    if (!targetRect.isValid() || targetRect.isEmpty()) {
        toolbar_->hide();
        return;
    }

    toolbar_->adjustSize();

    const int margin = 12;
    const QRect safeRect = visibleSafeAreaRect();
    const int safeLeft = safeRect.isValid() ? safeRect.left() + margin : margin;
    const int safeTop = safeRect.isValid() ? safeRect.top() + margin : margin;
    const int safeRight = safeRect.isValid()
        ? safeRect.right() - toolbar_->width() - margin + 1
        : width() - toolbar_->width() - margin;
    const int safeBottom = safeRect.isValid()
        ? safeRect.bottom() - toolbar_->height() - margin + 1
        : height() - toolbar_->height() - margin;

    int x = targetRect.center().x() - toolbar_->width() / 2;
    x = qBound(safeLeft, x, qMax(safeLeft, safeRight));

    const int belowY = targetRect.bottom() + margin;
    const int aboveY = targetRect.top() - toolbar_->height() - margin;

    int y = belowY;
    if (belowY + toolbar_->height() > safeBottom + toolbar_->height()) {
        if (aboveY >= safeTop) {
            y = aboveY;
        } else {
            y = safeBottom;
        }
    }
    y = qBound(safeTop, y, qMax(safeTop, safeBottom));

    toolbar_->move(x, y);
}

void FreezeOverlayWidget::updatePointerColor() {
    if (!hasPointerOverlayPoint_) {
        hasPointerColor_ = false;
        pointerColor_ = {};
        return;
    }

    QColor sampledColor;
    if (!sampleColorAtOverlayPoint(pointerOverlayPoint_, &sampledColor)) {
        hasPointerColor_ = false;
        pointerColor_ = {};
        return;
    }

    hasPointerColor_ = true;
    pointerColor_ = sampledColor;
}

void FreezeOverlayWidget::updateInfoGeometry() {
    if (infoPanel_ == nullptr) {
        return;
    }

    if (!selectionCommitted_
        && !manualSelectionActive_
        && hoverRect_.isEmpty()
        && !leftButtonPressed_) {
        infoPanel_->hide();
        return;
    }

    const QRect infoRect = visibleInfoRect();
    if (!infoRect.isValid() || infoRect.isEmpty()) {
        infoPanel_->hide();
        return;
    }

    const int widthValue = qMax(1, infoRect.width());
    const int heightValue = qMax(1, infoRect.height());
    QPoint pointValue = infoRect.topLeft() + screenGeometry_.topLeft();
    if (!selectionCommitted_
        && !manualSelectionActive_
        && hasPointerOverlayPoint_) {
        pointValue = pointerOverlayPoint_ + capture_.virtualDesktopRect.topLeft();
    }

    if (auto* sizeLabel = infoPanel_->findChild<QLabel*>(QStringLiteral("selectionSizeLabel"))) {
        sizeLabel->setText(QStringLiteral("%1 x %2").arg(widthValue).arg(heightValue));
    }
    if (auto* pointLabel = infoPanel_->findChild<QLabel*>(QStringLiteral("selectionPointLabel"))) {
        pointLabel->setText(QStringLiteral("X: %1  Y: %2")
                                .arg(pointValue.x())
                                .arg(pointValue.y()));
    }
    if (auto* appLabel = infoPanel_->findChild<QLabel*>(QStringLiteral("selectionAppLabel"))) {
        const QString appName = currentInfoAppName();
        appLabel->setText(QStringLiteral("应用: %1")
                              .arg(appName.isEmpty() ? QStringLiteral("--") : appName));
    }
    if (auto* colorLabel = infoPanel_->findChild<QLabel*>(QStringLiteral("selectionColorLabel"))) {
        colorLabel->setText(QStringLiteral("颜色: %1").arg(formattedPointerColor()));
    }

    infoPanel_->adjustSize();

    const QPoint anchorPoint = infoAnchorLocalPoint();
    const int margin = 12;
    const auto clampPanelRect = [this, margin](const QPoint& topLeft) {
        const int maxX = qMax(margin, width() - infoPanel_->width() - margin);
        const int maxY = qMax(margin, height() - infoPanel_->height() - margin);
        return QRect(QPoint(qBound(margin, topLeft.x(), maxX),
                            qBound(margin, topLeft.y(), maxY)),
                     infoPanel_->size());
    };

    QVector<QPoint> candidatePoints;
    candidatePoints.reserve(4);
    candidatePoints.push_back(QPoint(anchorPoint.x() + margin,
                                     anchorPoint.y() - infoPanel_->height() - margin));
    candidatePoints.push_back(QPoint(anchorPoint.x() + margin,
                                     anchorPoint.y() + margin));
    candidatePoints.push_back(QPoint(anchorPoint.x() - infoPanel_->width() - margin,
                                     anchorPoint.y() - infoPanel_->height() - margin));
    candidatePoints.push_back(QPoint(anchorPoint.x() - infoPanel_->width() - margin,
                                     anchorPoint.y() + margin));

    const QRect magnifierRect = visibleMagnifierRect();
    QRect panelRect = clampPanelRect(candidatePoints.first());
    if (magnifierRect.isValid() && !magnifierRect.isEmpty()) {
        for (const QPoint& point : candidatePoints) {
            const QRect nextRect = clampPanelRect(point);
            if (!nextRect.intersects(magnifierRect.adjusted(-6, -6, 6, 6))) {
                panelRect = nextRect;
                break;
            }
        }
    }

    infoPanel_->move(panelRect.topLeft());
    infoPanel_->show();
    infoPanel_->raise();
}

void FreezeOverlayWidget::updateMagnifier() {
    const QRect currentRect = visibleMagnifierRect();
    const QRect dirtyRect = lastMagnifierRect_.united(currentRect);
    lastMagnifierRect_ = currentRect;

    if (!dirtyRect.isValid() || dirtyRect.isEmpty()) {
        update();
        return;
    }

    update(dirtyRect.adjusted(-8, -8, 8, 8));
}

void FreezeOverlayWidget::setHoverState(const int newIndex,
                                        const bool useScreenFallback) {
    if (newIndex == hoverIndex_
        && useScreenFallback == hoverUsesScreenFallback_) {
        return;
    }

    const QRect previousRect = hoverRect_;
    hoverIndex_ = newIndex;
    hoverUsesScreenFallback_ = useScreenFallback;
    hoverRect_ = hoverUsesScreenFallback_
        ? visibleScreenSelectionRect()
        : visibleHoverRectForIndex(hoverIndex_);

    QRect dirtyRect = previousRect.united(hoverRect_);
    if (!dirtyRect.isValid() || dirtyRect.isEmpty()) {
        update();
        return;
    }

    dirtyRect.adjust(-4, -4, 4, 4);
    update(dirtyRect);
    updateInfoGeometry();
    updateMagnifier();
}

SelectionResult FreezeOverlayWidget::buildSelectionResult(const WindowCandidate& candidate) const {
    SelectionResult result;
    result.overlayRect = candidate.overlayRect;
    result.globalLogicalRect = candidate.overlayRect.translated(capture_.virtualDesktopRect.topLeft());
    result.nativeRect = candidate.nativeRect;
    result.nativeId = candidate.nativeId;
    result.ownerAppName = candidate.ownerAppName;
    result.windowTitle = candidate.windowTitle;
    return result;
}

SelectionResult FreezeOverlayWidget::buildManualSelectionResult() const {
    SelectionResult result;
    result.overlayRect = manualSelectionRect_;
    result.globalLogicalRect = manualSelectionRect_.translated(capture_.virtualDesktopRect.topLeft());
    result.nativeRect = result.globalLogicalRect;
    result.nativeId = 0;
    result.ownerAppName = QStringLiteral("自由框选");
    return result;
}

SelectionResult FreezeOverlayWidget::buildScreenSelectionResult() const {
    SelectionResult result;
    result.overlayRect = screenSelectionOverlayRect();
    result.globalLogicalRect =
        result.overlayRect.translated(capture_.virtualDesktopRect.topLeft());
    result.nativeRect = result.globalLogicalRect;
    result.nativeId = 0;
    result.ownerAppName = QStringLiteral("当前屏幕");
    return result;
}

FreezeOverlayWidget::SelectionHandle FreezeOverlayWidget::hitTestCommittedSelection(
    const QPoint& overlayPos) const {
    if (!selectionCommitted_) {
        return SelectionHandle::None;
    }

    const QRect rect = committedSelection_.overlayRect;
    if (!rect.isValid() || rect.isEmpty()) {
        return SelectionHandle::None;
    }

    constexpr int kEdgeTolerance = 6;
    const bool nearLeft = qAbs(overlayPos.x() - rect.left()) <= kEdgeTolerance;
    const bool nearRight = qAbs(overlayPos.x() - rect.right()) <= kEdgeTolerance;
    const bool nearTop = qAbs(overlayPos.y() - rect.top()) <= kEdgeTolerance;
    const bool nearBottom = qAbs(overlayPos.y() - rect.bottom()) <= kEdgeTolerance;
    const bool withinHorizontal =
        overlayPos.x() >= rect.left() - kEdgeTolerance
        && overlayPos.x() <= rect.right() + kEdgeTolerance;
    const bool withinVertical =
        overlayPos.y() >= rect.top() - kEdgeTolerance
        && overlayPos.y() <= rect.bottom() + kEdgeTolerance;

    if (nearLeft && nearTop) {
        return SelectionHandle::TopLeft;
    }
    if (nearRight && nearTop) {
        return SelectionHandle::TopRight;
    }
    if (nearLeft && nearBottom) {
        return SelectionHandle::BottomLeft;
    }
    if (nearRight && nearBottom) {
        return SelectionHandle::BottomRight;
    }
    if (nearLeft && withinVertical) {
        return SelectionHandle::Left;
    }
    if (nearRight && withinVertical) {
        return SelectionHandle::Right;
    }
    if (nearTop && withinHorizontal) {
        return SelectionHandle::Top;
    }
    if (nearBottom && withinHorizontal) {
        return SelectionHandle::Bottom;
    }
    if (rect.contains(overlayPos)) {
        return SelectionHandle::Move;
    }

    return SelectionHandle::None;
}

void FreezeOverlayWidget::updateCursorForPoint(const QPoint& overlayPos) {
    Qt::CursorShape cursorShape = Qt::CrossCursor;

    switch (hitTestCommittedSelection(overlayPos)) {
    case SelectionHandle::Move:
        cursorShape = Qt::SizeAllCursor;
        break;
    case SelectionHandle::Left:
    case SelectionHandle::Right:
        cursorShape = Qt::SizeHorCursor;
        break;
    case SelectionHandle::Top:
    case SelectionHandle::Bottom:
        cursorShape = Qt::SizeVerCursor;
        break;
    case SelectionHandle::TopLeft:
    case SelectionHandle::BottomRight:
        cursorShape = Qt::SizeFDiagCursor;
        break;
    case SelectionHandle::TopRight:
    case SelectionHandle::BottomLeft:
        cursorShape = Qt::SizeBDiagCursor;
        break;
    case SelectionHandle::None:
    default:
        break;
    }

    setCursor(cursorShape);
}

void FreezeOverlayWidget::updateCommittedInteraction(const QPoint& overlayPos) {
    if (!selectionCommitted_ || activeSelectionHandle_ == SelectionHandle::None) {
        return;
    }

    constexpr int kMinSelectionSize = 24;
    const int desktopRight = capture_.virtualDesktopRect.width();
    const int desktopBottom = capture_.virtualDesktopRect.height();

    int left = pressCommittedRect_.x();
    int top = pressCommittedRect_.y();
    int right = pressCommittedRect_.x() + pressCommittedRect_.width();
    int bottom = pressCommittedRect_.y() + pressCommittedRect_.height();

    if (activeSelectionHandle_ == SelectionHandle::Move) {
        const int dx = overlayPos.x() - pressOverlayPoint_.x();
        const int dy = overlayPos.y() - pressOverlayPoint_.y();
        const int width = pressCommittedRect_.width();
        const int height = pressCommittedRect_.height();
        left = qBound(0, pressCommittedRect_.x() + dx, qMax(0, desktopRight - width));
        top = qBound(0, pressCommittedRect_.y() + dy, qMax(0, desktopBottom - height));
        updateCommittedSelectionRect(QRect(left, top, width, height));
        return;
    }

    if (activeSelectionHandle_ == SelectionHandle::Left
        || activeSelectionHandle_ == SelectionHandle::TopLeft
        || activeSelectionHandle_ == SelectionHandle::BottomLeft) {
        left = qBound(0, overlayPos.x(), right - kMinSelectionSize);
    }
    if (activeSelectionHandle_ == SelectionHandle::Right
        || activeSelectionHandle_ == SelectionHandle::TopRight
        || activeSelectionHandle_ == SelectionHandle::BottomRight) {
        right = qBound(left + kMinSelectionSize, overlayPos.x(), desktopRight);
    }
    if (activeSelectionHandle_ == SelectionHandle::Top
        || activeSelectionHandle_ == SelectionHandle::TopLeft
        || activeSelectionHandle_ == SelectionHandle::TopRight) {
        top = qBound(0, overlayPos.y(), bottom - kMinSelectionSize);
    }
    if (activeSelectionHandle_ == SelectionHandle::Bottom
        || activeSelectionHandle_ == SelectionHandle::BottomLeft
        || activeSelectionHandle_ == SelectionHandle::BottomRight) {
        bottom = qBound(top + kMinSelectionSize, overlayPos.y(), desktopBottom);
    }

    updateCommittedSelectionRect(normalizedBoundsRect(left, top, right, bottom));
}

void FreezeOverlayWidget::paintEvent(QPaintEvent* event) {
    Q_UNUSED(event);

    QPainter painter(this);
    painter.setRenderHint(QPainter::Antialiasing, false);

    const QRect screenRect = screenGeometry_.isValid() ? screenGeometry_
                                                       : capture_.virtualDesktopRect;
    for (const auto& segment : capture_.displaySegments) {
        const QRect logicalRect = segment.logicalRect.intersected(screenRect);
        if (!logicalRect.isValid() || logicalRect.isEmpty()) {
            continue;
        }

        const QRect sourceRect = physicalRectForLogicalRect(logicalRect, segment);
        if (!sourceRect.isValid() || sourceRect.isEmpty()) {
            continue;
        }

        const QRect targetRect = logicalRect.translated(-screenRect.topLeft());
        painter.drawImage(targetRect, capture_.frozenDesktop, sourceRect);
    }

    QPainterPath fullPath;
    fullPath.addRect(rect());

    QPainterPath shadedPath = fullPath;
    const QRect visibleManualRect =
        overlayToLocalRect(manualSelectionRect_).intersected(rect());
    const QRect activeRect = selectionCommitted_
        ? visibleCommittedRect()
        : (manualSelectionActive_ ? visibleManualRect : hoverRect_);
    if (!activeRect.isEmpty()) {
        QPainterPath holePath;
        holePath.addRect(activeRect);
        shadedPath = fullPath.subtracted(holePath);
    }

    painter.fillPath(shadedPath, QColor(0, 0, 0, 100));

    if (!activeRect.isEmpty()) {
        painter.setPen(QPen(QColor(0, 255, 0), 2.0));
        painter.setBrush(Qt::NoBrush);
        painter.drawRect(activeRect.adjusted(1, 1, -1, -1));

        if (selectionCommitted_) {
            painter.setBrush(QColor(0, 255, 0));
            for (const QRect& handleRect : visibleHandleRects()) {
                painter.drawRect(handleRect);
            }
        }
    }

    const QRect magnifierRect = visibleMagnifierRect();
    if (magnifierRect.isValid() && !magnifierRect.isEmpty()) {
        painter.save();
        painter.setRenderHint(QPainter::Antialiasing, true);

        QPainterPath outerPath;
        outerPath.addRoundedRect(magnifierRect, 14, 14);
        painter.fillPath(outerPath, QColor(14, 18, 22, 236));

        const QRect previewRect = magnifierRect.adjusted(8, 8, -8, -8);
        const int sampleRadius = 8;
        const QRect sampleLogicalRect(
            pointerOverlayPoint_.x() + capture_.virtualDesktopRect.x() - sampleRadius,
            pointerOverlayPoint_.y() + capture_.virtualDesktopRect.y() - sampleRadius,
            sampleRadius * 2,
            sampleRadius * 2);
        QRect sourceRect;
        physicalRectForLogicalRect(sampleLogicalRect, capture_, &sourceRect);

        QPainterPath previewPath;
        previewPath.addRoundedRect(previewRect, 10, 10);
        painter.setClipPath(previewPath);
        painter.setRenderHint(QPainter::SmoothPixmapTransform, false);
        if (sourceRect.isValid() && !sourceRect.isEmpty()) {
            painter.drawImage(previewRect, capture_.frozenDesktop, sourceRect);
        }
        painter.setClipping(false);

        if (sourceRect.width() > 0 && sourceRect.height() > 0) {
            const qreal cellWidth = previewRect.width() / qreal(sourceRect.width());
            const qreal cellHeight = previewRect.height() / qreal(sourceRect.height());

            if (cellWidth >= 6.0 && cellHeight >= 6.0) {
                painter.setPen(QPen(QColor(255, 255, 255, 34), 1.0));
                for (int x = 1; x < sourceRect.width(); ++x) {
                    const qreal lineX = previewRect.left() + x * cellWidth;
                    painter.drawLine(QPointF(lineX, previewRect.top()),
                                     QPointF(lineX, previewRect.bottom()));
                }
                for (int y = 1; y < sourceRect.height(); ++y) {
                    const qreal lineY = previewRect.top() + y * cellHeight;
                    painter.drawLine(QPointF(previewRect.left(), lineY),
                                     QPointF(previewRect.right(), lineY));
                }
            }

            const qreal centerX = previewRect.left() + previewRect.width() / 2.0;
            const qreal centerY = previewRect.top() + previewRect.height() / 2.0;
            painter.setPen(QPen(QColor(91, 255, 127), 2.0));
            painter.drawLine(QPointF(centerX - 10.0, centerY),
                             QPointF(centerX + 10.0, centerY));
            painter.drawLine(QPointF(centerX, centerY - 10.0),
                             QPointF(centerX, centerY + 10.0));
        }

        painter.setPen(QPen(QColor(255, 255, 255, 60), 1.0));
        painter.setBrush(Qt::NoBrush);
        painter.drawRoundedRect(magnifierRect.adjusted(0, 0, -1, -1), 14, 14);
        painter.restore();
    }
}

void FreezeOverlayWidget::mouseMoveEvent(QMouseEvent* event) {
    const QPoint overlayPoint = globalToOverlayPoint(event->globalPosition());
    hasPointerOverlayPoint_ = true;
    pointerOverlayPoint_ = overlayPoint;
    updatePointerColor();
    updateMagnifier();

    if (selectionCommitted_ && !leftButtonPressed_) {
        updateCursorForPoint(overlayPoint);
        updateInfoGeometry();
        return;
    }

    if (leftButtonPressed_) {
        if (selectionCommitted_ && activeSelectionHandle_ != SelectionHandle::None) {
            updateCommittedInteraction(overlayPoint);
            return;
        }

        const bool moved =
            (overlayPoint - pressOverlayPoint_).manhattanLength() >= 3;
        if (moved) {
            if (!manualSelectionActive_) {
                manualSelectionActive_ = true;
                setHoverState(-1, false);
            }
            setManualSelectionRect(normalizedSelectionRect(pressOverlayPoint_, overlayPoint));
        }
        return;
    }

    const int hoverCandidateIndex = hitTestCandidateIndex(overlayPoint);
    setHoverState(hoverCandidateIndex, hoverCandidateIndex < 0);
    updateInfoGeometry();
}

void FreezeOverlayWidget::mousePressEvent(QMouseEvent* event) {
    hasPointerOverlayPoint_ = true;
    pointerOverlayPoint_ = globalToOverlayPoint(event->globalPosition());
    updatePointerColor();
    updateMagnifier();

    if (event->button() == Qt::RightButton) {
        if (mouseGrabber() == this) {
            releaseMouse();
        }
        infoPanel_->hide();
        hasPointerOverlayPoint_ = false;
        pointerOverlayPoint_ = {};
        hasPointerColor_ = false;
        pointerColor_ = {};
        updateMagnifier();
        emit selectionCanceled();
        close();
        return;
    }

    if (event->button() == Qt::LeftButton) {
        pressOverlayPoint_ = globalToOverlayPoint(event->globalPosition());
        if (selectionCommitted_) {
            activeSelectionHandle_ = hitTestCommittedSelection(pressOverlayPoint_);
            if (activeSelectionHandle_ != SelectionHandle::None) {
                leftButtonPressed_ = true;
                manualSelectionActive_ = false;
                pressedCandidateIndex_ = -1;
                pressedScreenFallback_ = false;
                pressCommittedRect_ = committedSelection_.overlayRect;
                toolbar_->hide();
                updateInfoGeometry();
                grabMouse();
                return;
            }

            clearCommittedSelection();
        }

        leftButtonPressed_ = true;
        manualSelectionActive_ = false;
        activeSelectionHandle_ = SelectionHandle::None;
        setManualSelectionRect({});
        pressedCandidateIndex_ = hitTestCandidateIndex(pressOverlayPoint_);
        pressedScreenFallback_ = pressedCandidateIndex_ < 0;
        setHoverState(pressedCandidateIndex_, pressedScreenFallback_);
        grabMouse();
        return;
    }

    QWidget::mousePressEvent(event);
}

void FreezeOverlayWidget::mouseReleaseEvent(QMouseEvent* event) {
    if (event->button() != Qt::LeftButton) {
        QWidget::mouseReleaseEvent(event);
        return;
    }

    hasPointerOverlayPoint_ = true;
    pointerOverlayPoint_ = globalToOverlayPoint(event->globalPosition());
    updatePointerColor();
    updateMagnifier();

    const bool hadManualSelection = manualSelectionActive_;
    leftButtonPressed_ = false;
    if (mouseGrabber() == this) {
        releaseMouse();
    }

    if (hadManualSelection && manualSelectionRect_.isValid() && !manualSelectionRect_.isEmpty()) {
        commitSelection(buildManualSelectionResult());
        return;
    }

    if (selectionCommitted_ && activeSelectionHandle_ != SelectionHandle::None) {
        activeSelectionHandle_ = SelectionHandle::None;
        updateToolbarGeometry();
        updateInfoGeometry();
        toolbar_->show();
        toolbar_->raise();
        updateCursorForPoint(globalToOverlayPoint(event->globalPosition()));
        update();
        return;
    }

    if (pressedCandidateIndex_ >= 0) {
        commitSelection(buildSelectionResult(candidates_.at(pressedCandidateIndex_)));
        return;
    }

    if (pressedScreenFallback_) {
        commitSelection(buildScreenSelectionResult());
        return;
    }

    pressedCandidateIndex_ = -1;
    pressedScreenFallback_ = false;
    activeSelectionHandle_ = SelectionHandle::None;
    setManualSelectionRect({});
    const int hoverCandidateIndex =
        hitTestCandidateIndex(globalToOverlayPoint(event->globalPosition()));
    setHoverState(hoverCandidateIndex, hoverCandidateIndex < 0);
    updateInfoGeometry();
}

void FreezeOverlayWidget::keyPressEvent(QKeyEvent* event) {
    if (event->key() == Qt::Key_Shift && !event->isAutoRepeat()) {
        colorFormatHex_ = !colorFormatHex_;
        updateInfoGeometry();
        return;
    }

    if (event->key() == Qt::Key_C
        && !(event->modifiers() & (Qt::ControlModifier
                                   | Qt::AltModifier
                                   | Qt::MetaModifier))) {
        triggerCopyHintFlash();
        if (hasPointerColor_) {
            emit colorPicked(formattedPointerColor(),
                             pointerColor_.name(QColor::HexRgb).toUpper(),
                             pointerOverlayPoint_ + capture_.virtualDesktopRect.topLeft());
        }
        return;
    }

    if (event->key() == Qt::Key_Escape) {
        if (mouseGrabber() == this) {
            releaseMouse();
        }
        infoPanel_->hide();
        hasPointerOverlayPoint_ = false;
        pointerOverlayPoint_ = {};
        hasPointerColor_ = false;
        pointerColor_ = {};
        updateMagnifier();
        emit selectionCanceled();
        close();
        return;
    }

    QWidget::keyPressEvent(event);
}

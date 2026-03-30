#include "core/capture/CaptureSessionController.h"

#include <QElapsedTimer>
#include <QPainter>
#include <algorithm>

#include "core/common/Logger.h"
#include "core/capture/ScreenCaptureManager.h"
#include "core/clipboard/ClipboardManager.h"

namespace {

qint64 hoverLatencyWindowUs() {
    const int envWindowMs = qEnvironmentVariableIntValue("KUCLAW_CAPTURE_HOVER_LATENCY_WINDOW_MS", nullptr);
    const int windowMs = envWindowMs > 0 ? envWindowMs : 200;
    return static_cast<qint64>(windowMs) * 1000LL;
}

qint64 hoverLatencySlaUs() {
    const int envSlaMs = qEnvironmentVariableIntValue("KUCLAW_CAPTURE_HOVER_LATENCY_SLA_MS", nullptr);
    const int slaMs = envSlaMs > 0 ? envSlaMs : 50;
    return static_cast<qint64>(slaMs) * 1000LL;
}

}  // namespace

CaptureSessionController::CaptureSessionController(ScreenCaptureManager* screenCaptureManager,
                                                   ClipboardManager* clipboardManager,
                                                   AnnotationManager* annotationManager,
                                                   QObject* parent)
    : QObject(parent),
      screenCaptureManager_(screenCaptureManager),
      clipboardManager_(clipboardManager),
      annotationManager_(annotationManager) {}

QRect CaptureSessionController::desktopGeometry() const {
    return desktopSnapshot_.virtualGeometry;
}

QImage CaptureSessionController::desktopImage() const {
    return desktopSnapshot_.image;
}

QList<DesktopScreenInfo> CaptureSessionController::screens() const {
    return desktopSnapshot_.screens;
}

QRect CaptureSessionController::selectionRect() const {
    return selectionRect_;
}

CaptureSessionController::CaptureState CaptureSessionController::state() const {
    return state_;
}

void CaptureSessionController::beginSession() {
    desktopSnapshot_ = screenCaptureManager_->captureDesktop();
    selectionRect_ = {};
    annotationManager_->clear();
    allowWindowAutoSelection_ = true;
    hoverWindowLatencySamples_.clear();
    hoverLatencyTimer_.start();
    lastHoverLatencyLogUs_ = 0;
    setState(CaptureState::Selecting);
    emit selectionRectChanged();
}

void CaptureSessionController::setWindowAutoSelectionEnabled(bool enabled) {
    allowWindowAutoSelection_ = enabled;
}

bool CaptureSessionController::isWindowAutoSelectionEnabled() const {
    return allowWindowAutoSelection_;
}

void CaptureSessionController::moveSelectionTo(int x, int y) {
    if (state_ == CaptureState::Idle || selectionRect_.isEmpty()) {
        return;
    }

    allowWindowAutoSelection_ = false;
    if (selectionRect_.x() == x && selectionRect_.y() == y) {
        return;
    }

    selectionRect_.moveTo(x, y);
    emit selectionRectChanged();
}

void CaptureSessionController::copyFullScreen() {
    if (state_ == CaptureState::Idle) {
        return;
    }

    selectionRect_ = {};
    emit selectionRectChanged();
    copyResultToClipboard();
}

void CaptureSessionController::cancelSession() {
    reportWindowHitLatencySnapshot(QStringLiteral("cancel"));
    resetSessionData();
    allowWindowAutoSelection_ = false;
    setState(CaptureState::Cancelled);
    setState(CaptureState::Idle);
}

void CaptureSessionController::updateSelection(const QRect& rect) {
    const QRect normalized = rect.normalized();
    if (selectionRect_ == normalized) {
        return;
    }

    if (!normalized.isEmpty()) {
        allowWindowAutoSelection_ = false;
    }

    selectionRect_ = normalized;
    setState(selectionRect_.isEmpty() ? CaptureState::Selecting : CaptureState::Selected);
    emit selectionRectChanged();
}

void CaptureSessionController::updateCursorPoint(const QPoint& point, bool trackWindow) {
    if (state_ == CaptureState::Idle) {
        return;
    }

    emit magnifierUpdated(screenCaptureManager_->buildMagnifierImage(point, 8, 8),
                          screenCaptureManager_->sampleColor(point));

    if (!trackWindow || !allowWindowAutoSelection_) {
        if (isHoverLatencyProfilingEnabled()) {
            hoverWindowLatencySamples_.clear();
            lastHoverLatencyLogUs_ = 0;
        }
        return;
    }

    QElapsedTimer localTimer;
    localTimer.start();

    QRect hoveredWindowRect;
    bool hoveredWindowVisible = false;
    if (!screenCaptureManager_->hoveredWindowAt(point, &hoveredWindowRect, nullptr, &hoveredWindowVisible)) {
        const qint64 elapsedUs = localTimer.nsecsElapsed() / 1000;
        if (isHoverLatencyProfilingEnabled()) {
            const qint64 nowUs = hoverLatencyTimer_.elapsed() * 1000LL;
            recordWindowHitLatency(nowUs, elapsedUs);
        }
        if (!selectionRect_.isNull()) {
            selectionRect_ = {};
            emit selectionRectChanged();
        }
        return;
    }

    if (!hoveredWindowVisible) {
        const qint64 elapsedUs = localTimer.nsecsElapsed() / 1000;
        if (isHoverLatencyProfilingEnabled()) {
            const qint64 nowUs = hoverLatencyTimer_.elapsed() * 1000LL;
            recordWindowHitLatency(nowUs, elapsedUs);
        }
        return;
    }

    const qint64 elapsedUs = localTimer.nsecsElapsed() / 1000;
    if (isHoverLatencyProfilingEnabled()) {
        const qint64 nowUs = hoverLatencyTimer_.elapsed() * 1000LL;
        recordWindowHitLatency(nowUs, elapsedUs);
    }

    if (selectionRect_ != hoveredWindowRect) {
        selectionRect_ = hoveredWindowRect;
        setState(CaptureState::Selected);
        emit selectionRectChanged();
    }
}

void CaptureSessionController::nudgeSelection(int dx, int dy) {
    if (state_ == CaptureState::Idle) {
        return;
    }

    allowWindowAutoSelection_ = false;

    if (selectionRect_.isEmpty()) {
        return;
    }

    selectionRect_.translate(dx, dy);
    emit selectionRectChanged();
}

void CaptureSessionController::resizeSelection(int left, int top, int right, int bottom) {
    if (state_ == CaptureState::Idle) {
        return;
    }

    allowWindowAutoSelection_ = false;

    if (selectionRect_.isEmpty()) {
        return;
    }

    const int nextX = selectionRect_.x() + left;
    const int nextY = selectionRect_.y() + top;
    const int nextWidth = selectionRect_.width() + right - left;
    const int nextHeight = selectionRect_.height() + bottom - top;

    if (nextWidth < 1 || nextHeight < 1) {
        return;
    }

    selectionRect_ = QRect(nextX, nextY, nextWidth, nextHeight);
    emit selectionRectChanged();
}

void CaptureSessionController::enterAnnotating() {
    if (selectionRect_.isEmpty()) {
        return;
    }

    setState(CaptureState::Annotating);
}

void CaptureSessionController::copyResultToClipboard() {
    const QImage image = exportImage();
    if (image.isNull()) {
        return;
    }

    clipboardManager_->setImage(image);
    resetSessionData();
    setState(CaptureState::Idle);
}

void CaptureSessionController::saveResultToFile(const QString& path) {
    const QImage image = exportImage();
    if (image.isNull() || path.isEmpty()) {
        return;
    }

    image.save(path);
    resetSessionData();
    setState(CaptureState::Idle);
}

void CaptureSessionController::pinResult() {
    const QImage image = exportImage();
    if (image.isNull()) {
        return;
    }

    emit sessionCompleted(image);
    resetSessionData();
    setState(CaptureState::Idle);
}

QImage CaptureSessionController::exportImage() const {
    if (desktopSnapshot_.image.isNull()) {
        return {};
    }

    const QRect sourceRect = selectionRect_.isEmpty()
        ? desktopSnapshot_.virtualGeometry
        : selectionRect_;
    const QRect translatedRect = sourceRect.translated(-desktopSnapshot_.virtualGeometry.topLeft());
    QImage result = desktopSnapshot_.image.copy(translatedRect);

    const QImage overlay = annotationManager_->renderOverlay(result.size());
    if (!overlay.isNull()) {
        QPainter painter(&result);
        painter.drawImage(0, 0, overlay);
    }

    return result;
}

void CaptureSessionController::resetSessionData() {
    selectionRect_ = {};
    desktopSnapshot_ = {};
    annotationManager_->clear();
    emit selectionRectChanged();
}

void CaptureSessionController::setState(CaptureState state) {
    if (state_ == state) {
        return;
    }

    if (state == CaptureState::Idle) {
        reportWindowHitLatencySnapshot(QStringLiteral("session-idle"));
    }

    state_ = state;
    emit stateChanged();
}

bool CaptureSessionController::isHoverLatencyProfilingEnabled() const {
    static const bool enabled = !qEnvironmentVariableIsEmpty("KUCLAW_CAPTURE_HOVER_LATENCY");
    return enabled;
}

void CaptureSessionController::recordWindowHitLatency(qint64 sessionTimeUs, qint64 latencyMicros) {
    if (!isHoverLatencyProfilingEnabled() || !hoverLatencyTimer_.isValid()) {
        return;
    }

    hoverWindowLatencySamples_.append(
        {sessionTimeUs, latencyMicros});

    const qint64 windowStartUs = sessionTimeUs - hoverLatencyWindowUs();
    while (!hoverWindowLatencySamples_.isEmpty()
           && hoverWindowLatencySamples_.first().elapsedSinceSessionUs < windowStartUs) {
        hoverWindowLatencySamples_.pop_front();
    }

    const qint64 nowUs = sessionTimeUs;
    if (lastHoverLatencyLogUs_ == 0) {
        lastHoverLatencyLogUs_ = sessionTimeUs;
    }
    if (nowUs - lastHoverLatencyLogUs_ >= hoverLatencyWindowUs()) {
        const QString windowReason =
            QString("window-%1ms").arg(hoverLatencyWindowUs() / 1000.0, 0, 'f', 0);
        reportWindowHitLatencySnapshot(windowReason);
        lastHoverLatencyLogUs_ = nowUs;
    }
}

qint64 CaptureSessionController::quantileUs(const QList<qint64>& samplesUs, double q) {
    if (samplesUs.isEmpty()) {
        return 0;
    }

    QList<qint64> sorted = samplesUs;
    std::sort(sorted.begin(), sorted.end());

    const int index = static_cast<int>(q * static_cast<double>(sorted.size() - 1));
    return sorted[qBound(0, index, sorted.size() - 1)];
}

void CaptureSessionController::reportWindowHitLatencySnapshot(const QString& reason) const {
    if (!isHoverLatencyProfilingEnabled() || hoverWindowLatencySamples_.isEmpty()) {
        return;
    }

    QList<qint64> latencies;
    latencies.reserve(hoverWindowLatencySamples_.size());
    for (const auto& sample : hoverWindowLatencySamples_) {
        latencies << sample.latencyUs;
    }

    const qint64 p50 = quantileUs(latencies, 0.5);
    const qint64 p95 = quantileUs(latencies, 0.95);
    const qint64 min = *std::min_element(latencies.cbegin(), latencies.cend());
    const qint64 max = *std::max_element(latencies.cbegin(), latencies.cend());
    const qint64 slaUs = hoverLatencySlaUs();
    const bool meetsSla = (p95 <= slaUs);
    const qint64 windowUs = hoverWindowLatencySamples_.isEmpty()
                                ? 0
                                : hoverWindowLatencySamples_.last().elapsedSinceSessionUs
                                      - hoverWindowLatencySamples_.first().elapsedSinceSessionUs;

    Logger::info("capture_perf",
                 QString("hoveredWindowAt(%1): p50=%2us p95=%3us min=%4us max=%5us "
                         "count=%6 span=%7ms sla=%8ms meets=%9")
                     .arg(reason)
                     .arg(p50)
                     .arg(p95)
                     .arg(min)
                     .arg(max)
                     .arg(hoverWindowLatencySamples_.size())
                     .arg(windowUs / 1000.0, 0, 'f', 1)
                     .arg(slaUs / 1000.0, 0, 'f', 1)
                     .arg(meetsSla ? "yes" : "no"));
}

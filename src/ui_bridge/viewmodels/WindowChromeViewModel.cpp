#include "ui_bridge/viewmodels/WindowChromeViewModel.h"

#include <utility>

#include <QEvent>
#include <QScreen>
#include <QWindow>

namespace {
constexpr int kRetryDelayMs = 16;
constexpr int kMaxRetryAttempts = 60;

WindowChromeMetrics defaultAttachMetrics(QWindow* window) {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    MacWindowChrome chrome;
    return chrome.attach(window);
#else
    Q_UNUSED(window);
    return {};
#endif
}

bool defaultBeginSystemDrag(QWindow* window) {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    MacWindowChrome chrome;
    return chrome.beginSystemDrag(window);
#else
    Q_UNUSED(window);
    return false;
#endif
}
}  // namespace

WindowChromeViewModel::WindowChromeViewModel(QObject* parent,
                                             AttachFunction attachFunction,
                                             DragFunction dragFunction)
    : QObject(parent),
      attachFunction_(std::move(attachFunction)),
      dragFunction_(std::move(dragFunction)) {
    retryTimer_.setSingleShot(true);
    connect(&retryTimer_, &QTimer::timeout, this, &WindowChromeViewModel::tryAttach);
}

bool WindowChromeViewModel::usesNativeTrafficLights() const {
    return metrics_.usesNativeTrafficLights;
}

int WindowChromeViewModel::trafficLightsSafeWidth() const {
    return metrics_.trafficLightsSafeWidth;
}

int WindowChromeViewModel::titleBarHeight() const {
    return metrics_.titleBarHeight;
}

void WindowChromeViewModel::attach(QObject* windowObject) {
    clearTrackedWindow();

    auto* window = qobject_cast<QWindow*>(windowObject);
    if (window == nullptr) {
        setMetrics({});
        return;
    }

    attachToWindow(window);
}

bool WindowChromeViewModel::beginSystemDrag() {
    if (trackedWindow_ == nullptr) {
        return false;
    }

    return dragFunction_ ? dragFunction_(trackedWindow_) : defaultBeginSystemDrag(trackedWindow_);
}

void WindowChromeViewModel::attachToWindow(QWindow* window) {
    trackedWindow_ = window;
    window->installEventFilter(this);
    connect(window, &QWindow::visibilityChanged, this, [this](QWindow::Visibility) {
        resetRetryState();
        tryAttach();
    });
    connect(window, &QWindow::screenChanged, this, [this](QScreen*) {
        resetRetryState();
        tryAttach();
    });
    connect(window, &QWindow::activeChanged, this, [this]() {
        resetRetryState();
        tryAttach();
    });
    connect(window, &QObject::destroyed, this, [this]() {
        clearTrackedWindow();
        setMetrics({});
    });

    tryAttach();
}

bool WindowChromeViewModel::eventFilter(QObject* watched, QEvent* event) {
    if (watched == trackedWindow_ && event != nullptr) {
        bool shouldReattach = false;
        switch (event->type()) {
        case QEvent::Show:
        case QEvent::Expose:
            shouldReattach = true;
            break;
        case QEvent::PlatformSurface: {
            auto* platformEvent = static_cast<QPlatformSurfaceEvent*>(event);
            shouldReattach =
                platformEvent->surfaceEventType() == QPlatformSurfaceEvent::SurfaceCreated;
            break;
        }
        default:
            break;
        }

        if (shouldReattach && !metrics_.usesNativeTrafficLights) {
            resetRetryState();
            tryAttach();
        }
    }

    return QObject::eventFilter(watched, event);
}

void WindowChromeViewModel::tryAttach() {
    if (trackedWindow_ == nullptr) {
        return;
    }

    const WindowChromeMetrics metrics =
        attachFunction_ ? attachFunction_(trackedWindow_) : defaultAttachMetrics(trackedWindow_);
    setMetrics(metrics);

    if (metrics.usesNativeTrafficLights) {
        resetRetryState();
        return;
    }

    scheduleRetry();
}

void WindowChromeViewModel::scheduleRetry() {
    if (!shouldRetry() || retryTimer_.isActive()) {
        return;
    }

    if (retryAttempts_ >= kMaxRetryAttempts) {
        return;
    }

    ++retryAttempts_;
    retryTimer_.start(kRetryDelayMs);
}

void WindowChromeViewModel::resetRetryState() {
    retryTimer_.stop();
    retryAttempts_ = 0;
}

bool WindowChromeViewModel::shouldRetry() const {
    if (trackedWindow_ == nullptr || metrics_.usesNativeTrafficLights) {
        return false;
    }

    if (attachFunction_) {
        return true;
    }

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    return trackedWindow_->visibility() != QWindow::Hidden;
#else
    return false;
#endif
}

void WindowChromeViewModel::clearTrackedWindow() {
    if (trackedWindow_ != nullptr) {
        trackedWindow_->removeEventFilter(this);
        disconnect(trackedWindow_, nullptr, this, nullptr);
    }
    resetRetryState();
    trackedWindow_.clear();
}

void WindowChromeViewModel::setMetrics(const WindowChromeMetrics& metrics) {
    if (metrics_.usesNativeTrafficLights == metrics.usesNativeTrafficLights
        && metrics_.trafficLightsSafeWidth == metrics.trafficLightsSafeWidth
        && metrics_.titleBarHeight == metrics.titleBarHeight) {
        return;
    }

    metrics_ = metrics;
    emit metricsChanged();
}

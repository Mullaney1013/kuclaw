#include "ui_bridge/viewmodels/WindowChromeViewModel.h"

#include <utility>

#include <QEvent>
#include <QMetaObject>
#include <QRectF>
#include <QScreen>
#include <QString>
#include <QDebug>
#include <QVariant>
#include <QWindow>

namespace {
constexpr int kRetryDelayMs = 16;
constexpr int kRetryDelayMsAfterWarmup = 50;
constexpr int kRetryDelayMsAfterStartup = 125;
constexpr int kWarmupRetryAttempts = 60;
constexpr int kStartupRetryAttempts = 180;

bool defaultBeginSystemDrag(QWindow* window) {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    MacWindowChrome chrome;
    return chrome.beginSystemDrag(window);
#else
    Q_UNUSED(window);
    return false;
#endif
}

bool defaultToggleNativeFullscreen(QWindow* window) {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    MacWindowChrome chrome;
    return chrome.toggleNativeFullscreen(window);
#else
    Q_UNUSED(window);
    return false;
#endif
}

void defaultDetachNativeChrome(QWindow* window, WId nativeId) {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    MacWindowChrome chrome;
    if (window != nullptr) {
        chrome.detach(window);
    } else if (nativeId != 0) {
        chrome.detach(nativeId);
    }
#else
    Q_UNUSED(window);
    Q_UNUSED(nativeId);
#endif
}

int retryDelayMsForAttempt(int retryAttempt) {
    if (retryAttempt <= kWarmupRetryAttempts) {
        return kRetryDelayMs;
    }

    if (retryAttempt <= kStartupRetryAttempts) {
        return kRetryDelayMsAfterWarmup;
    }

    return kRetryDelayMsAfterStartup;
}
}  // namespace

WindowChromeViewModel::WindowChromeViewModel(QObject* parent,
                                             AttachFunction attachFunction,
                                             DragFunction dragFunction,
                                             ToggleFullscreenFunction toggleFullscreenFunction,
                                             DetachFunction detachFunction,
                                             UpdateToolbarStateFunction updateToolbarStateFunction)
    : QObject(parent),
      attachFunction_(std::move(attachFunction)),
      dragFunction_(dragFunction ? std::move(dragFunction) : defaultBeginSystemDrag),
      toggleFullscreenFunction_(toggleFullscreenFunction ? std::move(toggleFullscreenFunction)
                                                         : defaultToggleNativeFullscreen),
      detachFunction_(detachFunction ? std::move(detachFunction) : defaultDetachNativeChrome),
      updateToolbarStateFunction_(updateToolbarStateFunction) {
    retryTimer_.setSingleShot(true);
    connect(&retryTimer_, &QTimer::timeout, this, &WindowChromeViewModel::tryAttach);
}

WindowChromeViewModel::~WindowChromeViewModel() {
    clearTrackedWindow();
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

    return dragFunction_ ? dragFunction_(trackedWindow_) : chrome_.beginSystemDrag(trackedWindow_);
}

bool WindowChromeViewModel::toggleNativeFullscreen() {
    if (trackedWindow_ == nullptr) {
        return false;
    }

    return toggleFullscreenFunction_ ? toggleFullscreenFunction_(trackedWindow_)
                                     : chrome_.toggleNativeFullscreen(trackedWindow_);
}

void WindowChromeViewModel::updateNativeToolbarState(bool backEnabled, bool forwardEnabled) {
    nativeBackEnabled_ = backEnabled;
    nativeForwardEnabled_ = forwardEnabled;

    if (trackedWindow_ == nullptr || !ownsNativeChromeAttachment_) {
        return;
    }

    if (updateToolbarStateFunction_) {
        updateToolbarStateFunction_(trackedWindow_, nativeBackEnabled_, nativeForwardEnabled_);
        return;
    }

    chrome_.updateNativeToolbarState(trackedWindow_, nativeBackEnabled_, nativeForwardEnabled_);
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
        clearTrackedWindow(nullptr, true);
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
            if (platformEvent->surfaceEventType() == QPlatformSurfaceEvent::SurfaceAboutToBeDestroyed) {
                if (ownsNativeChromeAttachment_) {
                    detachNativeChrome(nativeChromeDetachWindow_ != nullptr ? nativeChromeDetachWindow_
                                                                            : trackedWindow_.data(),
                                       nativeChromeDetachId_);
                    ownsNativeChromeAttachment_ = false;
                }
                nativeChromeDetachWindow_ = nullptr;
                nativeChromeDetachId_ = 0;
                nativeChromeAttached_ = false;
                resetRetryState();
                setMetrics({});
            } else {
                shouldReattach =
                    platformEvent->surfaceEventType() == QPlatformSurfaceEvent::SurfaceCreated;
            }
            break;
        }
        default:
            break;
        }

        if (shouldReattach) {
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

    auto queueSidebarToggle = [this]() { notifySidebarToggleRequested(); };
    auto queueBack = [this]() { notifyBackRequested(); };
    auto queueForward = [this]() { notifyForwardRequested(); };

    WindowChromeMetrics metrics;
    if (attachFunction_) {
        metrics = attachFunction_(trackedWindow_, queueSidebarToggle, queueBack, queueForward);
        nativeChromeAttached_ = metrics.usesNativeTrafficLights;
        ownsNativeChromeAttachment_ = metrics.usesNativeTrafficLights;
        nativeChromeDetachWindow_ = metrics.usesNativeTrafficLights ? trackedWindow_.data() : nullptr;
        nativeChromeDetachId_ = metrics.usesNativeTrafficLights && trackedWindow_ != nullptr
                                    && trackedWindow_->handle() != nullptr
                                    ? trackedWindow_->winId()
                                    : 0;
    } else {
        metrics = chrome_.attach(trackedWindow_, queueSidebarToggle, queueBack, queueForward);
        nativeChromeAttached_ = metrics.usesNativeTrafficLights;
        ownsNativeChromeAttachment_ = metrics.usesNativeTrafficLights;
        nativeChromeDetachWindow_ = metrics.usesNativeTrafficLights ? trackedWindow_.data() : nullptr;
        nativeChromeDetachId_ = metrics.usesNativeTrafficLights && trackedWindow_ != nullptr
                                    && trackedWindow_->handle() != nullptr
                                    ? trackedWindow_->winId()
                                    : 0;
    }
    setMetrics(metrics);

    if (metrics.usesNativeTrafficLights) {
        if (updateToolbarStateFunction_) {
            updateToolbarStateFunction_(trackedWindow_, nativeBackEnabled_, nativeForwardEnabled_);
        } else {
            chrome_.updateNativeToolbarState(trackedWindow_, nativeBackEnabled_, nativeForwardEnabled_);
        }
    }

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

    ++retryAttempts_;
    retryTimer_.start(retryDelayMsForAttempt(retryAttempts_));
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

void WindowChromeViewModel::clearTrackedWindow(QWindow* detachWindow, bool allowNativeDetach) {
    QWindow* detachTarget = detachWindow;

    if (allowNativeDetach && ownsNativeChromeAttachment_
        && (detachTarget != nullptr || nativeChromeDetachId_ != 0)) {
        detachNativeChrome(detachTarget, nativeChromeDetachId_);
    }

    if (trackedWindow_ != nullptr) {
        trackedWindow_->removeEventFilter(this);
        disconnect(trackedWindow_, nullptr, this, nullptr);
    }
    resetRetryState();
    nativeChromeAttached_ = false;
    ownsNativeChromeAttachment_ = false;
    nativeChromeDetachWindow_ = nullptr;
    nativeChromeDetachId_ = 0;
    trackedWindow_.clear();
}

void WindowChromeViewModel::detachNativeChrome(QWindow* window, WId nativeId) {
    if (window == nullptr && nativeId == 0) {
        return;
    }

    if (detachFunction_) {
        detachFunction_(window, nativeId);
        return;
    }

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (window != nullptr) {
        chrome_.detach(window);
    } else {
        chrome_.detach(nativeId);
    }
#else
    Q_UNUSED(window);
    Q_UNUSED(nativeId);
#endif
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

bool WindowChromeViewModel::invokeTrackedWindowMethod(const char* method) {
    return trackedWindow_ != nullptr
           && QMetaObject::invokeMethod(trackedWindow_, method, Qt::DirectConnection);
}

bool WindowChromeViewModel::invokeTrackedWindowMethod(const char* method, const QVariant& argument) {
    if (trackedWindow_ == nullptr) {
        return false;
    }

    if (QMetaObject::invokeMethod(trackedWindow_,
                                  method,
                                  Qt::DirectConnection,
                                  Q_ARG(QVariant, argument))) {
        return true;
    }

    return argument.canConvert<QString>()
           && QMetaObject::invokeMethod(trackedWindow_,
                                        method,
                                        Qt::DirectConnection,
                                        Q_ARG(QString, argument.toString()));
}

void WindowChromeViewModel::notifySidebarToggleRequested() {
    const bool invoked =
        invokeTrackedWindowMethod("dispatchShellEvent", QVariant(QStringLiteral("TOGGLE_CLICKED")));
    if (!invoked) {
        emit sidebarToggleRequested();
    }
}

void WindowChromeViewModel::notifyBackRequested() {
    const bool invoked = invokeTrackedWindowMethod("goBack");
    if (!invoked) {
        emit backRequested();
    }
}

void WindowChromeViewModel::notifyForwardRequested() {
    const bool invoked = invokeTrackedWindowMethod("goForward");
    if (!invoked) {
        emit forwardRequested();
    }
}

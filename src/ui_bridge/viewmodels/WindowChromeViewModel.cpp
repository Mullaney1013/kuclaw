#include "ui_bridge/viewmodels/WindowChromeViewModel.h"

#include <QWindow>

namespace {
WindowChromeMetrics defaultAttachMetrics(QWindow* window) {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    MacWindowChrome chrome;
    return chrome.attach(window);
#else
    Q_UNUSED(window);
    return {};
#endif
}
}  // namespace

WindowChromeViewModel::WindowChromeViewModel(QObject* parent, AttachFunction attachFunction)
    : QObject(parent), attachFunction_(std::move(attachFunction)) {}

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
    auto* window = qobject_cast<QWindow*>(windowObject);
    if (window == nullptr) {
        setMetrics({});
        return;
    }

    if (attachFunction_) {
        setMetrics(attachFunction_(window));
        return;
    }

    setMetrics(defaultAttachMetrics(window));
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

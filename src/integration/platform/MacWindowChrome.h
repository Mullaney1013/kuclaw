#pragma once

#include <QWindow>

struct WindowChromeMetrics {
    bool usesNativeTrafficLights = false;
    int trafficLightsSafeWidth = 0;
    int titleBarHeight = 0;
};

class MacWindowChrome final {
public:
    WindowChromeMetrics attach(QWindow* window);
};

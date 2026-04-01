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
    bool beginSystemDrag(QWindow* window);
    int titleBarDragRegionStartXForMetrics(const WindowChromeMetrics& metrics) const;
    bool hasTitleBarDragRegion(QWindow* window) const;
    bool titleBarDragRegionCapturesHitTest(QWindow* window) const;
    bool titleBarDragRegionCapturesTrailingHitTest(QWindow* window) const;
    bool hasTitleBarDragMonitor(QWindow* window) const;
};

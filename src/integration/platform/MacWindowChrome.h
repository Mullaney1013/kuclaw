#pragma once

#include <functional>

#include <QRect>
#include <QWindow>

struct WindowChromeMetrics {
    bool usesNativeTrafficLights = false;
    int trafficLightsSafeWidth = 0;
    int titleBarHeight = 0;
};

struct TrafficLightsGeometry {
    bool valid = false;
    int closeButtonTopInset = 0;
    int closeButtonMidY = 0;
    int closeButtonMidYFromTop = 0;
    int clusterTopInset = 0;
    int clusterMidY = 0;
    int clusterMidYFromTop = 0;
    int closeMinSpacing = 0;
    int minZoomSpacing = 0;
    int clusterWidth = 0;
};

struct NativeNavigationState {
    bool valid = false;
    bool backEnabled = false;
    bool forwardEnabled = false;
};

class MacWindowChrome final {
public:
    WindowChromeMetrics attach(QWindow* window,
                               std::function<void()> sidebarToggleHandler = {},
                               std::function<void()> backHandler = {},
                               std::function<void()> forwardHandler = {});
    void updateNativeToolbarState(QWindow* window, bool backEnabled, bool forwardEnabled);
    void detach(QWindow* window);
    void detach(WId nativeId);
    bool beginSystemDrag(QWindow* window);
    bool toggleNativeFullscreen(QWindow* window);
    TrafficLightsGeometry trafficLightsGeometry(QWindow* window) const;
    int titleBarDragRegionStartXForMetrics(const WindowChromeMetrics& metrics) const;
    int currentTitleBarDragRegionStartX(QWindow* window) const;
    bool hasTitleBarDragRegion(QWindow* window) const;
    bool hasTitleBarDragRegion(WId nativeId) const;
    bool supportsNativeFullscreen(QWindow* window) const;
    bool titleBarDragRegionCapturesHitTest(QWindow* window) const;
    bool titleBarDragRegionCapturesTrailingHitTest(QWindow* window) const;
    bool hasTitleBarDragMonitor(QWindow* window) const;
    bool hasTitleBarDragMonitor(WId nativeId) const;
    bool hasToolbarChrome(WId nativeId) const;
    bool hasLeadingToolbarCluster(QWindow* window) const;
    QRect leadingToolbarClusterFrame(QWindow* window) const;
    bool leadingToolbarClusterCapturesHitTest(QWindow* window) const;
    bool leadingToolbarClusterUsesDirectTitlebarHost(QWindow* window) const;
    bool leadingToolbarClusterUsesToolbarItem(QWindow* window) const;
    NativeNavigationState navigationEnabledState(QWindow* window) const;
    bool hasHiddenTitlebarSeparator(WId nativeId) const;
};

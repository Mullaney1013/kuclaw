#pragma once

#include <functional>

#include <QRectF>
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

class MacWindowChrome final {
public:
    WindowChromeMetrics attach(QWindow* window,
                               std::function<void()> sidebarToggleHandler = {},
                               std::function<void()> backHandler = {},
                               std::function<void()> forwardHandler = {});
    void detach(QWindow* window);
    void detach(WId nativeId);
    bool beginSystemDrag(QWindow* window);
    bool toggleNativeFullscreen(QWindow* window);
    TrafficLightsGeometry trafficLightsGeometry(QWindow* window) const;
    void setTitleBarControlRects(const QRectF& sidebarToggleRect,
                                 const QRectF& backRect,
                                 const QRectF& forwardRect);
    int titleBarDragRegionStartXForMetrics(const WindowChromeMetrics& metrics) const;
    int titleBarDragRegionStartXForLayout(const WindowChromeMetrics& metrics,
                                          const QRectF& sidebarToggleRect,
                                          const QRectF& backRect,
                                          const QRectF& forwardRect) const;
    int currentTitleBarDragRegionStartX(QWindow* window) const;
    bool hasTitleBarDragRegion(QWindow* window) const;
    bool supportsNativeFullscreen(QWindow* window) const;
    bool titleBarDragRegionCapturesHitTest(QWindow* window) const;
    bool titleBarDragRegionCapturesTrailingHitTest(QWindow* window) const;
    bool hasTitleBarDragMonitor(QWindow* window) const;

private:
    QRectF sidebarToggleRect_;
    QRectF backRect_;
    QRectF forwardRect_;
};

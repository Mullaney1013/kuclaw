#include "integration/platform/MacWindowChrome.h"

#include <QtMath>

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
#import <AppKit/AppKit.h>
#endif

WindowChromeMetrics MacWindowChrome::attach(QWindow* window) {
    WindowChromeMetrics metrics;

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (window == nullptr) {
        return metrics;
    }

    const WId nativeId = window->winId();
    if (nativeId == 0) {
        return metrics;
    }

    auto* nativeView = (__bridge NSView*)(reinterpret_cast<void*>(nativeId));
    if (nativeView == nil) {
        return metrics;
    }

    NSWindow* nsWindow = nativeView.window;
    if (nsWindow == nil) {
        return metrics;
    }

    nsWindow.titleVisibility = NSWindowTitleHidden;
    nsWindow.titlebarAppearsTransparent = YES;
    nsWindow.styleMask |= NSWindowStyleMaskFullSizeContentView;

    NSButton* closeButton = [nsWindow standardWindowButton:NSWindowCloseButton];
    NSButton* zoomButton = [nsWindow standardWindowButton:NSWindowZoomButton];
    if (closeButton == nil || zoomButton == nil) {
        return metrics;
    }

    const NSRect closeFrame = closeButton.frame;
    const NSRect zoomFrame = zoomButton.frame;
    const CGFloat leftInset = NSMinX(closeFrame);
    const CGFloat rightEdge = NSMaxX(zoomFrame);

    const CGFloat titleBarHeight = qMax(0.0, NSHeight(nsWindow.frame) - NSHeight(nsWindow.contentLayoutRect));

    metrics.usesNativeTrafficLights = true;
    metrics.trafficLightsSafeWidth = qCeil(rightEdge + leftInset);
    metrics.titleBarHeight = qCeil(titleBarHeight);
#else
    Q_UNUSED(window);
#endif

    return metrics;
}

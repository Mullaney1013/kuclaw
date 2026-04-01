#include "integration/platform/MacWindowChrome.h"

#include <QtMath>

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
#import <AppKit/AppKit.h>
#import <objc/runtime.h>

@interface KuclawWindowDragView : NSView
@end

@implementation KuclawWindowDragView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self != nil) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = NSColor.clearColor.CGColor;
        self.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    }
    return self;
}

- (BOOL)isOpaque {
    return NO;
}

- (BOOL)acceptsFirstMouse:(NSEvent*)event {
    Q_UNUSED(event);
    return YES;
}

- (BOOL)mouseDownCanMoveWindow {
    return YES;
}

- (NSView*)hitTest:(NSPoint)point {
    if (self.hidden || !NSPointInRect(point, self.bounds)) {
        return nil;
    }

    return self;
}

- (void)mouseDown:(NSEvent*)event {
    if (self.window != nil && event != nil) {
        [self.window performWindowDragWithEvent:event];
        return;
    }

    [super mouseDown:event];
}

@end
#endif

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
namespace {
constexpr CGFloat kTitleBarDragRegionStartX = 192.0;
constexpr CGFloat kTitleBarDragRegionMinHeight = 56.0;
const void* kWindowDragViewAssociationKey = &kWindowDragViewAssociationKey;

static NSRect dragRegionFrameForView(NSView* nativeView, CGFloat titleBarHeight) {
    const CGFloat safeHeight = qMax(titleBarHeight, kTitleBarDragRegionMinHeight);
    const CGFloat clampedWidth = qMax<CGFloat>(0.0, NSWidth(nativeView.bounds) - kTitleBarDragRegionStartX);
    const CGFloat topAlignedY = qMax<CGFloat>(0.0, NSHeight(nativeView.bounds) - safeHeight);
    return NSMakeRect(kTitleBarDragRegionStartX, topAlignedY, clampedWidth, safeHeight);
}

static KuclawWindowDragView* dragRegionViewForNativeView(NSView* nativeView) {
    return (KuclawWindowDragView*)objc_getAssociatedObject(nativeView, kWindowDragViewAssociationKey);
}

static void installOrUpdateDragRegion(NSView* nativeView, CGFloat titleBarHeight) {
    if (nativeView == nil) {
        return;
    }

    KuclawWindowDragView* dragView = dragRegionViewForNativeView(nativeView);
    if (dragView == nil) {
        dragView = [[KuclawWindowDragView alloc] initWithFrame:NSZeroRect];
        objc_setAssociatedObject(nativeView,
                                 kWindowDragViewAssociationKey,
                                 dragView,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [nativeView addSubview:dragView positioned:NSWindowAbove relativeTo:nil];
    }

    dragView.frame = dragRegionFrameForView(nativeView, titleBarHeight);
    dragView.hidden = NSIsEmptyRect(dragView.frame);
}
}  // namespace
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

    nsWindow.movableByWindowBackground = YES;
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

    installOrUpdateDragRegion(nativeView, titleBarHeight);
#else
    Q_UNUSED(window);
#endif

    return metrics;
}

bool MacWindowChrome::beginSystemDrag(QWindow* window) {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (window == nullptr) {
        return false;
    }

    const WId nativeId = window->winId();
    if (nativeId == 0) {
        return false;
    }

    auto* nativeView = (__bridge NSView*)(reinterpret_cast<void*>(nativeId));
    if (nativeView == nil) {
        return false;
    }

    NSWindow* nsWindow = nativeView.window;
    if (nsWindow == nil) {
        return false;
    }

    NSEvent* currentEvent = NSApp.currentEvent;
    if (currentEvent == nil) {
        return false;
    }

    const NSEventType eventType = currentEvent.type;
    if (eventType != NSEventTypeLeftMouseDown && eventType != NSEventTypeLeftMouseDragged) {
        return false;
    }

    [nsWindow performWindowDragWithEvent:currentEvent];
    return true;
#else
    Q_UNUSED(window);
    return false;
#endif
}

bool MacWindowChrome::hasTitleBarDragRegion(QWindow* window) const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (window == nullptr) {
        return false;
    }

    const WId nativeId = window->winId();
    if (nativeId == 0) {
        return false;
    }

    auto* nativeView = (__bridge NSView*)(reinterpret_cast<void*>(nativeId));
    if (nativeView == nil) {
        return false;
    }

    KuclawWindowDragView* dragView = dragRegionViewForNativeView(nativeView);
    return dragView != nil && !dragView.hidden && !NSIsEmptyRect(dragView.frame);
#else
    Q_UNUSED(window);
    return false;
#endif
}


bool MacWindowChrome::titleBarDragRegionCapturesHitTest(QWindow* window) const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (window == nullptr) {
        return false;
    }

    const WId nativeId = window->winId();
    if (nativeId == 0) {
        return false;
    }

    auto* nativeView = (__bridge NSView*)(reinterpret_cast<void*>(nativeId));
    if (nativeView == nil) {
        return false;
    }

    KuclawWindowDragView* dragView = dragRegionViewForNativeView(nativeView);
    if (dragView == nil || dragView.hidden || NSIsEmptyRect(dragView.frame)) {
        return false;
    }

    const NSRect dragFrame = dragView.frame;
    const NSPoint testPoint = NSMakePoint(NSMidX(dragFrame), NSMidY(dragFrame));
    NSView* hitView = [nativeView hitTest:testPoint];
    return hitView == dragView;
#else
    Q_UNUSED(window);
    return false;
#endif
}

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
const void* kWindowDragMonitorAssociationKey = &kWindowDragMonitorAssociationKey;

static NSView* titleBarContainerView(NSWindow* nsWindow) {
    if (nsWindow == nil) {
        return nil;
    }

    NSButton* closeButton = [nsWindow standardWindowButton:NSWindowCloseButton];
    NSView* titleBarView = closeButton.superview;
    if (titleBarView != nil && titleBarView.superview != nil) {
        return titleBarView.superview;
    }

    return titleBarView;
}

static NSView* dragRegionHostViewForWindow(NSWindow* nsWindow, NSView* nativeView) {
    NSView* titleBarContainer = titleBarContainerView(nsWindow);
    if (titleBarContainer != nil) {
        return titleBarContainer;
    }

    if (nativeView != nil && nativeView.superview != nil) {
        return nativeView.superview;
    }

    if (nativeView != nil) {
        return nativeView;
    }

    if (nsWindow != nil && nsWindow.contentView != nil) {
        return nsWindow.contentView;
    }

    return nil;
}

static NSRect dragRegionFrameForView(NSView* nativeView, CGFloat titleBarHeight) {
    const CGFloat hostHeight = NSHeight(nativeView.bounds);
    const CGFloat safeHeight = qMin(hostHeight, qMax(titleBarHeight, kTitleBarDragRegionMinHeight));
    const CGFloat clampedWidth = qMax<CGFloat>(0.0, NSWidth(nativeView.bounds) - kTitleBarDragRegionStartX);
    const CGFloat topAlignedY = qMax<CGFloat>(0.0, hostHeight - safeHeight);
    return NSMakeRect(kTitleBarDragRegionStartX, topAlignedY, clampedWidth, safeHeight);
}

static NSRect dragRegionRectForWindow(NSWindow* nsWindow, CGFloat titleBarHeight) {
    if (nsWindow == nil) {
        return NSZeroRect;
    }

    const CGFloat windowWidth = NSWidth(nsWindow.frame);
    const CGFloat windowHeight = NSHeight(nsWindow.frame);
    const CGFloat safeHeight = qMin(windowHeight, qMax(titleBarHeight, kTitleBarDragRegionMinHeight));
    const CGFloat clampedWidth = qMax<CGFloat>(0.0, windowWidth - kTitleBarDragRegionStartX);
    const CGFloat topAlignedY = qMax<CGFloat>(0.0, windowHeight - safeHeight);
    return NSMakeRect(kTitleBarDragRegionStartX, topAlignedY, clampedWidth, safeHeight);
}

static KuclawWindowDragView* dragRegionViewForWindow(NSWindow* nsWindow) {
    if (nsWindow == nil) {
        return nil;
    }

    return (KuclawWindowDragView*)objc_getAssociatedObject(nsWindow, kWindowDragViewAssociationKey);
}

static id dragRegionMonitorForWindow(NSWindow* nsWindow) {
    if (nsWindow == nil) {
        return nil;
    }

    return objc_getAssociatedObject(nsWindow, kWindowDragMonitorAssociationKey);
}

static void installOrUpdateDragMonitor(NSWindow* nsWindow, CGFloat titleBarHeight) {
    if (nsWindow == nil) {
        return;
    }

    id existingMonitor = dragRegionMonitorForWindow(nsWindow);
    if (existingMonitor != nil) {
        [NSEvent removeMonitor:existingMonitor];
        objc_setAssociatedObject(nsWindow, kWindowDragMonitorAssociationKey, nil, OBJC_ASSOCIATION_ASSIGN);
    }

    __weak NSWindow* weakWindow = nsWindow;
    id monitor =
        [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown
                                              handler:^NSEvent* _Nullable(NSEvent* _Nonnull event) {
                                                  NSWindow* strongWindow = weakWindow;
                                                  if (strongWindow == nil || event == nil || event.window != strongWindow) {
                                                      return event;
                                                  }

                                                  const CGFloat currentTitleBarHeight =
                                                      qMax(0.0, NSHeight(strongWindow.frame)
                                                                     - NSHeight(strongWindow.contentLayoutRect));
                                                  const NSRect dragRect =
                                                      dragRegionRectForWindow(strongWindow, currentTitleBarHeight);
                                                  if (!NSPointInRect(event.locationInWindow, dragRect)) {
                                                      return event;
                                                  }

                                                  [strongWindow performWindowDragWithEvent:event];
                                                  return nil;
                                              }];

    objc_setAssociatedObject(nsWindow,
                             kWindowDragMonitorAssociationKey,
                             monitor,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void installOrUpdateDragRegion(NSWindow* nsWindow, NSView* nativeView, CGFloat titleBarHeight) {
    NSView* hostView = dragRegionHostViewForWindow(nsWindow, nativeView);
    if (hostView == nil || nsWindow == nil) {
        return;
    }

    KuclawWindowDragView* dragView = dragRegionViewForWindow(nsWindow);
    if (dragView == nil) {
        dragView = [[KuclawWindowDragView alloc] initWithFrame:NSZeroRect];
        objc_setAssociatedObject(nsWindow,
                                 kWindowDragViewAssociationKey,
                                 dragView,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    NSView* relativeView = nil;
    for (NSView* subview in hostView.subviews.reverseObjectEnumerator) {
        if (subview != dragView) {
            relativeView = subview;
            break;
        }
    }
    if (dragView.superview != hostView) {
        [dragView removeFromSuperview];
    }
    [hostView addSubview:dragView positioned:NSWindowAbove relativeTo:relativeView];

    dragView.frame = dragRegionFrameForView(hostView, titleBarHeight);
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

    installOrUpdateDragRegion(nsWindow, nativeView, titleBarHeight);
    installOrUpdateDragMonitor(nsWindow, titleBarHeight);
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

    NSWindow* nsWindow = nativeView.window;
    KuclawWindowDragView* dragView = dragRegionViewForWindow(nsWindow);
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
    if (nativeView == nil || nativeView.window == nil) {
        return false;
    }

    NSWindow* nsWindow = nativeView.window;
    const CGFloat titleBarHeight =
        qMax(0.0, NSHeight(nsWindow.frame) - NSHeight(nsWindow.contentLayoutRect));
    const NSRect dragRect = dragRegionRectForWindow(nsWindow, titleBarHeight);
    if (dragRegionMonitorForWindow(nsWindow) == nil || NSIsEmptyRect(dragRect)) {
        return false;
    }

    const NSPoint testPoint = NSMakePoint(NSMidX(dragRect), NSMidY(dragRect));
    return NSPointInRect(testPoint, dragRect);
#else
    Q_UNUSED(window);
    return false;
#endif
}


bool MacWindowChrome::titleBarDragRegionCapturesTrailingHitTest(QWindow* window) const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (window == nullptr) {
        return false;
    }

    const WId nativeId = window->winId();
    if (nativeId == 0) {
        return false;
    }

    auto* nativeView = (__bridge NSView*)(reinterpret_cast<void*>(nativeId));
    if (nativeView == nil || nativeView.window == nil) {
        return false;
    }

    NSWindow* nsWindow = nativeView.window;
    const CGFloat titleBarHeight =
        qMax(0.0, NSHeight(nsWindow.frame) - NSHeight(nsWindow.contentLayoutRect));
    const NSRect dragRect = dragRegionRectForWindow(nsWindow, titleBarHeight);
    if (dragRegionMonitorForWindow(nsWindow) == nil || NSIsEmptyRect(dragRect)) {
        return false;
    }

    const NSPoint testPoint = NSMakePoint(NSMaxX(dragRect) - 24.0, NSMidY(dragRect));
    return NSPointInRect(testPoint, dragRect);
#else
    Q_UNUSED(window);
    return false;
#endif
}

bool MacWindowChrome::hasTitleBarDragMonitor(QWindow* window) const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (window == nullptr) {
        return false;
    }

    const WId nativeId = window->winId();
    if (nativeId == 0) {
        return false;
    }

    auto* nativeView = (__bridge NSView*)(reinterpret_cast<void*>(nativeId));
    if (nativeView == nil || nativeView.window == nil) {
        return false;
    }

    return dragRegionMonitorForWindow(nativeView.window) != nil;
#else
    Q_UNUSED(window);
    return false;
#endif
}

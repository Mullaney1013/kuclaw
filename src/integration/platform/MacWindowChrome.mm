#include "integration/platform/MacWindowChrome.h"

#include <QGuiApplication>
#include <QtMath>
#include <QDebug>

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
#import <AppKit/AppKit.h>
#import <objc/runtime.h>

@interface KuclawWindowDragView : NSView
@end

@interface KuclawChromeToolbarDelegate : NSObject <NSToolbarDelegate>
@end

typedef NS_ENUM(NSInteger, KuclawPendingTitleBarAction) {
    KuclawPendingTitleBarActionNone = 0,
    KuclawPendingTitleBarActionSidebarToggle,
    KuclawPendingTitleBarActionBack,
    KuclawPendingTitleBarActionForward,
};

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

@implementation KuclawChromeToolbarDelegate

- (NSArray<NSToolbarItemIdentifier>*)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    Q_UNUSED(toolbar);
    return @[];
}

- (NSArray<NSToolbarItemIdentifier>*)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    Q_UNUSED(toolbar);
    return @[];
}

- (NSArray<NSToolbarItemIdentifier>*)toolbarSelectableItemIdentifiers:(NSToolbar*)toolbar {
    Q_UNUSED(toolbar);
    return @[];
}

@end
#endif

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
namespace {
constexpr CGFloat kTitleBarDragRegionMinHeight = 56.0;
constexpr CGFloat kTitleBarControlsHeight = 20.0;
constexpr CGFloat kTitleBarControlSafeWidthMin = 78.0;
constexpr CGFloat kTitleBarControlSafeWidthMax = 96.0;
constexpr CGFloat kSidebarToggleLeadingGap = 12.0;
constexpr CGFloat kSidebarToggleWidth = 20.0;
constexpr CGFloat kTitleBarControlsClusterWidth = 82.0;
constexpr CGFloat kTitleBarDragRegionLeadingGap = 20.0;
constexpr CGFloat kBackButtonX = 40.0;
constexpr CGFloat kBackButtonWidth = 12.0;
constexpr CGFloat kForwardButtonX = 56.0;
constexpr CGFloat kForwardButtonWidth = 12.0;
const void* kWindowDragViewAssociationKey = &kWindowDragViewAssociationKey;
const void* kWindowDragMonitorAssociationKey = &kWindowDragMonitorAssociationKey;
const void* kWindowToolbarAssociationKey = &kWindowToolbarAssociationKey;
const void* kWindowToolbarDelegateAssociationKey = &kWindowToolbarDelegateAssociationKey;
const void* kWindowPendingActionAssociationKey = &kWindowPendingActionAssociationKey;

static bool runningOnCocoaPlatform() {
    return QGuiApplication::platformName() == QStringLiteral("cocoa");
}

static NSView* nativeViewForId(WId nativeId) {
    if (nativeId == 0) {
        return nil;
    }

    return (__bridge NSView*)(reinterpret_cast<void*>(nativeId));
}

static NSWindow* nativeWindowForId(WId nativeId) {
    NSView* nativeView = nativeViewForId(nativeId);
    return nativeView != nil ? nativeView.window : nil;
}

static KuclawPendingTitleBarAction pendingActionForWindow(NSWindow* nsWindow) {
    if (nsWindow == nil) {
        return KuclawPendingTitleBarActionNone;
    }

    NSNumber* pendingAction =
        (NSNumber*)objc_getAssociatedObject(nsWindow, kWindowPendingActionAssociationKey);
    return pendingAction != nil ? (KuclawPendingTitleBarAction)pendingAction.integerValue
                                : KuclawPendingTitleBarActionNone;
}

static void setPendingActionForWindow(NSWindow* nsWindow, KuclawPendingTitleBarAction action) {
    if (nsWindow == nil) {
        return;
    }

    if (action == KuclawPendingTitleBarActionNone) {
        objc_setAssociatedObject(
            nsWindow, kWindowPendingActionAssociationKey, nil, OBJC_ASSOCIATION_ASSIGN);
        return;
    }

    objc_setAssociatedObject(nsWindow,
                             kWindowPendingActionAssociationKey,
                             @(action),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

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

static WindowChromeMetrics currentWindowChromeMetrics(NSWindow* nsWindow) {
    WindowChromeMetrics metrics;
    if (nsWindow == nil) {
        return metrics;
    }

    NSButton* closeButton = [nsWindow standardWindowButton:NSWindowCloseButton];
    NSButton* zoomButton = [nsWindow standardWindowButton:NSWindowZoomButton];
    if (closeButton == nil || zoomButton == nil) {
        return metrics;
    }

    const NSRect closeFrame = closeButton.frame;
    const NSRect zoomFrame = zoomButton.frame;
    const CGFloat leftInset = NSMinX(closeFrame);
    const CGFloat rightEdge = NSMaxX(zoomFrame);
    const CGFloat titleBarHeight =
        qMax(0.0, NSHeight(nsWindow.frame) - NSHeight(nsWindow.contentLayoutRect));

    metrics.usesNativeTrafficLights = true;
    metrics.trafficLightsSafeWidth = qCeil(rightEdge + leftInset);
    metrics.titleBarHeight = qCeil(titleBarHeight);
    return metrics;
}

static TrafficLightsGeometry currentTrafficLightsGeometry(NSWindow* nsWindow) {
    TrafficLightsGeometry geometry;
    if (nsWindow == nil) {
        return geometry;
    }

    NSButton* closeButton = [nsWindow standardWindowButton:NSWindowCloseButton];
    NSButton* minimizeButton = [nsWindow standardWindowButton:NSWindowMiniaturizeButton];
    NSButton* zoomButton = [nsWindow standardWindowButton:NSWindowZoomButton];
    if (closeButton == nil || minimizeButton == nil || zoomButton == nil) {
        return geometry;
    }

    const NSRect closeFrame = [closeButton convertRect:closeButton.bounds toView:nil];
    const NSRect minimizeFrame = [minimizeButton convertRect:minimizeButton.bounds toView:nil];
    const NSRect zoomFrame = [zoomButton convertRect:zoomButton.bounds toView:nil];
    const NSRect clusterFrame = NSUnionRect(NSUnionRect(closeFrame, minimizeFrame), zoomFrame);
    const CGFloat windowHeight = NSHeight(nsWindow.frame);

    geometry.valid = true;
    geometry.closeButtonTopInset = qRound(windowHeight - NSMaxY(closeFrame));
    geometry.closeButtonMidY = qRound(NSMidY(closeFrame));
    geometry.closeButtonMidYFromTop = qRound(windowHeight - NSMidY(closeFrame));
    geometry.clusterTopInset = qRound(windowHeight - NSMaxY(clusterFrame));
    geometry.clusterMidY = qRound(NSMidY(clusterFrame));
    geometry.clusterMidYFromTop = qRound(windowHeight - NSMidY(clusterFrame));
    geometry.closeMinSpacing = qRound(NSMinX(minimizeFrame) - NSMaxX(closeFrame));
    geometry.minZoomSpacing = qRound(NSMinX(zoomFrame) - NSMaxX(minimizeFrame));
    geometry.clusterWidth = qRound(NSWidth(clusterFrame));
    return geometry;
}

static bool windowIsFullScreen(NSWindow* nsWindow) {
    if (nsWindow == nil) {
        return false;
    }

    return (nsWindow.styleMask & NSWindowStyleMaskFullScreen) == NSWindowStyleMaskFullScreen;
}

static CGFloat normalizedTrafficLightsSafeWidth(const WindowChromeMetrics& metrics) {
    return qMin<CGFloat>(kTitleBarControlSafeWidthMax,
                         qMax<CGFloat>(kTitleBarControlSafeWidthMin,
                                       qMax<CGFloat>(0.0, metrics.trafficLightsSafeWidth)));
}

static CGFloat dragRegionStartXForMetrics(const WindowChromeMetrics& metrics) {
    const CGFloat safeWidth = normalizedTrafficLightsSafeWidth(metrics);
    return safeWidth + kSidebarToggleLeadingGap + kTitleBarControlsClusterWidth
           + kTitleBarDragRegionLeadingGap;
}

static CGFloat dragRegionStartXForFrames(const WindowChromeMetrics& metrics,
                                         const NSRect& toggleFrame,
                                         const NSRect& backFrame,
                                         const NSRect& forwardFrame) {
    const bool hasCustomFrames =
        !NSIsEmptyRect(toggleFrame) || !NSIsEmptyRect(backFrame) || !NSIsEmptyRect(forwardFrame);
    if (!hasCustomFrames) {
        return dragRegionStartXForMetrics(metrics);
    }

    CGFloat maxRight = 0.0;
    if (!NSIsEmptyRect(toggleFrame)) {
        maxRight = qMax(maxRight, NSMaxX(toggleFrame));
    }
    if (!NSIsEmptyRect(backFrame)) {
        maxRight = qMax(maxRight, NSMaxX(backFrame));
    }
    if (!NSIsEmptyRect(forwardFrame)) {
        maxRight = qMax(maxRight, NSMaxX(forwardFrame));
    }

    return maxRight + kTitleBarDragRegionLeadingGap;
}

static CGFloat titleBarControlsTopMarginForMetrics(const WindowChromeMetrics& metrics) {
    return qMax<CGFloat>(0.0,
                         qRound((qMax<CGFloat>(0.0, metrics.titleBarHeight) - kTitleBarControlsHeight) / 2.0));
}

static NSRect titleBarControlFrameForWindow(NSWindow* nsWindow,
                                            const WindowChromeMetrics& metrics,
                                            CGFloat x,
                                            CGFloat width) {
    if (nsWindow == nil) {
        return NSZeroRect;
    }

    const CGFloat windowHeight = NSHeight(nsWindow.frame);
    const CGFloat y = qMax<CGFloat>(
        0.0, windowHeight - qMax<CGFloat>(0.0, metrics.titleBarHeight) + titleBarControlsTopMarginForMetrics(metrics));
    return NSMakeRect(x, y, width, kTitleBarControlsHeight);
}

static NSRect sidebarToggleFrameForWindow(NSWindow* nsWindow, const WindowChromeMetrics& metrics) {
    return titleBarControlFrameForWindow(nsWindow,
                                         metrics,
                                         normalizedTrafficLightsSafeWidth(metrics) + kSidebarToggleLeadingGap,
                                         kSidebarToggleWidth);
}

static NSRect backButtonFrameForWindow(NSWindow* nsWindow, const WindowChromeMetrics& metrics) {
    return titleBarControlFrameForWindow(nsWindow,
                                         metrics,
                                         normalizedTrafficLightsSafeWidth(metrics) + kSidebarToggleLeadingGap
                                             + kBackButtonX,
                                         kBackButtonWidth);
}

static NSRect forwardButtonFrameForWindow(NSWindow* nsWindow, const WindowChromeMetrics& metrics) {
    return titleBarControlFrameForWindow(nsWindow,
                                         metrics,
                                         normalizedTrafficLightsSafeWidth(metrics) + kSidebarToggleLeadingGap
                                             + kForwardButtonX,
                                         kForwardButtonWidth);
}

static NSRect controlRectFromSceneRect(NSWindow* nsWindow, const QRectF& sceneRect) {
    if (nsWindow == nil || sceneRect.isEmpty()) {
        return NSZeroRect;
    }

    const CGFloat windowHeight = NSHeight(nsWindow.frame);
    return NSMakeRect(sceneRect.x(),
                      windowHeight - sceneRect.y() - sceneRect.height(),
                      sceneRect.width(),
                      sceneRect.height());
}

static bool windowPointHitsButton(NSButton* button, NSPoint windowPoint) {
    if (button == nil || button.superview == nil || button.hidden) {
        return false;
    }

    const NSPoint pointInButtonSuperview = [button.superview convertPoint:windowPoint fromView:nil];
    return NSPointInRect(pointInButtonSuperview, button.frame);
}

static const char* trafficLightNameForPoint(NSWindow* nsWindow, NSPoint windowPoint) {
    if (nsWindow == nil) {
        return "";
    }

    NSButton* closeButton = [nsWindow standardWindowButton:NSWindowCloseButton];
    if (windowPointHitsButton(closeButton, windowPoint)) {
        return "close";
    }

    NSButton* minimizeButton = [nsWindow standardWindowButton:NSWindowMiniaturizeButton];
    if (windowPointHitsButton(minimizeButton, windowPoint)) {
        return "minimize";
    }

    NSButton* zoomButton = [nsWindow standardWindowButton:NSWindowZoomButton];
    if (windowPointHitsButton(zoomButton, windowPoint)) {
        return "zoom";
    }

    return "";
}

static NSRect dragRegionFrameForView(NSView* nativeView,
                                     CGFloat titleBarHeight,
                                     const WindowChromeMetrics& metrics,
                                     CGFloat startX) {
    const CGFloat hostHeight = NSHeight(nativeView.bounds);
    const CGFloat safeHeight = qMin(hostHeight, qMax(titleBarHeight, kTitleBarDragRegionMinHeight));
    const CGFloat clampedStartX = qMin<CGFloat>(NSWidth(nativeView.bounds), startX);
    const CGFloat clampedWidth = qMax<CGFloat>(0.0, NSWidth(nativeView.bounds) - clampedStartX);
    const CGFloat topAlignedY = qMax<CGFloat>(0.0, hostHeight - safeHeight);
    return NSMakeRect(clampedStartX, topAlignedY, clampedWidth, safeHeight);
}

static NSRect dragRegionRectForWindow(NSWindow* nsWindow,
                                      CGFloat titleBarHeight,
                                      const WindowChromeMetrics& metrics,
                                      CGFloat startX) {
    if (nsWindow == nil) {
        return NSZeroRect;
    }

    const CGFloat windowWidth = NSWidth(nsWindow.frame);
    const CGFloat windowHeight = NSHeight(nsWindow.frame);
    const CGFloat safeHeight = qMin(windowHeight, qMax(titleBarHeight, kTitleBarDragRegionMinHeight));
    const CGFloat clampedStartX = qMin<CGFloat>(windowWidth, startX);
    const CGFloat clampedWidth = qMax<CGFloat>(0.0, windowWidth - clampedStartX);
    const CGFloat topAlignedY = qMax<CGFloat>(0.0, windowHeight - safeHeight);
    return NSMakeRect(clampedStartX, topAlignedY, clampedWidth, safeHeight);
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

static NSToolbar* toolbarForWindow(NSWindow* nsWindow) {
    if (nsWindow == nil) {
        return nil;
    }

    return (NSToolbar*)objc_getAssociatedObject(nsWindow, kWindowToolbarAssociationKey);
}

static void installOrUpdateToolbarChrome(NSWindow* nsWindow) {
    if (nsWindow == nil) {
        return;
    }

    NSToolbar* toolbar = toolbarForWindow(nsWindow);
    if (toolbar == nil) {
        toolbar = [[NSToolbar alloc] initWithIdentifier:@"com.mullaney1013.kuclaw.windowChromeToolbar"];
        toolbar.allowsUserCustomization = NO;
        toolbar.autosavesConfiguration = NO;
        toolbar.displayMode = NSToolbarDisplayModeIconOnly;

        KuclawChromeToolbarDelegate* delegate = [[KuclawChromeToolbarDelegate alloc] init];
        toolbar.delegate = delegate;

        objc_setAssociatedObject(nsWindow,
                                 kWindowToolbarDelegateAssociationKey,
                                 delegate,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(nsWindow,
                                 kWindowToolbarAssociationKey,
                                 toolbar,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    if (nsWindow.toolbar != toolbar) {
        nsWindow.toolbar = toolbar;
    }

    if (@available(macOS 11.0, *)) {
        nsWindow.toolbarStyle = NSWindowToolbarStyleUnified;
    }
}

static void installOrUpdateDragMonitor(NSWindow* nsWindow,
                                       CGFloat titleBarHeight,
                                       const WindowChromeMetrics& metrics,
                                       std::function<QRectF()> sidebarToggleRectProvider,
                                       std::function<QRectF()> backRectProvider,
                                       std::function<QRectF()> forwardRectProvider,
                                       std::function<void()> sidebarToggleHandler,
                                       std::function<void()> backHandler,
                                       std::function<void()> forwardHandler) {
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
        [NSEvent addLocalMonitorForEventsMatchingMask:(NSEventMaskLeftMouseDown
                                                       | NSEventMaskLeftMouseUp)
                                              handler:^NSEvent* _Nullable(NSEvent* _Nonnull event) {
                                                  NSWindow* strongWindow = weakWindow;
                                                  if (strongWindow == nil || event == nil) {
                                                      return event;
                                                  }

                                                  if (event.window != strongWindow) {
                                                      return event;
                                                  }

                                                  const QRectF toggleSceneRect = sidebarToggleRectProvider
                                                                                     ? sidebarToggleRectProvider()
                                                                                     : QRectF();
                                                  const QRectF backSceneRect =
                                                      backRectProvider ? backRectProvider() : QRectF();
                                                  const QRectF forwardSceneRect =
                                                      forwardRectProvider ? forwardRectProvider() : QRectF();
                                                  const NSRect toggleFrame =
                                                      toggleSceneRect.isEmpty()
                                                          ? sidebarToggleFrameForWindow(strongWindow, metrics)
                                                          : controlRectFromSceneRect(strongWindow, toggleSceneRect);
                                                  const NSRect backFrame =
                                                      backSceneRect.isEmpty()
                                                          ? backButtonFrameForWindow(strongWindow, metrics)
                                                          : controlRectFromSceneRect(strongWindow, backSceneRect);
                                                  const NSRect forwardFrame =
                                                      forwardSceneRect.isEmpty()
                                                          ? forwardButtonFrameForWindow(strongWindow, metrics)
                                                          : controlRectFromSceneRect(strongWindow, forwardSceneRect);
                                                  const CGFloat dragRegionStartX =
                                                      dragRegionStartXForFrames(metrics,
                                                                                toggleFrame,
                                                                                backFrame,
                                                                                forwardFrame);
                                                  const CGFloat currentTitleBarHeight =
                                                      qMax(0.0, NSHeight(strongWindow.frame)
                                                                     - NSHeight(strongWindow.contentLayoutRect));
                                                  const NSRect dragRect =
                                                      dragRegionRectForWindow(
                                                          strongWindow,
                                                          currentTitleBarHeight,
                                                          metrics,
                                                          dragRegionStartX);
                                                  NSButton* closeButton =
                                                      [strongWindow standardWindowButton:NSWindowCloseButton];
                                                  NSButton* minimizeButton =
                                                      [strongWindow standardWindowButton:NSWindowMiniaturizeButton];
                                                  NSButton* zoomButton =
                                                      [strongWindow standardWindowButton:NSWindowZoomButton];
                                                  if (windowPointHitsButton(closeButton, event.locationInWindow)
                                                      || windowPointHitsButton(minimizeButton, event.locationInWindow)
                                                      || windowPointHitsButton(zoomButton, event.locationInWindow)) {
                                                      setPendingActionForWindow(
                                                          strongWindow, KuclawPendingTitleBarActionNone);
                                                      return event;
                                                  }

                                                  if (event.type == NSEventTypeLeftMouseDown) {
                                                      if (sidebarToggleHandler
                                                          && NSPointInRect(event.locationInWindow, toggleFrame)) {
                                                          setPendingActionForWindow(
                                                              strongWindow,
                                                              KuclawPendingTitleBarActionSidebarToggle);
                                                          return nil;
                                                      }

                                                      if (backHandler
                                                          && NSPointInRect(event.locationInWindow, backFrame)) {
                                                          setPendingActionForWindow(
                                                              strongWindow,
                                                              KuclawPendingTitleBarActionBack);
                                                          return nil;
                                                      }

                                                      if (forwardHandler
                                                          && NSPointInRect(event.locationInWindow, forwardFrame)) {
                                                          setPendingActionForWindow(
                                                              strongWindow,
                                                              KuclawPendingTitleBarActionForward);
                                                          return nil;
                                                      }

                                                      setPendingActionForWindow(
                                                          strongWindow, KuclawPendingTitleBarActionNone);
                                                      if (!NSPointInRect(event.locationInWindow, dragRect)) {
                                                          return event;
                                                      }

                                                      [strongWindow performWindowDragWithEvent:event];
                                                      return nil;
                                                  }

                                                  const KuclawPendingTitleBarAction pendingAction =
                                                      pendingActionForWindow(strongWindow);
                                                  setPendingActionForWindow(
                                                      strongWindow, KuclawPendingTitleBarActionNone);
                                                  if (pendingAction == KuclawPendingTitleBarActionNone) {
                                                      return event;
                                                  }

                                                  if (pendingAction
                                                          == KuclawPendingTitleBarActionSidebarToggle
                                                      && sidebarToggleHandler
                                                      && NSPointInRect(event.locationInWindow, toggleFrame)) {
                                                      sidebarToggleHandler();
                                                      return nil;
                                                  }

                                                  if (pendingAction == KuclawPendingTitleBarActionBack
                                                      && backHandler
                                                      && NSPointInRect(event.locationInWindow, backFrame)) {
                                                      backHandler();
                                                      return nil;
                                                  }

                                                  if (pendingAction == KuclawPendingTitleBarActionForward
                                                      && forwardHandler
                                                      && NSPointInRect(event.locationInWindow, forwardFrame)) {
                                                      forwardHandler();
                                                  }
                                                  return nil;
                                              }];

    objc_setAssociatedObject(nsWindow,
                             kWindowDragMonitorAssociationKey,
                             monitor,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void installOrUpdateDragRegion(NSWindow* nsWindow,
                                      NSView* nativeView,
                                      CGFloat titleBarHeight,
                                      const WindowChromeMetrics& metrics,
                                      const QRectF& sidebarToggleRect,
                                      const QRectF& backRect,
                                      const QRectF& forwardRect) {
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

    const NSRect toggleFrame =
        sidebarToggleRect.isEmpty() ? sidebarToggleFrameForWindow(nsWindow, metrics)
                                    : controlRectFromSceneRect(nsWindow, sidebarToggleRect);
    const NSRect backFrame =
        backRect.isEmpty() ? backButtonFrameForWindow(nsWindow, metrics)
                           : controlRectFromSceneRect(nsWindow, backRect);
    const NSRect forwardFrame =
        forwardRect.isEmpty() ? forwardButtonFrameForWindow(nsWindow, metrics)
                              : controlRectFromSceneRect(nsWindow, forwardRect);
    const CGFloat dragRegionStartX =
        dragRegionStartXForFrames(metrics, toggleFrame, backFrame, forwardFrame);
    dragView.frame = dragRegionFrameForView(hostView, titleBarHeight, metrics, dragRegionStartX);
    dragView.hidden = NSIsEmptyRect(dragView.frame);
}
}  // namespace
#endif

void MacWindowChrome::setTitleBarControlRects(const QRectF& sidebarToggleRect,
                                              const QRectF& backRect,
                                              const QRectF& forwardRect) {
    sidebarToggleRect_ = sidebarToggleRect;
    backRect_ = backRect;
    forwardRect_ = forwardRect;
}

bool MacWindowChrome::toggleNativeFullscreen(QWindow* window) {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (window == nullptr || !runningOnCocoaPlatform()) {
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
    nsWindow.collectionBehavior |= NSWindowCollectionBehaviorFullScreenPrimary;
    [nsWindow toggleFullScreen:nil];
    return true;
#else
    Q_UNUSED(window);
    return false;
#endif
}

WindowChromeMetrics MacWindowChrome::attach(QWindow* window,
                                            std::function<void()> sidebarToggleHandler,
                                            std::function<void()> backHandler,
                                            std::function<void()> forwardHandler) {
    WindowChromeMetrics metrics;

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (window == nullptr || !runningOnCocoaPlatform()) {
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

    installOrUpdateToolbarChrome(nsWindow);
    nsWindow.movableByWindowBackground = NO;
    nsWindow.titleVisibility = NSWindowTitleHidden;
    nsWindow.titlebarAppearsTransparent = YES;
    nsWindow.styleMask |= NSWindowStyleMaskFullSizeContentView;
    nsWindow.collectionBehavior |= NSWindowCollectionBehaviorFullScreenPrimary;

    metrics = currentWindowChromeMetrics(nsWindow);
    if (!metrics.usesNativeTrafficLights) {
        return metrics;
    }

    installOrUpdateDragRegion(nsWindow,
                              nativeView,
                              metrics.titleBarHeight,
                              metrics,
                              sidebarToggleRect_,
                              backRect_,
                              forwardRect_);
    installOrUpdateDragMonitor(nsWindow,
                               metrics.titleBarHeight,
                               metrics,
                               [this]() { return sidebarToggleRect_; },
                               [this]() { return backRect_; },
                               [this]() { return forwardRect_; },
                               std::move(sidebarToggleHandler),
                               std::move(backHandler),
                               std::move(forwardHandler));
#else
    Q_UNUSED(window);
#   if !defined(Q_OS_MACOS) && !defined(Q_OS_MAC)
    Q_UNUSED(sidebarToggleHandler);
    Q_UNUSED(backHandler);
    Q_UNUSED(forwardHandler);
#   endif
#endif

    return metrics;
}

void MacWindowChrome::detach(QWindow* window) {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (window == nullptr || !runningOnCocoaPlatform()) {
        return;
    }

    const WId nativeId = window->winId();
    if (nativeId == 0) {
        return;
    }

    detach(nativeId);
#else
    Q_UNUSED(window);
#endif
}

void MacWindowChrome::detach(WId nativeId) {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (nativeId == 0 || !runningOnCocoaPlatform()) {
        return;
    }

    auto* nativeView = (__bridge NSView*)(reinterpret_cast<void*>(nativeId));
    if (nativeView == nil || nativeView.window == nil) {
        return;
    }

    NSWindow* nsWindow = nativeView.window;
    id existingMonitor = dragRegionMonitorForWindow(nsWindow);
    if (existingMonitor != nil) {
        [NSEvent removeMonitor:existingMonitor];
        objc_setAssociatedObject(nsWindow,
                                 kWindowDragMonitorAssociationKey,
                                 nil,
                                 OBJC_ASSOCIATION_ASSIGN);
    }

    KuclawWindowDragView* dragView = dragRegionViewForWindow(nsWindow);
    if (dragView != nil) {
        [dragView removeFromSuperview];
        objc_setAssociatedObject(nsWindow,
                                 kWindowDragViewAssociationKey,
                                 nil,
                                 OBJC_ASSOCIATION_ASSIGN);
    }

    NSToolbar* toolbar = toolbarForWindow(nsWindow);
    if (toolbar != nil && nsWindow.toolbar == toolbar) {
        nsWindow.toolbar = nil;
    }
    objc_setAssociatedObject(nsWindow,
                             kWindowToolbarAssociationKey,
                             nil,
                             OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(nsWindow,
                             kWindowToolbarDelegateAssociationKey,
                             nil,
                             OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(nsWindow,
                             kWindowPendingActionAssociationKey,
                             nil,
                             OBJC_ASSOCIATION_ASSIGN);
#else
    Q_UNUSED(nativeId);
#endif
}

TrafficLightsGeometry MacWindowChrome::trafficLightsGeometry(QWindow* window) const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (window == nullptr || !runningOnCocoaPlatform()) {
        return {};
    }

    const WId nativeId = window->winId();
    if (nativeId == 0) {
        return {};
    }

    auto* nativeView = (__bridge NSView*)(reinterpret_cast<void*>(nativeId));
    if (nativeView == nil || nativeView.window == nil) {
        return {};
    }

    return currentTrafficLightsGeometry(nativeView.window);
#else
    Q_UNUSED(window);
    return {};
#endif
}

int MacWindowChrome::titleBarDragRegionStartXForMetrics(const WindowChromeMetrics& metrics) const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    return qCeil(dragRegionStartXForMetrics(metrics));
#else
    Q_UNUSED(metrics);
    return 0;
#endif
}

int MacWindowChrome::titleBarDragRegionStartXForLayout(const WindowChromeMetrics& metrics,
                                                       const QRectF& sidebarToggleRect,
                                                       const QRectF& backRect,
                                                       const QRectF& forwardRect) const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    const NSRect toggleFrame = sidebarToggleRect.isEmpty()
                                   ? NSZeroRect
                                   : NSMakeRect(sidebarToggleRect.x(),
                                                sidebarToggleRect.y(),
                                                sidebarToggleRect.width(),
                                                sidebarToggleRect.height());
    const NSRect backFrame = backRect.isEmpty()
                                 ? NSZeroRect
                                 : NSMakeRect(backRect.x(),
                                              backRect.y(),
                                              backRect.width(),
                                              backRect.height());
    const NSRect forwardFrame = forwardRect.isEmpty()
                                    ? NSZeroRect
                                    : NSMakeRect(forwardRect.x(),
                                                 forwardRect.y(),
                                                 forwardRect.width(),
                                                 forwardRect.height());
    return qCeil(dragRegionStartXForFrames(metrics, toggleFrame, backFrame, forwardFrame));
#else
    Q_UNUSED(metrics);
    Q_UNUSED(sidebarToggleRect);
    Q_UNUSED(backRect);
    Q_UNUSED(forwardRect);
    return 0;
#endif
}

bool MacWindowChrome::beginSystemDrag(QWindow* window) {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (window == nullptr || !runningOnCocoaPlatform()) {
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

int MacWindowChrome::currentTitleBarDragRegionStartX(QWindow* window) const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (window == nullptr || !runningOnCocoaPlatform()) {
        return 0;
    }

    const WId nativeId = window->winId();
    if (nativeId == 0) {
        return 0;
    }

    auto* nativeView = (__bridge NSView*)(reinterpret_cast<void*>(nativeId));
    if (nativeView == nil || nativeView.window == nil) {
        return 0;
    }

    KuclawWindowDragView* dragView = dragRegionViewForWindow(nativeView.window);
    return dragView != nil ? qRound(NSMinX(dragView.frame)) : 0;
#else
    Q_UNUSED(window);
    return 0;
#endif
}

bool MacWindowChrome::hasTitleBarDragRegion(QWindow* window) const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (window == nullptr || !runningOnCocoaPlatform()) {
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

bool MacWindowChrome::hasTitleBarDragRegion(WId nativeId) const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (nativeId == 0 || !runningOnCocoaPlatform()) {
        return false;
    }

    NSWindow* nsWindow = nativeWindowForId(nativeId);
    if (nsWindow == nil) {
        return false;
    }

    KuclawWindowDragView* dragView = dragRegionViewForWindow(nsWindow);
    return dragView != nil && !dragView.hidden && !NSIsEmptyRect(dragView.frame);
#else
    Q_UNUSED(nativeId);
    return false;
#endif
}

bool MacWindowChrome::supportsNativeFullscreen(QWindow* window) const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (window == nullptr || !runningOnCocoaPlatform()) {
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
    return (nsWindow.collectionBehavior & NSWindowCollectionBehaviorFullScreenPrimary)
           == NSWindowCollectionBehaviorFullScreenPrimary;
#else
    Q_UNUSED(window);
    return false;
#endif
}


bool MacWindowChrome::titleBarDragRegionCapturesHitTest(QWindow* window) const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (window == nullptr || !runningOnCocoaPlatform()) {
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
    const WindowChromeMetrics metrics = currentWindowChromeMetrics(nsWindow);
    const NSRect dragRect =
        dragRegionRectForWindow(nsWindow,
                                titleBarHeight,
                                metrics,
                                dragRegionStartXForMetrics(metrics));
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
    if (window == nullptr || !runningOnCocoaPlatform()) {
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
    const WindowChromeMetrics metrics = currentWindowChromeMetrics(nsWindow);
    const NSRect dragRect =
        dragRegionRectForWindow(nsWindow,
                                titleBarHeight,
                                metrics,
                                dragRegionStartXForMetrics(metrics));
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
    if (window == nullptr || !runningOnCocoaPlatform()) {
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

bool MacWindowChrome::hasTitleBarDragMonitor(WId nativeId) const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (nativeId == 0 || !runningOnCocoaPlatform()) {
        return false;
    }

    NSWindow* nsWindow = nativeWindowForId(nativeId);
    if (nsWindow == nil) {
        return false;
    }

    return dragRegionMonitorForWindow(nsWindow) != nil;
#else
    Q_UNUSED(nativeId);
    return false;
#endif
}

bool MacWindowChrome::hasToolbarChrome(WId nativeId) const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (nativeId == 0 || !runningOnCocoaPlatform()) {
        return false;
    }

    NSWindow* nsWindow = nativeWindowForId(nativeId);
    if (nsWindow == nil) {
        return false;
    }

    NSToolbar* toolbar = toolbarForWindow(nsWindow);
    return toolbar != nil && nsWindow.toolbar == toolbar;
#else
    Q_UNUSED(nativeId);
    return false;
#endif
}

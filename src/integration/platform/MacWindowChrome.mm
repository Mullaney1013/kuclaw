#include "integration/platform/MacWindowChrome.h"

#include <QGuiApplication>
#include <QtMath>
#include <QDebug>

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
#import <AppKit/AppKit.h>
#import <objc/runtime.h>

@interface KuclawWindowDragView : NSView
@end

@interface KuclawHoverButton : NSButton
@end

@interface KuclawHoverSegmentedControl : NSSegmentedControl
@end

static const CGFloat kLeadingToolbarClusterWindowedGap = 10.0;
static const CGFloat kLeadingToolbarClusterFullscreenGap = 0.0;
static NSToolbarItemIdentifier const kLeadingClusterToolbarItemIdentifier =
    @"com.mullaney1013.kuclaw.leadingCluster";

typedef NS_ENUM(NSInteger, KuclawLeadingClusterHostMode) {
    KuclawLeadingClusterHostModeNone = 0,
    KuclawLeadingClusterHostModeToolbarItem,
    KuclawLeadingClusterHostModeDirectTitlebarHost,
    KuclawLeadingClusterHostModeTitlebarAccessory,
};

static NSView* leadingClusterHostViewForWindow(NSWindow* nsWindow) {
    if (nsWindow == nil) {
        return nil;
    }

    const bool fullScreen =
        (nsWindow.styleMask & NSWindowStyleMaskFullScreen) == NSWindowStyleMaskFullScreen;
    if (fullScreen && nsWindow.contentView != nil) {
        return nsWindow.contentView;
    }

    NSView* titleBarHost = nil;
    NSButton* closeButton = [nsWindow standardWindowButton:NSWindowCloseButton];
    NSView* titleBarView = closeButton.superview;
    if (titleBarView != nil && titleBarView.superview != nil) {
        titleBarHost = titleBarView.superview;
    } else {
        titleBarHost = titleBarView;
    }

    if (titleBarHost != nil) {
        return titleBarHost;
    }

    return nsWindow.contentView;
}

static NSRect trafficLightsClusterFrameInView(NSWindow* nsWindow, NSView* targetView) {
    if (nsWindow == nil || targetView == nil) {
        return NSZeroRect;
    }

    NSButton* closeButton = [nsWindow standardWindowButton:NSWindowCloseButton];
    NSButton* minimizeButton = [nsWindow standardWindowButton:NSWindowMiniaturizeButton];
    NSButton* zoomButton = [nsWindow standardWindowButton:NSWindowZoomButton];
    if (closeButton == nil || minimizeButton == nil || zoomButton == nil) {
        return NSZeroRect;
    }

    const NSRect closeFrame = [closeButton convertRect:closeButton.bounds toView:targetView];
    const NSRect minimizeFrame = [minimizeButton convertRect:minimizeButton.bounds toView:targetView];
    const NSRect zoomFrame = [zoomButton convertRect:zoomButton.bounds toView:targetView];
    return NSUnionRect(NSUnionRect(closeFrame, minimizeFrame), zoomFrame);
}

@interface KuclawChromeToolbarController : NSObject <NSToolbarDelegate>
@property(nonatomic, weak) NSWindow* window;
@property(nonatomic, strong) NSToolbar* toolbar;
@property(nonatomic, strong) NSToolbarItem* leadingClusterItem;
@property(nonatomic, strong) NSTitlebarAccessoryViewController* leadingAccessoryController;
@property(nonatomic, strong) NSStackView* leadingClusterView;
@property(nonatomic, strong) NSButton* sidebarButton;
@property(nonatomic, strong) NSSegmentedControl* navigationControl;
@property(nonatomic, assign) KuclawLeadingClusterHostMode hostMode;
@property(nonatomic, copy) dispatch_block_t sidebarHandler;
@property(nonatomic, copy) dispatch_block_t backHandler;
@property(nonatomic, copy) dispatch_block_t forwardHandler;
- (instancetype)initWithWindow:(NSWindow*)window;
- (void)updateHandlersWithSidebar:(dispatch_block_t)sidebar
                             back:(dispatch_block_t)back
                          forward:(dispatch_block_t)forward;
- (void)updateNavigationEnabledBack:(BOOL)backEnabled
                            forward:(BOOL)forwardEnabled;
- (NativeNavigationState)navigationEnabledState;
- (NSRect)leadingClusterFrameInWindowCoordinates;
- (BOOL)leadingClusterUsesDirectTitlebarHost;
- (BOOL)leadingClusterUsesToolbarItem;
- (BOOL)leadingClusterUsesTitlebarAccessory;
- (void)installForCurrentWindowState;
- (void)detachFromWindow;
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

@implementation KuclawHoverButton

- (void)resetCursorRects {
    [super resetCursorRects];
    [self addCursorRect:self.bounds cursor:[NSCursor pointingHandCursor]];
}

@end

@implementation KuclawHoverSegmentedControl

- (void)resetCursorRects {
    [super resetCursorRects];
    [self addCursorRect:self.bounds cursor:[NSCursor pointingHandCursor]];
}

@end

@implementation KuclawChromeToolbarController

- (NSButton*)makeSidebarButton {
    KuclawHoverButton* button =
        [[KuclawHoverButton alloc] initWithFrame:NSMakeRect(0.0, 0.0, 30.0, 22.0)];
    button.target = self;
    button.action = @selector(handleSidebar:);
    button.bordered = YES;
    button.buttonType = NSButtonTypeMomentaryChange;
    button.bezelStyle = NSBezelStyleTexturedRounded;
    button.imagePosition = NSImageOnly;
    button.imageScaling = NSImageScaleProportionallyDown;
    button.contentTintColor =
        [NSColor colorWithCalibratedRed:0.36 green:0.42 blue:0.50 alpha:1.0];
    button.showsBorderOnlyWhileMouseInside = YES;
    button.toolTip = @"Toggle Sidebar";
    button.frame = NSMakeRect(0.0, 0.0, 30.0, 22.0);
    return button;
}

- (NSSegmentedControl*)makeNavigationControl {
    KuclawHoverSegmentedControl* control =
        [[KuclawHoverSegmentedControl alloc] initWithFrame:NSMakeRect(0.0, 0.0, 52.0, 22.0)];
    control.segmentCount = 2;
    control.trackingMode = NSSegmentSwitchTrackingMomentary;
    control.target = self;
    control.action = @selector(handleNavigation:);
    control.segmentStyle = NSSegmentStyleSeparated;
    control.frame = NSMakeRect(0.0, 0.0, 52.0, 22.0);
    return control;
}

- (NSStackView*)makeLeadingClusterViewWithSidebarButton:(NSButton*)sidebarButton
                                      navigationControl:(NSSegmentedControl*)navigationControl {
    NSStackView* stackView = [NSStackView stackViewWithViews:@[ sidebarButton, navigationControl ]];
    stackView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    stackView.alignment = NSLayoutAttributeCenterY;
    stackView.spacing = 10.0;
    stackView.edgeInsets = NSEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    const NSSize fittingSize = stackView.fittingSize;
    stackView.frame = NSMakeRect(0.0, 0.0, fittingSize.width, fittingSize.height);
    return stackView;
}

- (NSToolbarItem*)makeLeadingClusterItem {
    NSToolbarItem* item =
        [[NSToolbarItem alloc] initWithItemIdentifier:kLeadingClusterToolbarItemIdentifier];
    item.label = @"Leading Controls";
    item.paletteLabel = @"Leading Controls";
    item.view = self.leadingClusterView;
    item.minSize = self.leadingClusterView.fittingSize;
    item.maxSize = self.leadingClusterView.fittingSize;
    return item;
}

- (NSTitlebarAccessoryViewController*)makeLeadingAccessoryController {
    NSTitlebarAccessoryViewController* accessory = [[NSTitlebarAccessoryViewController alloc] init];
    accessory.layoutAttribute = NSLayoutAttributeLeft;
    accessory.view = self.leadingClusterView;
    accessory.view.frame = NSMakeRect(0.0,
                                      0.0,
                                      self.leadingClusterView.fittingSize.width,
                                      self.leadingClusterView.fittingSize.height);
    return accessory;
}

- (instancetype)initWithWindow:(NSWindow*)window {
    self = [super init];
    if (self != nil) {
        self.window = window;

        self.toolbar =
            [[NSToolbar alloc] initWithIdentifier:@"com.mullaney1013.kuclaw.windowChromeToolbar"];
        self.toolbar.allowsUserCustomization = NO;
        self.toolbar.autosavesConfiguration = NO;
        self.toolbar.displayMode = NSToolbarDisplayModeIconOnly;
        self.toolbar.delegate = self;

        self.sidebarButton = [self makeSidebarButton];
        self.navigationControl = [self makeNavigationControl];
        self.leadingClusterView =
            [self makeLeadingClusterViewWithSidebarButton:self.sidebarButton
                                        navigationControl:self.navigationControl];
        self.leadingClusterView.hidden = NO;
        self.leadingClusterItem = [self makeLeadingClusterItem];
        self.leadingAccessoryController = [self makeLeadingAccessoryController];
        self.hostMode = KuclawLeadingClusterHostModeNone;
    }

    return self;
}

- (NSArray<NSToolbarItemIdentifier>*)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    Q_UNUSED(toolbar);
    return @[ kLeadingClusterToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier ];
}

- (NSArray<NSToolbarItemIdentifier>*)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    Q_UNUSED(toolbar);
    return @[ kLeadingClusterToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier ];
}

- (NSArray<NSToolbarItemIdentifier>*)toolbarSelectableItemIdentifiers:(NSToolbar*)toolbar {
    Q_UNUSED(toolbar);
    return @[];
}

- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar
    itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier
willBeInsertedIntoToolbar:(BOOL)flag {
    Q_UNUSED(toolbar);
    Q_UNUSED(flag);
    if ([itemIdentifier isEqualToString:kLeadingClusterToolbarItemIdentifier]) {
        self.leadingClusterItem.view = self.leadingClusterView;
        self.leadingClusterItem.minSize = self.leadingClusterView.fittingSize;
        self.leadingClusterItem.maxSize = self.leadingClusterView.fittingSize;
        return self.leadingClusterItem;
    }

    return nil;
}

- (void)updateHandlersWithSidebar:(dispatch_block_t)sidebar
                             back:(dispatch_block_t)back
                          forward:(dispatch_block_t)forward {
    self.sidebarHandler = sidebar;
    self.backHandler = back;
    self.forwardHandler = forward;
}

- (void)updateNavigationEnabledBack:(BOOL)backEnabled
                            forward:(BOOL)forwardEnabled {
    [self.navigationControl setEnabled:backEnabled forSegment:0];
    [self.navigationControl setEnabled:forwardEnabled forSegment:1];
}

- (NativeNavigationState)navigationEnabledState {
    NativeNavigationState state;
    state.valid = true;
    NSSegmentedControl* control = self.navigationControl;
    state.backEnabled = [control isEnabledForSegment:0];
    state.forwardEnabled = [control isEnabledForSegment:1];
    return state;
}

- (NSRect)leadingClusterFrameInWindowCoordinates {
    if (self.leadingClusterView == nil || self.leadingClusterView.superview == nil) {
        return NSZeroRect;
    }

    [self.leadingClusterView.superview layoutSubtreeIfNeeded];
    return [self.leadingClusterView convertRect:self.leadingClusterView.bounds toView:nil];
}

- (BOOL)leadingClusterUsesDirectTitlebarHost {
    return self.hostMode == KuclawLeadingClusterHostModeDirectTitlebarHost;
}

- (BOOL)leadingClusterUsesToolbarItem {
    return self.hostMode == KuclawLeadingClusterHostModeToolbarItem;
}

- (BOOL)leadingClusterUsesTitlebarAccessory {
    return self.hostMode == KuclawLeadingClusterHostModeTitlebarAccessory;
}

- (void)removeAccessoryIfNeeded {
    if (self.window == nil || self.leadingAccessoryController == nil) {
        return;
    }

    const NSUInteger accessoryIndex =
        [self.window.titlebarAccessoryViewControllers indexOfObjectIdenticalTo:self.leadingAccessoryController];
    if (accessoryIndex != NSNotFound) {
        [self.window removeTitlebarAccessoryViewControllerAtIndex:accessoryIndex];
    }
}

- (void)installAsToolbarItem {
    [self removeAccessoryIfNeeded];

    self.leadingAccessoryController.view = nil;
    [self.leadingClusterView removeFromSuperview];
    self.leadingClusterItem.view = self.leadingClusterView;
    self.leadingClusterItem.minSize = self.leadingClusterView.fittingSize;
    self.leadingClusterItem.maxSize = self.leadingClusterView.fittingSize;

    if (self.window.toolbar != self.toolbar) {
        self.window.toolbar = self.toolbar;
    }

    [self.toolbar validateVisibleItems];
    self.hostMode = KuclawLeadingClusterHostModeToolbarItem;
}

- (void)installAsDirectTitlebarHost {
    [self removeAccessoryIfNeeded];

    if (self.window.toolbar == self.toolbar) {
        self.window.toolbar = nil;
    }

    self.leadingAccessoryController.view = nil;
    self.leadingClusterItem.view = nil;

    NSView* hostView = leadingClusterHostViewForWindow(self.window);
    if (hostView == nil) {
        self.hostMode = KuclawLeadingClusterHostModeNone;
        return;
    }

    if (self.leadingClusterView.superview != hostView) {
        [self.leadingClusterView removeFromSuperview];
        [hostView addSubview:self.leadingClusterView];
    }

    [hostView layoutSubtreeIfNeeded];

    const NSRect trafficLightsFrame = trafficLightsClusterFrameInView(self.window, hostView);
    const NSSize fittingSize = self.leadingClusterView.fittingSize;
    const CGFloat clusterX =
        NSIsEmptyRect(trafficLightsFrame) ? 78.0 : NSMaxX(trafficLightsFrame) + kLeadingToolbarClusterFullscreenGap;
    const CGFloat clusterY =
        NSIsEmptyRect(trafficLightsFrame)
            ? qMax<CGFloat>(0.0, NSHeight(hostView.bounds) - fittingSize.height - 8.0)
            : NSMidY(trafficLightsFrame) - (fittingSize.height / 2.0);
    self.leadingClusterView.frame = NSMakeRect(clusterX,
                                               qMax<CGFloat>(0.0, clusterY),
                                               fittingSize.width,
                                               fittingSize.height);
    self.leadingClusterView.autoresizingMask = NSViewMaxXMargin | NSViewMinYMargin;
    self.hostMode = KuclawLeadingClusterHostModeDirectTitlebarHost;
}

- (void)installAsTitlebarAccessory {
    if (self.window.toolbar == self.toolbar) {
        self.window.toolbar = nil;
    }

    self.leadingClusterItem.view = nil;

    if (self.leadingAccessoryController.view != self.leadingClusterView) {
        self.leadingAccessoryController.view = self.leadingClusterView;
    }

    if ([self.window.titlebarAccessoryViewControllers
            indexOfObjectIdenticalTo:self.leadingAccessoryController] == NSNotFound) {
        [self.window addTitlebarAccessoryViewController:self.leadingAccessoryController];
    }

    self.hostMode = KuclawLeadingClusterHostModeTitlebarAccessory;
}

- (void)installForCurrentWindowState {
    if (self.window == nil) {
        return;
    }

    const bool fullScreen =
        (self.window.styleMask & NSWindowStyleMaskFullScreen) == NSWindowStyleMaskFullScreen;
    if (fullScreen) {
        [self installAsDirectTitlebarHost];
        return;
    }

    [self installAsToolbarItem];
}

- (void)detachFromWindow {
    if (self.window == nil) {
        return;
    }

    [self removeAccessoryIfNeeded];

    if (self.window.toolbar == self.toolbar) {
        self.window.toolbar = nil;
    }

    self.leadingAccessoryController.view = nil;
    self.leadingClusterItem.view = nil;
    [self.leadingClusterView removeFromSuperview];
    self.hostMode = KuclawLeadingClusterHostModeNone;
}

- (void)handleSidebar:(id)sender {
    Q_UNUSED(sender);
    if (self.sidebarHandler) {
        self.sidebarHandler();
    }
}

- (void)handleNavigation:(id)sender {
    NSSegmentedControl* control = [sender isKindOfClass:[NSSegmentedControl class]]
                                      ? (NSSegmentedControl*)sender
                                      : nil;
    const NSInteger selectedSegment = control != nil ? control.selectedSegment : -1;
    if (selectedSegment == 0) {
        if (self.backHandler) {
            self.backHandler();
        }
        return;
    }

    if (selectedSegment == 1 && self.forwardHandler) {
        self.forwardHandler();
    }
}

@end
#endif

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
namespace {
constexpr CGFloat kTitleBarDragRegionMinHeight = 56.0;
constexpr CGFloat kTitleBarControlSafeWidthMin = 78.0;
constexpr CGFloat kTitleBarControlSafeWidthMax = 96.0;
constexpr CGFloat kLeadingToolbarClusterFallbackWidth = 82.0;
constexpr CGFloat kTitleBarDragRegionLeadingGap = 20.0;
const void* kWindowDragViewAssociationKey = &kWindowDragViewAssociationKey;
const void* kWindowDragMonitorAssociationKey = &kWindowDragMonitorAssociationKey;
const void* kWindowToolbarAssociationKey = &kWindowToolbarAssociationKey;
const void* kWindowToolbarControllerAssociationKey = &kWindowToolbarControllerAssociationKey;

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
    if (nsWindow != nil && nsWindow.contentView != nil) {
        return nsWindow.contentView;
    }

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

static KuclawChromeToolbarController* toolbarControllerForWindow(NSWindow* nsWindow) {
    if (nsWindow == nil) {
        return nil;
    }

    return (KuclawChromeToolbarController*)objc_getAssociatedObject(
        nsWindow, kWindowToolbarControllerAssociationKey);
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
    return safeWidth + kLeadingToolbarClusterFallbackWidth + kTitleBarDragRegionLeadingGap;
}

static NSRect installedLeadingToolbarClusterFrameForWindow(NSWindow* nsWindow) {
    KuclawChromeToolbarController* controller = toolbarControllerForWindow(nsWindow);
    if (controller != nil) {
        if (![controller leadingClusterUsesToolbarItem]
            && ![controller leadingClusterUsesTitlebarAccessory]) {
            return NSZeroRect;
        }
        const NSRect frame = [controller leadingClusterFrameInWindowCoordinates];
        if (!NSIsEmptyRect(frame)) {
            return frame;
        }
    }

    return NSZeroRect;
}

static NSRect fallbackLeadingToolbarClusterFrameForDrag(NSWindow* nsWindow,
                                                        const WindowChromeMetrics& metrics) {
    if (nsWindow == nil) {
        return NSZeroRect;
    }

    const CGFloat windowHeight = NSHeight(nsWindow.frame);
    const CGFloat titleBarHeight =
        qMax<CGFloat>(0.0, NSHeight(nsWindow.frame) - NSHeight(nsWindow.contentLayoutRect));
    const CGFloat topInset = qMax<CGFloat>(0.0, titleBarHeight - 20.0) / 2.0;
    return NSMakeRect(normalizedTrafficLightsSafeWidth(metrics),
                      qMax<CGFloat>(0.0, windowHeight - titleBarHeight + topInset),
                      kLeadingToolbarClusterFallbackWidth,
                      20.0);
}

static CGFloat dragRegionStartXForClusterFrame(const WindowChromeMetrics& metrics,
                                               const NSRect& leadingClusterFrame) {
    if (NSIsEmptyRect(leadingClusterFrame)) {
        return dragRegionStartXForMetrics(metrics);
    }

    return NSMaxX(leadingClusterFrame) + kTitleBarDragRegionLeadingGap;
}

static QRect qRectFromNSRect(const NSRect& rect) {
    return QRect(qRound(NSMinX(rect)),
                 qRound(NSMinY(rect)),
                 qRound(NSWidth(rect)),
                 qRound(NSHeight(rect)));
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

static NSImage* symbolImage(NSString* systemName, NSString* accessibilityDescription, CGFloat pointSize) {
    if (@available(macOS 11.0, *)) {
        NSImage* image =
            [NSImage imageWithSystemSymbolName:systemName accessibilityDescription:accessibilityDescription];
        if (image != nil) {
            NSImageSymbolConfiguration* configuration =
                [NSImageSymbolConfiguration configurationWithPointSize:pointSize
                                                                weight:NSFontWeightRegular];
            return [image imageWithSymbolConfiguration:configuration];
        }
    }

    return nil;
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

static NSView* hitTestViewForWindowPoint(NSWindow* nsWindow, NSPoint windowPoint) {
    NSView* hostView = dragRegionHostViewForWindow(nsWindow, nil);
    if (hostView == nil) {
        return nil;
    }

    const NSPoint hostPoint = [hostView convertPoint:windowPoint fromView:nil];
    return [hostView hitTest:hostPoint];
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

static NSImage* sidebarToggleButtonImage() {
    return symbolImage(@"sidebar.left", @"Toggle Sidebar", 15.0);
}

static NSImage* navigationSymbolImage(bool forward) {
    return symbolImage(forward ? @"chevron.forward" : @"chevron.backward",
                       forward ? @"Go Forward" : @"Go Back",
                       11.0);
}

static KuclawChromeToolbarController* installOrUpdateToolbarChrome(NSWindow* nsWindow,
                                                                   std::function<void()> sidebarToggleHandler,
                                                                   std::function<void()> backHandler,
                                                                   std::function<void()> forwardHandler,
                                                                   bool backEnabled,
                                                                   bool forwardEnabled) {
    if (nsWindow == nil) {
        return nil;
    }

    KuclawChromeToolbarController* controller = toolbarControllerForWindow(nsWindow);
    if (controller == nil) {
        controller = [[KuclawChromeToolbarController alloc] initWithWindow:nsWindow];
        controller.sidebarButton.image = sidebarToggleButtonImage();
        if (controller.sidebarButton.image == nil) {
            controller.sidebarButton.title = @"|||";
        }

        [controller.navigationControl setImage:navigationSymbolImage(false) forSegment:0];
        [controller.navigationControl setImage:navigationSymbolImage(true) forSegment:1];

        objc_setAssociatedObject(nsWindow,
                                 kWindowToolbarControllerAssociationKey,
                                 controller,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(nsWindow,
                                 kWindowToolbarAssociationKey,
                                 controller.toolbar,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    const auto sidebar = std::move(sidebarToggleHandler);
    const auto back = std::move(backHandler);
    const auto forward = std::move(forwardHandler);
    dispatch_block_t sidebarBlock = nil;
    if (sidebar) {
        sidebarBlock = ^{
            sidebar();
        };
    }

    dispatch_block_t backBlock = nil;
    if (back) {
        backBlock = ^{
            back();
        };
    }

    dispatch_block_t forwardBlock = nil;
    if (forward) {
        forwardBlock = ^{
            forward();
        };
    }

    [controller updateHandlersWithSidebar:sidebarBlock back:backBlock forward:forwardBlock];
    [controller updateNavigationEnabledBack:backEnabled forward:forwardEnabled];

    if (@available(macOS 11.0, *)) {
        nsWindow.toolbarStyle = NSWindowToolbarStyleUnified;
        nsWindow.titlebarSeparatorStyle = NSTitlebarSeparatorStyleNone;
    }
    controller.toolbar.showsBaselineSeparator = NO;
    [controller installForCurrentWindowState];

    return controller;
}

static void installOrUpdateDragMonitor(NSWindow* nsWindow,
                                       CGFloat titleBarHeight,
                                       const WindowChromeMetrics& metrics) {
    if (nsWindow == nil) {
        return;
    }

    id existingMonitor = dragRegionMonitorForWindow(nsWindow);
    if (existingMonitor != nil) {
        [NSEvent removeMonitor:existingMonitor];
        objc_setAssociatedObject(nsWindow,
                                 kWindowDragMonitorAssociationKey,
                                 nil,
                                 OBJC_ASSOCIATION_ASSIGN);
    }

    __weak NSWindow* weakWindow = nsWindow;
    id monitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown
                                                       handler:^NSEvent* _Nullable(NSEvent* _Nonnull event) {
                                                           NSWindow* strongWindow = weakWindow;
                                                           if (strongWindow == nil || event == nil) {
                                                               return event;
                                                           }

                                                           if (event.window != strongWindow) {
                                                               return event;
                                                           }

                                                           if (trafficLightNameForPoint(strongWindow, event.locationInWindow)[0] != '\0') {
                                                               return event;
                                                           }

                                                           NSRect leadingClusterFrame =
                                                               installedLeadingToolbarClusterFrameForWindow(strongWindow);
                                                           if (NSIsEmptyRect(leadingClusterFrame)) {
                                                               leadingClusterFrame =
                                                                   fallbackLeadingToolbarClusterFrameForDrag(
                                                                       strongWindow, metrics);
                                                           }
                                                           if (!NSIsEmptyRect(leadingClusterFrame)
                                                               && NSPointInRect(event.locationInWindow, leadingClusterFrame)) {
                                                               return event;
                                                           }

                                                           const CGFloat currentTitleBarHeight =
                                                               qMax(0.0,
                                                                    NSHeight(strongWindow.frame)
                                                                        - NSHeight(strongWindow.contentLayoutRect));
                                                           const NSRect dragRect =
                                                               dragRegionRectForWindow(strongWindow,
                                                                                       currentTitleBarHeight,
                                                                                       metrics,
                                                                                       dragRegionStartXForClusterFrame(
                                                                                           metrics,
                                                                                           leadingClusterFrame));
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

static void installOrUpdateDragRegion(NSWindow* nsWindow,
                                      NSView* nativeView,
                                      CGFloat titleBarHeight,
                                      const WindowChromeMetrics& metrics) {
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

    if (dragView.superview != hostView) {
        [dragView removeFromSuperview];
    }
    [hostView addSubview:dragView positioned:NSWindowBelow relativeTo:nil];

    NSRect leadingClusterFrame = installedLeadingToolbarClusterFrameForWindow(nsWindow);
    if (NSIsEmptyRect(leadingClusterFrame)) {
        leadingClusterFrame = fallbackLeadingToolbarClusterFrameForDrag(nsWindow, metrics);
    }
    const CGFloat dragRegionStartX =
        dragRegionStartXForClusterFrame(metrics, leadingClusterFrame);
    dragView.frame = dragRegionFrameForView(hostView, titleBarHeight, metrics, dragRegionStartX);
    dragView.hidden = NSIsEmptyRect(dragView.frame);
}
}  // namespace
#endif

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

    nsWindow.movableByWindowBackground = NO;
    nsWindow.titleVisibility = NSWindowTitleHidden;
    nsWindow.titlebarAppearsTransparent = YES;
    nsWindow.styleMask |= NSWindowStyleMaskFullSizeContentView;
    nsWindow.collectionBehavior |= NSWindowCollectionBehaviorFullScreenPrimary;
    metrics = currentWindowChromeMetrics(nsWindow);
    if (!metrics.usesNativeTrafficLights) {
        return metrics;
    }

    installOrUpdateToolbarChrome(nsWindow,
                                 std::move(sidebarToggleHandler),
                                 std::move(backHandler),
                                 std::move(forwardHandler),
                                 false,
                                 false);
    installOrUpdateDragRegion(nsWindow,
                              nativeView,
                              metrics.titleBarHeight,
                              metrics);
    installOrUpdateDragMonitor(nsWindow, metrics.titleBarHeight, metrics);
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

void MacWindowChrome::updateNativeToolbarState(QWindow* window, bool backEnabled, bool forwardEnabled) {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (window == nullptr || !runningOnCocoaPlatform()) {
        return;
    }

    const WId nativeId = window->winId();
    if (nativeId == 0) {
        return;
    }

    auto* nativeView = (__bridge NSView*)(reinterpret_cast<void*>(nativeId));
    if (nativeView == nil || nativeView.window == nil) {
        return;
    }

    NSWindow* nsWindow = nativeView.window;
    KuclawChromeToolbarController* controller = toolbarControllerForWindow(nsWindow);
    if (controller == nil) {
        return;
    }

    [controller installForCurrentWindowState];
    [controller updateNavigationEnabledBack:backEnabled forward:forwardEnabled];
    const WindowChromeMetrics metrics = currentWindowChromeMetrics(nsWindow);
    installOrUpdateDragRegion(nsWindow, nativeView, metrics.titleBarHeight, metrics);
    installOrUpdateDragMonitor(nsWindow, metrics.titleBarHeight, metrics);
#else
    Q_UNUSED(window);
    Q_UNUSED(backEnabled);
    Q_UNUSED(forwardEnabled);
#endif
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

    KuclawChromeToolbarController* controller = toolbarControllerForWindow(nsWindow);
    if (controller != nil) {
        [controller detachFromWindow];
    } else {
        NSToolbar* toolbar = toolbarForWindow(nsWindow);
        if (toolbar != nil && nsWindow.toolbar == toolbar) {
            nsWindow.toolbar = nil;
        }
    }
    objc_setAssociatedObject(nsWindow,
                             kWindowToolbarAssociationKey,
                             nil,
                             OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(nsWindow,
                             kWindowToolbarControllerAssociationKey,
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
    NSRect leadingClusterFrame = installedLeadingToolbarClusterFrameForWindow(nsWindow);
    if (NSIsEmptyRect(leadingClusterFrame)) {
        leadingClusterFrame = fallbackLeadingToolbarClusterFrameForDrag(nsWindow, metrics);
    }
    const NSRect dragRect =
        dragRegionRectForWindow(nsWindow,
                                titleBarHeight,
                                metrics,
                                dragRegionStartXForClusterFrame(metrics, leadingClusterFrame));
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
    NSRect leadingClusterFrame = installedLeadingToolbarClusterFrameForWindow(nsWindow);
    if (NSIsEmptyRect(leadingClusterFrame)) {
        leadingClusterFrame = fallbackLeadingToolbarClusterFrameForDrag(nsWindow, metrics);
    }
    const NSRect dragRect =
        dragRegionRectForWindow(nsWindow,
                                titleBarHeight,
                                metrics,
                                dragRegionStartXForClusterFrame(metrics, leadingClusterFrame));
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

bool MacWindowChrome::hasLeadingToolbarCluster(QWindow* window) const {
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

    const NSRect frame = installedLeadingToolbarClusterFrameForWindow(nativeView.window);
    return !NSIsEmptyRect(frame);
#else
    Q_UNUSED(window);
    return false;
#endif
}

QRect MacWindowChrome::leadingToolbarClusterFrame(QWindow* window) const {
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

    return qRectFromNSRect(installedLeadingToolbarClusterFrameForWindow(nativeView.window));
#else
    Q_UNUSED(window);
    return {};
#endif
}

bool MacWindowChrome::leadingToolbarClusterCapturesHitTest(QWindow* window) const {
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
    const NSRect frame = installedLeadingToolbarClusterFrameForWindow(nsWindow);
    if (NSIsEmptyRect(frame)) {
        return false;
    }

    NSView* hitView = hitTestViewForWindowPoint(nsWindow, NSMakePoint(NSMidX(frame), NSMidY(frame)));
    KuclawChromeToolbarController* controller = toolbarControllerForWindow(nsWindow);
    if (controller == nil || hitView == nil) {
        return false;
    }

    return [hitView isDescendantOf:controller.leadingClusterView]
           || hitView == controller.leadingClusterView;
#else
    Q_UNUSED(window);
    return false;
#endif
}

bool MacWindowChrome::leadingToolbarClusterUsesDirectTitlebarHost(QWindow* window) const {
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

    KuclawChromeToolbarController* controller = toolbarControllerForWindow(nativeView.window);
    return controller != nil && [controller leadingClusterUsesDirectTitlebarHost];
#else
    Q_UNUSED(window);
    return false;
#endif
}

bool MacWindowChrome::leadingToolbarClusterUsesToolbarItem(QWindow* window) const {
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

    KuclawChromeToolbarController* controller = toolbarControllerForWindow(nativeView.window);
    return controller != nil && [controller leadingClusterUsesToolbarItem];
#else
    Q_UNUSED(window);
    return false;
#endif
}

bool MacWindowChrome::leadingToolbarClusterUsesTitlebarAccessory(QWindow* window) const {
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

    KuclawChromeToolbarController* controller = toolbarControllerForWindow(nativeView.window);
    return controller != nil && [controller leadingClusterUsesTitlebarAccessory];
#else
    Q_UNUSED(window);
    return false;
#endif
}

NativeNavigationState MacWindowChrome::navigationEnabledState(QWindow* window) const {
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

    KuclawChromeToolbarController* controller = toolbarControllerForWindow(nativeView.window);
    return controller != nil ? [controller navigationEnabledState] : NativeNavigationState{};
#else
    Q_UNUSED(window);
    return {};
#endif
}

bool MacWindowChrome::hasHiddenTitlebarSeparator(WId nativeId) const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (nativeId == 0 || !runningOnCocoaPlatform()) {
        return false;
    }

    NSWindow* nsWindow = nativeWindowForId(nativeId);
    if (nsWindow == nil) {
        return false;
    }

    if (@available(macOS 11.0, *)) {
        NSToolbar* toolbar = toolbarForWindow(nsWindow);
        return nsWindow.titlebarSeparatorStyle == NSTitlebarSeparatorStyleNone
               && (toolbar == nil || !toolbar.showsBaselineSeparator);
    }

    return false;
#else
    Q_UNUSED(nativeId);
    return false;
#endif
}

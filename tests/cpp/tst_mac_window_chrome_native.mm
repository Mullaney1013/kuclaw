#include <QtTest>

#include <QGuiApplication>
#include <QWindow>

#import <AppKit/AppKit.h>

#include "integration/platform/MacWindowChrome.h"
#include "ui_bridge/viewmodels/WindowChromeViewModel.h"

@interface ReferenceToolbarDelegate : NSObject <NSToolbarDelegate>
@end

@implementation ReferenceToolbarDelegate

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

namespace {

NSRect trafficLightsClusterFrameForNSWindow(NSWindow* nsWindow) {
    if (nsWindow == nil) {
        return NSZeroRect;
    }

    NSButton* closeButton = [nsWindow standardWindowButton:NSWindowCloseButton];
    NSButton* minimizeButton = [nsWindow standardWindowButton:NSWindowMiniaturizeButton];
    NSButton* zoomButton = [nsWindow standardWindowButton:NSWindowZoomButton];
    if (closeButton == nil || minimizeButton == nil || zoomButton == nil) {
        return NSZeroRect;
    }

    const NSRect closeFrame = [closeButton convertRect:closeButton.bounds toView:nil];
    const NSRect minimizeFrame = [minimizeButton convertRect:minimizeButton.bounds toView:nil];
    const NSRect zoomFrame = [zoomButton convertRect:zoomButton.bounds toView:nil];
    return NSUnionRect(NSUnionRect(closeFrame, minimizeFrame), zoomFrame);
}

TrafficLightsGeometry trafficLightsGeometryForNSWindow(NSWindow* nsWindow) {
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

NSWindow* createReferenceWindow() {
    NSRect frame = NSMakeRect(0, 0, 640, 480);
    NSWindow* nsWindow =
        [[NSWindow alloc] initWithContentRect:frame
                                    styleMask:(NSWindowStyleMaskTitled
                                               | NSWindowStyleMaskClosable
                                               | NSWindowStyleMaskMiniaturizable
                                               | NSWindowStyleMaskResizable)
                                      backing:NSBackingStoreBuffered
                                        defer:NO];
    nsWindow.titleVisibility = NSWindowTitleHidden;
    nsWindow.titlebarAppearsTransparent = YES;
    nsWindow.styleMask |= NSWindowStyleMaskFullSizeContentView;
    nsWindow.collectionBehavior |= NSWindowCollectionBehaviorFullScreenPrimary;

    NSToolbar* toolbar = [[NSToolbar alloc] initWithIdentifier:@"com.mullaney1013.kuclaw.referenceToolbar"];
    toolbar.allowsUserCustomization = NO;
    toolbar.autosavesConfiguration = NO;
    toolbar.displayMode = NSToolbarDisplayModeIconOnly;
    ReferenceToolbarDelegate* delegate = [[ReferenceToolbarDelegate alloc] init];
    toolbar.delegate = delegate;
    nsWindow.toolbar = toolbar;

    if (@available(macOS 11.0, *)) {
        nsWindow.toolbarStyle = NSWindowToolbarStyleUnified;
    }

    [nsWindow center];
    [nsWindow makeKeyAndOrderFront:nil];
    return nsWindow;
}
}  // namespace

class MacWindowChromeNativeTest : public QObject {
    Q_OBJECT

private slots:
    void macWindowChromeKeepsTrafficLightsInStandardVerticalBandForNativeWindow() {
        if (QGuiApplication::platformName() != "cocoa") {
            QSKIP("Native traffic-lights band verification requires the cocoa platform plugin.");
        }

        if (QGuiApplication::screens().isEmpty()) {
            QSKIP("No screens available for native traffic-lights band verification.");
        }

        QWindow window;
        window.resize(640, 480);
        window.show();
        QVERIFY(QTest::qWaitForWindowExposed(&window));

        MacWindowChrome chrome;
        chrome.attach(&window);
        QTest::qWait(50);

        const TrafficLightsGeometry actual = chrome.trafficLightsGeometry(&window);
        QVERIFY2(actual.valid, "Attached AppShell window should expose native traffic-lights geometry.");

        NSWindow* referenceWindow = createReferenceWindow();
        QVERIFY(referenceWindow != nil);
        QTest::qWait(50);

        const TrafficLightsGeometry expected = trafficLightsGeometryForNSWindow(referenceWindow);
        QVERIFY2(expected.valid,
                 "Reference toolbar-style NSWindow should expose native traffic-lights geometry.");

        const QByteArray topInsetMessage =
            QString("Traffic-lights cluster top inset should stay within the standard "
                    "toolbar/titlebar band. actual=%1 expected=%2")
                .arg(actual.clusterTopInset)
                .arg(expected.clusterTopInset)
                .toUtf8();
        QVERIFY2(qAbs(actual.clusterTopInset - expected.clusterTopInset) <= 4,
                 topInsetMessage.constData());

        const QByteArray midYMessage =
            QString("Traffic-lights cluster vertical center should match the standard "
                    "toolbar/titlebar band. actualFromTop=%1 expectedFromTop=%2 rawActual=%3 rawExpected=%4")
                .arg(actual.clusterMidYFromTop)
                .arg(expected.clusterMidYFromTop)
                .arg(actual.clusterMidY)
                .arg(expected.clusterMidY)
                .toUtf8();
        QVERIFY2(qAbs(actual.clusterMidYFromTop - expected.clusterMidYFromTop) <= 4,
                 midYMessage.constData());
        QVERIFY2(qAbs(actual.closeMinSpacing - expected.closeMinSpacing) <= 2,
                 "Traffic-lights close/minimize spacing should stay native.");
        QVERIFY2(qAbs(actual.minZoomSpacing - expected.minZoomSpacing) <= 2,
                 "Traffic-lights minimize/zoom spacing should stay native.");

        [referenceWindow orderOut:nil];
    }

    void macWindowChromeInstallsLeadingNativeToolbarCluster() {
        if (QGuiApplication::platformName() != "cocoa") {
            QSKIP("Native leading-cluster verification requires the cocoa platform plugin.");
        }

        if (QGuiApplication::screens().isEmpty()) {
            QSKIP("No screens available for native leading-cluster verification.");
        }

        QWindow window;
        window.resize(640, 480);
        window.show();
        QVERIFY(QTest::qWaitForWindowExposed(&window));

        MacWindowChrome chrome;
        const WindowChromeMetrics metrics = chrome.attach(&window);

        QTRY_VERIFY(chrome.hasToolbarChrome(window.winId()));
        QTRY_VERIFY(chrome.hasLeadingToolbarCluster(&window));
        QTRY_VERIFY(chrome.leadingToolbarClusterUsesDirectTitlebarHost(&window));
        QVERIFY(!chrome.leadingToolbarClusterFrame(&window).isEmpty());
        QTRY_VERIFY(chrome.leadingToolbarClusterCapturesHitTest(&window));

        const TrafficLightsGeometry geometry = chrome.trafficLightsGeometry(&window);
        QVERIFY(geometry.valid);
        const QRect leadingClusterFrame = chrome.leadingToolbarClusterFrame(&window);
        const QByteArray rowMessage =
            QString("Leading native cluster should stay on the same titlebar row as the traffic lights."
                    " clusterMidY=%1 trafficMidY=%2")
                .arg(leadingClusterFrame.center().y())
                .arg(geometry.clusterMidY)
                .toUtf8();
        QVERIFY2(qAbs(leadingClusterFrame.center().y() - geometry.clusterMidY) <= 4,
                 rowMessage.constData());
        QVERIFY(leadingClusterFrame.left() >= metrics.trafficLightsSafeWidth);
    }

    void macWindowChromeUpdatesNativeNavigationEnabledState() {
        if (QGuiApplication::platformName() != "cocoa") {
            QSKIP("Native navigation enabled-state verification requires the cocoa platform plugin.");
        }

        if (QGuiApplication::screens().isEmpty()) {
            QSKIP("No screens available for native navigation enabled-state verification.");
        }

        QWindow window;
        window.resize(640, 480);
        window.show();
        QVERIFY(QTest::qWaitForWindowExposed(&window));

        MacWindowChrome chrome;
        chrome.attach(&window);

        chrome.updateNativeToolbarState(&window, false, false);
        QCOMPARE(chrome.navigationEnabledState(&window).backEnabled, false);
        QCOMPARE(chrome.navigationEnabledState(&window).forwardEnabled, false);

        chrome.updateNativeToolbarState(&window, true, false);
        QCOMPARE(chrome.navigationEnabledState(&window).backEnabled, true);
        QCOMPARE(chrome.navigationEnabledState(&window).forwardEnabled, false);

        chrome.updateNativeToolbarState(&window, true, true);
        QCOMPARE(chrome.navigationEnabledState(&window).backEnabled, true);
        QCOMPARE(chrome.navigationEnabledState(&window).forwardEnabled, true);
    }

    void macWindowChromeFullscreenKeepsLeadingClusterAlongsideTrafficLights() {
        if (QGuiApplication::platformName() != "cocoa") {
            QSKIP("Native fullscreen titlebar verification requires the cocoa platform plugin.");
        }

        if (QGuiApplication::screens().isEmpty()) {
            QSKIP("No screens available for native fullscreen titlebar verification.");
        }

        QWindow window;
        window.resize(640, 480);
        window.show();
        QVERIFY(QTest::qWaitForWindowExposed(&window));

        MacWindowChrome chrome;
        const WindowChromeMetrics metrics = chrome.attach(&window);
        QVERIFY(chrome.hasToolbarChrome(window.winId()));
        QVERIFY(chrome.toggleNativeFullscreen(&window));
        QTRY_COMPARE(window.visibility(), QWindow::FullScreen);
        QTRY_VERIFY(chrome.hasLeadingToolbarCluster(&window));
        QTRY_VERIFY(chrome.leadingToolbarClusterUsesDirectTitlebarHost(&window));
        QTRY_VERIFY(chrome.leadingToolbarClusterCapturesHitTest(&window));
        QVERIFY(!chrome.leadingToolbarClusterFrame(&window).isEmpty());
        QVERIFY(chrome.leadingToolbarClusterFrame(&window).left() >= metrics.trafficLightsSafeWidth);
        const TrafficLightsGeometry fullscreenGeometry = chrome.trafficLightsGeometry(&window);
        QVERIFY(fullscreenGeometry.valid);
        const QRect fullscreenClusterFrame = chrome.leadingToolbarClusterFrame(&window);
        const QByteArray fullscreenRowMessage =
            QString("Fullscreen leading native cluster should stay on the same titlebar row as the traffic lights."
                    " clusterMidY=%1 trafficMidY=%2")
                .arg(fullscreenClusterFrame.center().y())
                .arg(fullscreenGeometry.clusterMidY)
                .toUtf8();
        QVERIFY2(qAbs(fullscreenClusterFrame.center().y() - fullscreenGeometry.clusterMidY) <= 4,
                 fullscreenRowMessage.constData());
        const int fullscreenClusterTopInset =
            window.frameGeometry().height() - fullscreenClusterFrame.top() - fullscreenClusterFrame.height();
        const QByteArray fullscreenTopInsetMessage =
            QString("Fullscreen leading native cluster should stay close to the top-left chrome band."
                    " clusterTopInset=%1 trafficTopInset=%2")
                .arg(fullscreenClusterTopInset)
                .arg(fullscreenGeometry.clusterTopInset)
                .toUtf8();
        QVERIFY2(qAbs(fullscreenClusterTopInset - fullscreenGeometry.clusterTopInset) <= 8,
                 fullscreenTopInsetMessage.constData());
        NSView* nativeView = (__bridge NSView*)(reinterpret_cast<void*>(window.winId()));
        NSWindow* nativeWindow = nativeView != nil ? nativeView.window : nil;
        QVERIFY(nativeWindow != nil);
        const NSRect fullscreenTrafficLightsFrame = trafficLightsClusterFrameForNSWindow(nativeWindow);
        QVERIFY(!NSIsEmptyRect(fullscreenTrafficLightsFrame));
        const int fullscreenLeadingGap =
            fullscreenClusterFrame.left() - qRound(NSMaxX(fullscreenTrafficLightsFrame));
        const QByteArray fullscreenLeadingGapMessage =
            QString("Fullscreen leading native cluster should sit close to the traffic lights."
                    " leadingGap=%1")
                .arg(fullscreenLeadingGap)
                .toUtf8();
        QVERIFY2(fullscreenLeadingGap >= 0 && fullscreenLeadingGap <= 1,
                 fullscreenLeadingGapMessage.constData());
        QTRY_VERIFY(!chrome.hasToolbarChrome(window.winId()));
        QTRY_VERIFY(chrome.hasHiddenTitlebarSeparator(window.winId()));

        chrome.toggleNativeFullscreen(&window);
        QTRY_COMPARE(window.visibility(), QWindow::Windowed);
        QTRY_VERIFY(chrome.hasLeadingToolbarCluster(&window));
        QTRY_VERIFY(chrome.leadingToolbarClusterUsesDirectTitlebarHost(&window));
        QTRY_VERIFY(chrome.leadingToolbarClusterCapturesHitTest(&window));
        QTRY_VERIFY(chrome.hasToolbarChrome(window.winId()));
    }

    void destroyedWindowFallbackDetachesNativeChromeArtifactsByStoredNativeId() {
        if (QGuiApplication::platformName() != "cocoa") {
            QSKIP("Destroyed-window native cleanup verification requires the cocoa platform plugin.");
        }

        if (QGuiApplication::screens().isEmpty()) {
            QSKIP("No screens available for destroyed-window native cleanup verification.");
        }

        auto* window = new QWindow;
        window->resize(640, 480);
        window->show();
        QVERIFY(QTest::qWaitForWindowExposed(window));

        WindowChromeViewModel viewModel;
        viewModel.attach(window);
        QTRY_VERIFY(viewModel.usesNativeTrafficLights());

        const WId nativeId = window->winId();
        QVERIFY(nativeId != 0);

        MacWindowChrome chrome;
        QVERIFY(chrome.hasTitleBarDragMonitor(nativeId));
        QVERIFY(chrome.hasTitleBarDragRegion(nativeId));
        QVERIFY(chrome.hasToolbarChrome(nativeId));

        NSView* retainedNativeView = (__bridge NSView*)(reinterpret_cast<void*>(nativeId));
        QVERIFY(retainedNativeView != nil);
        NSWindow* retainedWindow = retainedNativeView.window;
        QVERIFY(retainedWindow != nil);

        window->removeEventFilter(&viewModel);
        delete window;

        QCoreApplication::processEvents();
        QTest::qWait(50);

        QVERIFY(!chrome.hasTitleBarDragMonitor(nativeId));
        QVERIFY(!chrome.hasTitleBarDragRegion(nativeId));
        QVERIFY(!chrome.hasToolbarChrome(nativeId));
        QCOMPARE(viewModel.usesNativeTrafficLights(), false);

        [retainedWindow orderOut:nil];
    }
};

QTEST_MAIN(MacWindowChromeNativeTest)

#include "tst_mac_window_chrome_native.moc"

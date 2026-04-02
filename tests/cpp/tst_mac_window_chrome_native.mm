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

    void windowChromeViewModelReappliesDragRegionWhenControlRectsChange() {
        if (QGuiApplication::platformName() != "cocoa") {
            QSKIP("Native drag-region reapply verification requires the cocoa platform plugin.");
        }

        if (QGuiApplication::screens().isEmpty()) {
            QSKIP("No screens available for native drag-region reapply verification.");
        }

        QWindow window;
        window.resize(640, 480);
        window.show();
        QVERIFY(QTest::qWaitForWindowExposed(&window));

        WindowChromeViewModel viewModel;
        viewModel.attach(&window);
        QTRY_VERIFY(viewModel.usesNativeTrafficLights());

        MacWindowChrome chrome;
        const int baselineStartX = chrome.currentTitleBarDragRegionStartX(&window);
        QVERIFY(baselineStartX > 0);

        viewModel.updateTitleBarControlRects(120.0,
                                             100.0,
                                             20.0,
                                             16.0,
                                             160.0,
                                             100.0,
                                             12.0,
                                             14.0,
                                             176.0,
                                             100.0,
                                             12.0,
                                             14.0);

        QTRY_COMPARE(chrome.currentTitleBarDragRegionStartX(&window), 208);
        QVERIFY(chrome.currentTitleBarDragRegionStartX(&window) > baselineStartX);
    }
};

QTEST_MAIN(MacWindowChromeNativeTest)

#include "tst_mac_window_chrome_native.moc"

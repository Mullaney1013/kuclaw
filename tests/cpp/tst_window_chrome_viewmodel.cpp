#include <QtTest>

#include <QGuiApplication>
#include <QSignalSpy>
#include <QWindow>

#include "integration/platform/MacWindowChrome.h"
#include "ui_bridge/viewmodels/WindowChromeViewModel.h"

namespace {
WindowChromeMetrics fakeMetricsProvider(QWindow* window) {
    Q_UNUSED(window);
    return WindowChromeMetrics{
        true,
        78,
        32,
    };
}
}  // namespace

class WindowChromeViewModelTest : public QObject {
    Q_OBJECT

private slots:
    void attachIgnoresNonWindowObjects() {
        WindowChromeViewModel viewModel;
        QObject plainObject;

        QSignalSpy spy(&viewModel, &WindowChromeViewModel::metricsChanged);
        viewModel.attach(&plainObject);

        QCOMPARE(viewModel.usesNativeTrafficLights(), false);
        QCOMPARE(viewModel.trafficLightsSafeWidth(), 0);
        QCOMPARE(viewModel.titleBarHeight(), 0);
        QCOMPARE(spy.count(), 0);
    }

    void attachUsesInjectedMetricsProvider() {
        WindowChromeViewModel viewModel(nullptr, fakeMetricsProvider);
        QWindow window;

        QSignalSpy spy(&viewModel, &WindowChromeViewModel::metricsChanged);
        viewModel.attach(&window);

        QCOMPARE(viewModel.usesNativeTrafficLights(), true);
        QCOMPARE(viewModel.trafficLightsSafeWidth(), 78);
        QCOMPARE(viewModel.titleBarHeight(), 32);
        QCOMPARE(spy.count(), 1);
    }

    void attachRetriesUntilMetricsBecomeAvailable() {
        int attachCount = 0;
        WindowChromeViewModel viewModel(nullptr, [&attachCount](QWindow* window) {
            Q_UNUSED(window);
            ++attachCount;
            if (attachCount < 3) {
                return WindowChromeMetrics{};
            }

            return WindowChromeMetrics{
                true,
                78,
                32,
            };
        });
        QWindow window;

        QSignalSpy spy(&viewModel, &WindowChromeViewModel::metricsChanged);
        viewModel.attach(&window);

        QTRY_VERIFY_WITH_TIMEOUT(attachCount >= 3, 1000);
        QCOMPARE(viewModel.usesNativeTrafficLights(), true);
        QCOMPARE(viewModel.trafficLightsSafeWidth(), 78);
        QCOMPARE(viewModel.titleBarHeight(), 32);
        QCOMPARE(spy.count(), 1);
    }

    void attachStopsRetryingAfterSuccess() {
        int attachCount = 0;
        WindowChromeViewModel viewModel(nullptr, [&attachCount](QWindow* window) {
            Q_UNUSED(window);
            ++attachCount;
            if (attachCount == 1) {
                return WindowChromeMetrics{};
            }

            return WindowChromeMetrics{
                true,
                78,
                32,
            };
        });
        QWindow window;

        viewModel.attach(&window);
        QTRY_COMPARE_WITH_TIMEOUT(attachCount, 2, 1000);

        const int settledAttachCount = attachCount;
        QTest::qWait(100);
        QCOMPARE(attachCount, settledAttachCount);
        QCOMPARE(viewModel.usesNativeTrafficLights(), true);
    }

    void attachKeepsRetryingBeyondInitialWarmupWindow() {
        int attachCount = 0;
        WindowChromeViewModel viewModel(nullptr, [&attachCount](QWindow* window) {
            Q_UNUSED(window);
            ++attachCount;
            if (attachCount <= 80) {
                return WindowChromeMetrics{};
            }

            return WindowChromeMetrics{
                true,
                78,
                32,
            };
        });
        QWindow window;

        viewModel.attach(&window);

        QTRY_VERIFY_WITH_TIMEOUT(viewModel.usesNativeTrafficLights(), 4000);
        QCOMPARE(viewModel.trafficLightsSafeWidth(), 78);
        QCOMPARE(viewModel.titleBarHeight(), 32);
        QCOMPARE(attachCount, 81);
    }

    void attachReplacesPendingRetryWhenSwitchingWindows() {
        int firstWindowCount = 0;
        int secondWindowCount = 0;
        QWindow firstWindow;
        QWindow secondWindow;
        WindowChromeViewModel viewModel(nullptr,
                                        [&firstWindowCount, &secondWindowCount, &firstWindow,
                                         &secondWindow](QWindow* window) {
                                            if (window == &firstWindow) {
                                                ++firstWindowCount;
                                                return WindowChromeMetrics{};
                                            }

                                            if (window == &secondWindow) {
                                                ++secondWindowCount;
                                                return WindowChromeMetrics{
                                                    true,
                                                    78,
                                                    32,
                                                };
                                            }

                                            return WindowChromeMetrics{};
                                        });

        viewModel.attach(&firstWindow);
        QCOMPARE(firstWindowCount, 1);

        viewModel.attach(&secondWindow);
        QTRY_VERIFY_WITH_TIMEOUT(secondWindowCount >= 1, 1000);

        const int settledFirstWindowCount = firstWindowCount;
        QTest::qWait(100);

        QCOMPARE(firstWindowCount, settledFirstWindowCount);
        QCOMPARE(viewModel.usesNativeTrafficLights(), true);
        QCOMPARE(viewModel.trafficLightsSafeWidth(), 78);
        QCOMPARE(viewModel.titleBarHeight(), 32);
    }

    void beginSystemDragReturnsFalseWithoutTrackedWindow() {
        WindowChromeViewModel viewModel;

        QVERIFY(!viewModel.beginSystemDrag());
    }

    void beginSystemDragUsesInjectedDragProviderForTrackedWindow() {
        int dragCount = 0;
        QWindow window;
        WindowChromeViewModel viewModel(nullptr,
                                        fakeMetricsProvider,
                                        [&dragCount, &window](QWindow* trackedWindow) {
                                            ++dragCount;
                                            return trackedWindow == &window;
                                        });

        viewModel.attach(&window);

        QVERIFY(viewModel.beginSystemDrag());
        QCOMPARE(dragCount, 1);
    }

#ifdef Q_OS_MACOS
    void macWindowChromeDerivesDragRegionStartFromMeasuredSafeWidth() {
        MacWindowChrome chrome;

        const int baselineStartX = chrome.titleBarDragRegionStartXForMetrics(
            WindowChromeMetrics{ true, 78, 32 });
        const int widerStartX = chrome.titleBarDragRegionStartXForMetrics(
            WindowChromeMetrics{ true, 110, 32 });

        QCOMPARE(baselineStartX, 192);
        QVERIFY(widerStartX > baselineStartX);
    }

    void macWindowChromeReturnsUsableMetricsForNativeWindow() {
        if (QGuiApplication::platformName() != "cocoa") {
            QSKIP("Native NSWindow metrics require the cocoa platform plugin.");
        }

        if (QGuiApplication::screens().isEmpty()) {
            QSKIP("No screens available for native window verification.");
        }

        QWindow window;
        window.resize(640, 480);
        window.show();
        QVERIFY(QTest::qWaitForWindowExposed(&window));

        MacWindowChrome chrome;
        const WindowChromeMetrics metrics = chrome.attach(&window);

        QVERIFY(metrics.usesNativeTrafficLights);
        QVERIFY(metrics.trafficLightsSafeWidth > 0);
        QVERIFY(metrics.titleBarHeight > 0);
        QVERIFY2(metrics.titleBarHeight < 120, "Native title bar height should stay in a realistic range for AppShell layout.");
    }

    void macWindowChromeInstallsNativeDragRegionForNativeWindow() {
        if (QGuiApplication::platformName() != "cocoa") {
            QSKIP("Native drag region verification requires the cocoa platform plugin.");
        }

        if (QGuiApplication::screens().isEmpty()) {
            QSKIP("No screens available for native drag region verification.");
        }

        QWindow window;
        window.resize(640, 480);
        window.show();
        QVERIFY(QTest::qWaitForWindowExposed(&window));

        MacWindowChrome chrome;
        chrome.attach(&window);

        QVERIFY2(chrome.hasTitleBarDragRegion(&window),
                 "Native title-bar drag region should be installed for expanded AppShell windows.");
        QVERIFY2(chrome.hasTitleBarDragMonitor(&window),
                 "Native title-bar drag monitor should be installed for expanded AppShell windows.");
    }

    void macWindowChromeDragRegionCapturesHitTestForNativeWindow() {
        if (QGuiApplication::platformName() != "cocoa") {
            QSKIP("Native drag region hit-test verification requires the cocoa platform plugin.");
        }

        if (QGuiApplication::screens().isEmpty()) {
            QSKIP("No screens available for native drag region verification.");
        }

        QWindow window;
        window.resize(640, 480);
        window.show();
        QVERIFY(QTest::qWaitForWindowExposed(&window));

        MacWindowChrome chrome;
        chrome.attach(&window);

        QVERIFY2(chrome.titleBarDragRegionCapturesHitTest(&window),
                 "Native title-bar drag region should win hit-testing in the blank AppShell title-bar area.");
    }

    void macWindowChromeDragRegionCapturesTrailingHitTestForNativeWindow() {
        if (QGuiApplication::platformName() != "cocoa") {
            QSKIP("Native trailing drag region verification requires the cocoa platform plugin.");
        }

        if (QGuiApplication::screens().isEmpty()) {
            QSKIP("No screens available for native drag region verification.");
        }

        QWindow window;
        window.resize(640, 480);
        window.show();
        QVERIFY(QTest::qWaitForWindowExposed(&window));

        MacWindowChrome chrome;
        chrome.attach(&window);

        QVERIFY2(chrome.titleBarDragRegionCapturesTrailingHitTest(&window),
                 "Native title-bar drag region should also win hit-testing near the trailing edge of the AppShell title bar.");
    }
#endif
};

QTEST_MAIN(WindowChromeViewModelTest)

#include "tst_window_chrome_viewmodel.moc"

#include <QtTest>

#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QSignalSpy>
#include <QVariant>
#include <QWindow>

#include "integration/platform/MacWindowChrome.h"
#include "ui_bridge/viewmodels/WindowChromeViewModel.h"

namespace {
WindowChromeMetrics fakeMetricsProvider(QWindow* window,
                                        std::function<void()> sidebarToggleHandler,
                                        std::function<void()> backHandler,
                                        std::function<void()> forwardHandler) {
    Q_UNUSED(window);
    Q_UNUSED(sidebarToggleHandler);
    Q_UNUSED(backHandler);
    Q_UNUSED(forwardHandler);
    return WindowChromeMetrics{
        true,
        78,
        32,
    };
}

class InvokableTestWindow : public QWindow {
    Q_OBJECT

public:
    int toggleEventCount = 0;
    int backCount = 0;
    int forwardCount = 0;

    Q_INVOKABLE void dispatchShellEvent(const QString& eventType) {
        if (eventType == QStringLiteral("TOGGLE_CLICKED")) {
            ++toggleEventCount;
        }
    }

    Q_INVOKABLE void goBack() {
        ++backCount;
    }

    Q_INVOKABLE void goForward() {
        ++forwardCount;
    }
};

class VariantInvokableTestWindow : public QWindow {
    Q_OBJECT

public:
    int toggleEventCount = 0;

    Q_INVOKABLE void dispatchShellEvent(const QVariant& eventType) {
        if (eventType.toString() == QStringLiteral("TOGGLE_CLICKED")) {
            ++toggleEventCount;
        }
    }
};

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
        WindowChromeViewModel viewModel(nullptr,
                                        [&attachCount](QWindow* window,
                                                       std::function<void()> sidebarToggleHandler,
                                                       std::function<void()> backHandler,
                                                       std::function<void()> forwardHandler) {
            Q_UNUSED(window);
            Q_UNUSED(sidebarToggleHandler);
            Q_UNUSED(backHandler);
            Q_UNUSED(forwardHandler);
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
        WindowChromeViewModel viewModel(nullptr,
                                        [&attachCount](QWindow* window,
                                                       std::function<void()> sidebarToggleHandler,
                                                       std::function<void()> backHandler,
                                                       std::function<void()> forwardHandler) {
            Q_UNUSED(window);
            Q_UNUSED(sidebarToggleHandler);
            Q_UNUSED(backHandler);
            Q_UNUSED(forwardHandler);
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
        WindowChromeViewModel viewModel(nullptr,
                                        [&attachCount](QWindow* window,
                                                       std::function<void()> sidebarToggleHandler,
                                                       std::function<void()> backHandler,
                                                       std::function<void()> forwardHandler) {
            Q_UNUSED(window);
            Q_UNUSED(sidebarToggleHandler);
            Q_UNUSED(backHandler);
            Q_UNUSED(forwardHandler);
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
                                         &secondWindow](QWindow* window,
                                                        std::function<void()> sidebarToggleHandler,
                                                        std::function<void()> backHandler,
                                                        std::function<void()> forwardHandler) {
                                            Q_UNUSED(sidebarToggleHandler);
                                            Q_UNUSED(backHandler);
                                            Q_UNUSED(forwardHandler);
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

    void attachReattachesAfterSurfaceRecreatedEvenWhenNativeMetricsWereAlreadyAvailable() {
        int attachCount = 0;
        QWindow window;
        WindowChromeViewModel viewModel(
            nullptr,
            [&attachCount](QWindow* trackedWindow,
                           std::function<void()> toggle,
                           std::function<void()> back,
                           std::function<void()> forward) {
                Q_UNUSED(trackedWindow);
                Q_UNUSED(toggle);
                Q_UNUSED(back);
                Q_UNUSED(forward);
                ++attachCount;
                return WindowChromeMetrics{ true, 78, 32 };
            });

        viewModel.attach(&window);

        QCOMPARE(attachCount, 1);
        QVERIFY(viewModel.usesNativeTrafficLights());

        QPlatformSurfaceEvent destroyEvent(QPlatformSurfaceEvent::SurfaceAboutToBeDestroyed);
        QCoreApplication::sendEvent(&window, &destroyEvent);

        QCOMPARE(viewModel.usesNativeTrafficLights(), false);
        QCOMPARE(viewModel.trafficLightsSafeWidth(), 0);
        QCOMPARE(viewModel.titleBarHeight(), 0);

        QPlatformSurfaceEvent createEvent(QPlatformSurfaceEvent::SurfaceCreated);
        QCoreApplication::sendEvent(&window, &createEvent);

        QTRY_COMPARE_WITH_TIMEOUT(attachCount, 2, 1000);
        QVERIFY(viewModel.usesNativeTrafficLights());
        QCOMPARE(viewModel.trafficLightsSafeWidth(), 78);
        QCOMPARE(viewModel.titleBarHeight(), 32);
    }

    void attachDetachesNativeChromeWhenSurfaceIsAboutToBeDestroyed() {
        int detachCount = 0;
        QWindow window;
        const WId expectedNativeId = window.winId();
        WindowChromeViewModel viewModel(
            nullptr,
            fakeMetricsProvider,
            {},
            {},
            [&detachCount, &window, expectedNativeId](QWindow* detachWindow, WId nativeId) {
                ++detachCount;
                QCOMPARE(detachWindow, &window);
                QCOMPARE(nativeId, expectedNativeId);
            });

        viewModel.attach(&window);
        QVERIFY(viewModel.usesNativeTrafficLights());

        QPlatformSurfaceEvent destroyEvent(QPlatformSurfaceEvent::SurfaceAboutToBeDestroyed);
        QCoreApplication::sendEvent(&window, &destroyEvent);

        QCOMPARE(detachCount, 1);
        QCOMPARE(viewModel.usesNativeTrafficLights(), false);
        QCOMPARE(viewModel.trafficLightsSafeWidth(), 0);
        QCOMPARE(viewModel.titleBarHeight(), 0);
    }

    void attachDoesNotDetachNativeChromeFromDestroyedWindowFallback() {
        int detachCount = 0;
        auto* window = new QWindow;
        window->create();
        const WId expectedNativeId = window->winId();
        WindowChromeViewModel viewModel(
            nullptr,
            fakeMetricsProvider,
            {},
            {},
            [&detachCount, expectedNativeId](QWindow* detachWindow, WId nativeId) {
                ++detachCount;
                QCOMPARE(detachWindow, nullptr);
                QCOMPARE(nativeId, expectedNativeId);
            });

        viewModel.attach(window);
        QVERIFY(viewModel.usesNativeTrafficLights());

        window->removeEventFilter(&viewModel);
        delete window;

        QCOMPARE(detachCount, 1);
        QCOMPARE(viewModel.usesNativeTrafficLights(), false);
        QCOMPARE(viewModel.trafficLightsSafeWidth(), 0);
        QCOMPARE(viewModel.titleBarHeight(), 0);
    }

    void attachBridgesNativeCallbacksToSignals() {
        std::function<void()> sidebarToggleHandler;
        std::function<void()> backHandler;
        std::function<void()> forwardHandler;
        QWindow window;
        WindowChromeViewModel viewModel(
            nullptr,
            [&sidebarToggleHandler, &backHandler, &forwardHandler](QWindow* trackedWindow,
                                                                   std::function<void()> toggle,
                                                                   std::function<void()> back,
                                                                   std::function<void()> forward) {
                Q_UNUSED(trackedWindow);
                sidebarToggleHandler = std::move(toggle);
                backHandler = std::move(back);
                forwardHandler = std::move(forward);
                return WindowChromeMetrics{ true, 78, 32 };
            });

        QSignalSpy toggleSpy(&viewModel, &WindowChromeViewModel::sidebarToggleRequested);
        QSignalSpy backSpy(&viewModel, &WindowChromeViewModel::backRequested);
        QSignalSpy forwardSpy(&viewModel, &WindowChromeViewModel::forwardRequested);

        viewModel.attach(&window);

        QVERIFY(sidebarToggleHandler);
        QVERIFY(backHandler);
        QVERIFY(forwardHandler);

        sidebarToggleHandler();
        backHandler();
        forwardHandler();

        QCOMPARE(toggleSpy.count(), 1);
        QCOMPARE(backSpy.count(), 1);
        QCOMPARE(forwardSpy.count(), 1);
    }

    void attachBridgesSidebarToggleToInvokableWindowMethod() {
        std::function<void()> sidebarToggleHandler;
        InvokableTestWindow window;
        WindowChromeViewModel viewModel(
            nullptr,
            [&sidebarToggleHandler](QWindow* trackedWindow,
                                    std::function<void()> toggle,
                                    std::function<void()> back,
                                    std::function<void()> forward) {
                Q_UNUSED(trackedWindow);
                Q_UNUSED(back);
                Q_UNUSED(forward);
                sidebarToggleHandler = std::move(toggle);
                return WindowChromeMetrics{ true, 78, 32 };
            });

        QSignalSpy toggleSpy(&viewModel, &WindowChromeViewModel::sidebarToggleRequested);

        viewModel.attach(&window);

        QVERIFY(sidebarToggleHandler);
        QCOMPARE(window.toggleEventCount, 0);

        sidebarToggleHandler();

        QCOMPARE(window.toggleEventCount, 1);
        QCOMPARE(toggleSpy.count(), 0);
    }

    void attachBridgesSidebarToggleToQmlWindowMethod() {
        std::function<void()> sidebarToggleHandler;
        QQmlEngine engine;
        QQmlComponent component(&engine);
        component.setData(R"(
            import QtQuick
            import QtQuick.Window

            Window {
                width: 200
                height: 100
                visible: false
                property int toggleEventCount: 0

                function dispatchShellEvent(eventType) {
                    if (eventType === "TOGGLE_CLICKED") {
                        toggleEventCount += 1
                    }
                }
            }
        )",
                          QUrl("inline:ToggleWindow.qml"));

        if (!component.isReady()) {
            QSKIP(qPrintable(QStringLiteral("QQml Window test harness unavailable: ")
                             + component.errorString()));
        }
        std::unique_ptr<QObject> object(component.create());
        if (object == nullptr) {
            QSKIP(qPrintable(QStringLiteral("QQml Window object creation unavailable: ")
                             + component.errorString()));
        }
        auto* window = qobject_cast<QWindow*>(object.get());
        QVERIFY(window != nullptr);

        WindowChromeViewModel viewModel(
            nullptr,
            [&sidebarToggleHandler](QWindow* trackedWindow,
                                    std::function<void()> toggle,
                                    std::function<void()> back,
                                    std::function<void()> forward) {
                Q_UNUSED(trackedWindow);
                Q_UNUSED(back);
                Q_UNUSED(forward);
                sidebarToggleHandler = std::move(toggle);
                return WindowChromeMetrics{ true, 78, 32 };
            });

        QSignalSpy toggleSpy(&viewModel, &WindowChromeViewModel::sidebarToggleRequested);

        viewModel.attach(window);

        QVERIFY(sidebarToggleHandler);
        QCOMPARE(object->property("toggleEventCount").toInt(), 0);

        sidebarToggleHandler();

        QCOMPARE(object->property("toggleEventCount").toInt(), 1);
        QCOMPARE(toggleSpy.count(), 0);
    }

    void attachBridgesSidebarToggleToVariantInvokableWindowMethod() {
        std::function<void()> sidebarToggleHandler;
        VariantInvokableTestWindow window;
        WindowChromeViewModel viewModel(
            nullptr,
            [&sidebarToggleHandler](QWindow* trackedWindow,
                                    std::function<void()> toggle,
                                    std::function<void()> back,
                                    std::function<void()> forward) {
                Q_UNUSED(trackedWindow);
                Q_UNUSED(back);
                Q_UNUSED(forward);
                sidebarToggleHandler = std::move(toggle);
                return WindowChromeMetrics{ true, 78, 32 };
            });

        QSignalSpy toggleSpy(&viewModel, &WindowChromeViewModel::sidebarToggleRequested);

        viewModel.attach(&window);

        QVERIFY(sidebarToggleHandler);
        QCOMPARE(window.toggleEventCount, 0);

        sidebarToggleHandler();

        QCOMPARE(window.toggleEventCount, 1);
        QCOMPARE(toggleSpy.count(), 0);
    }

    void attachBridgesBackToInvokableWindowMethodWithoutSignalFallback() {
        std::function<void()> backHandler;
        InvokableTestWindow window;
        WindowChromeViewModel viewModel(
            nullptr,
            [&backHandler](QWindow* trackedWindow,
                           std::function<void()> toggle,
                           std::function<void()> back,
                           std::function<void()> forward) {
                Q_UNUSED(trackedWindow);
                Q_UNUSED(toggle);
                Q_UNUSED(forward);
                backHandler = std::move(back);
                return WindowChromeMetrics{ true, 78, 32 };
            });

        QSignalSpy backSpy(&viewModel, &WindowChromeViewModel::backRequested);

        viewModel.attach(&window);

        QVERIFY(backHandler);
        QCOMPARE(window.backCount, 0);

        backHandler();

        QCOMPARE(window.backCount, 1);
        QCOMPARE(backSpy.count(), 0);
    }

    void attachBridgesForwardToInvokableWindowMethodWithoutSignalFallback() {
        std::function<void()> forwardHandler;
        InvokableTestWindow window;
        WindowChromeViewModel viewModel(
            nullptr,
            [&forwardHandler](QWindow* trackedWindow,
                              std::function<void()> toggle,
                              std::function<void()> back,
                              std::function<void()> forward) {
                Q_UNUSED(trackedWindow);
                Q_UNUSED(toggle);
                Q_UNUSED(back);
                forwardHandler = std::move(forward);
                return WindowChromeMetrics{ true, 78, 32 };
            });

        QSignalSpy forwardSpy(&viewModel, &WindowChromeViewModel::forwardRequested);

        viewModel.attach(&window);

        QVERIFY(forwardHandler);
        QCOMPARE(window.forwardCount, 0);

        forwardHandler();

        QCOMPARE(window.forwardCount, 1);
        QCOMPARE(forwardSpy.count(), 0);
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

    void toggleNativeFullscreenReturnsFalseWithoutTrackedWindow() {
        WindowChromeViewModel viewModel;

        QVERIFY(!viewModel.toggleNativeFullscreen());
    }

    void toggleNativeFullscreenUsesInjectedProviderForTrackedWindow() {
        int toggleCount = 0;
        QWindow window;
        WindowChromeViewModel viewModel(nullptr,
                                        fakeMetricsProvider,
                                        {},
                                        [&toggleCount, &window](QWindow* trackedWindow) {
                                            ++toggleCount;
                                            return trackedWindow == &window;
                                        });

        viewModel.attach(&window);

        QVERIFY(viewModel.toggleNativeFullscreen());
        QCOMPARE(toggleCount, 1);
    }

    void updateNativeToolbarStateUsesInjectedProviderForTrackedWindow() {
        int updateCount = 0;
        bool lastBackEnabled = false;
        bool lastForwardEnabled = false;
        QWindow window;
        WindowChromeViewModel viewModel(nullptr,
                                        fakeMetricsProvider,
                                        {},
                                        {},
                                        {},
                                        [&updateCount, &window, &lastBackEnabled,
                                         &lastForwardEnabled](QWindow* trackedWindow,
                                                              bool backEnabled,
                                                              bool forwardEnabled) {
                                            ++updateCount;
                                            QCOMPARE(trackedWindow, &window);
                                            lastBackEnabled = backEnabled;
                                            lastForwardEnabled = forwardEnabled;
                                        });

        viewModel.attach(&window);
        QCOMPARE(updateCount, 1);
        QCOMPARE(lastBackEnabled, false);
        QCOMPARE(lastForwardEnabled, false);
        viewModel.updateNativeToolbarState(true, false);

        QCOMPARE(updateCount, 2);
        QCOMPARE(lastBackEnabled, true);
        QCOMPARE(lastForwardEnabled, false);
    }

#ifdef Q_OS_MACOS
    void macWindowChromeDerivesDragRegionStartFromMeasuredSafeWidth() {
        MacWindowChrome chrome;

        const int baselineStartX = chrome.titleBarDragRegionStartXForMetrics(
            WindowChromeMetrics{ true, 78, 32 });
        const int widerStartX = chrome.titleBarDragRegionStartXForMetrics(
            WindowChromeMetrics{ true, 110, 32 });

        QCOMPARE(baselineStartX, 180);
        QVERIFY(widerStartX > baselineStartX);
    }

    void macWindowChromeClampsRunawaySafeWidthForDragRegion() {
        MacWindowChrome chrome;

        const int clampedStartX =
            chrome.titleBarDragRegionStartXForMetrics(WindowChromeMetrics{ true, 480, 32 });

        QCOMPARE(clampedStartX, 198);
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

    void macWindowChromeEnablesNativeFullscreenForNativeWindow() {
        if (QGuiApplication::platformName() != "cocoa") {
            QSKIP("Native fullscreen verification requires the cocoa platform plugin.");
        }

        if (QGuiApplication::screens().isEmpty()) {
            QSKIP("No screens available for native fullscreen verification.");
        }

        QWindow window;
        window.resize(640, 480);
        window.show();
        QVERIFY(QTest::qWaitForWindowExposed(&window));

        MacWindowChrome chrome;
        chrome.attach(&window);

        QVERIFY2(chrome.supportsNativeFullscreen(&window),
                 "AppShell native chrome should mark the window as full-screen capable so the green traffic-light keeps native fullscreen semantics.");
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

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
        if (QGuiApplication::screens().isEmpty()) {
            QSKIP("No screens available for QWindow creation.");
        }

        WindowChromeViewModel viewModel(nullptr, fakeMetricsProvider);
        QWindow window;

        QSignalSpy spy(&viewModel, &WindowChromeViewModel::metricsChanged);
        viewModel.attach(&window);

        QCOMPARE(viewModel.usesNativeTrafficLights(), true);
        QCOMPARE(viewModel.trafficLightsSafeWidth(), 78);
        QCOMPARE(viewModel.titleBarHeight(), 32);
        QCOMPARE(spy.count(), 1);
    }

#ifdef Q_OS_MACOS
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
    }
#endif
};

QTEST_MAIN(WindowChromeViewModelTest)

#include "tst_window_chrome_viewmodel.moc"

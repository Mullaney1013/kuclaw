#include <QApplication>
#include <QCoreApplication>
#include <QElapsedTimer>
#include <QPoint>
#include <QRect>
#include <QScreen>
#include <QThread>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <cstdio>
#include <algorithm>

#include "core/capture/ScreenCaptureManager.h"
#include "app/ApplicationCoordinator.h"
#include "core/common/Logger.h"
#include "core/common/SingleInstanceGuard.h"

namespace {

qint64 percentileUs(const QList<qint64>& samples, const double quantile) {
    if (samples.isEmpty()) {
        return 0;
    }

    QList<qint64> sorted = samples;
    std::sort(sorted.begin(), sorted.end());
    const int index = static_cast<int>(quantile * static_cast<double>(sorted.size() - 1));
    return sorted[qBound(0, index, sorted.size() - 1)];
}

void runHoverWindowBenchmarkMs(ScreenCaptureManager* manager) {
    if (manager == nullptr) {
        return;
    }

    const int durationMs = qEnvironmentVariableIntValue("KUCLAW_CAPTURE_HOVER_BENCH_MS", nullptr);
    const int intervalMs = qEnvironmentVariableIntValue("KUCLAW_CAPTURE_HOVER_BENCH_INTERVAL_MS", nullptr);
    const int sampleCountHint = qEnvironmentVariableIntValue("KUCLAW_CAPTURE_HOVER_BENCH_SAMPLES", nullptr);
    const int slaMs = qEnvironmentVariableIntValue("KUCLAW_CAPTURE_HOVER_LATENCY_SLA_MS", nullptr);

    const int targetSlaMs = slaMs > 0 ? slaMs : 50;

    const int targetDurationMs = durationMs > 0 ? durationMs : 200;
    const int targetIntervalMs = intervalMs > 0 ? intervalMs : 4;
    const int pointCountHint = sampleCountHint > 0 ? sampleCountHint : 80;

    QRect virtualGeometry;
    const QList<QScreen*> screens = QGuiApplication::screens();
    for (QScreen* screen : screens) {
        if (screen == nullptr) {
            continue;
        }
        virtualGeometry = virtualGeometry.united(screen->geometry());
    }

    if (!virtualGeometry.isValid() || virtualGeometry.isNull()) {
        fprintf(stderr, "[capture_perf] Hover benchmark skipped: unable to get valid virtual desktop geometry.\n");
        return;
    }

    QList<QPoint> points;
    points.reserve(pointCountHint);
    const int spanX = qMax(1, virtualGeometry.width() - 20);
    const int spanY = qMax(1, virtualGeometry.height() - 20);
    for (int i = 0; i < pointCountHint; ++i) {
        const int x = virtualGeometry.x() + 10 + (spanX * i) / qMax(1, pointCountHint - 1);
        const int y = virtualGeometry.y() + 10 + (spanY * i) / qMax(1, pointCountHint - 1);
        points << QPoint(x, y);
    }

    QList<qint64> latencies;
    QElapsedTimer durationTimer;
    durationTimer.start();
    int pointIndex = 0;

    while (durationTimer.elapsed() < targetDurationMs) {
        QRect ignoredRect;
        QElapsedTimer timer;
        timer.start();
        manager->hoveredWindowAt(points[pointIndex % points.size()], &ignoredRect, nullptr, nullptr);
        const qint64 durationUs = timer.nsecsElapsed() / 1000;
        latencies << durationUs;
        ++pointIndex;

        if (targetIntervalMs > 0) {
            QThread::msleep(static_cast<unsigned long>(targetIntervalMs));
        }
    }

    const qint64 p50 = percentileUs(latencies, 0.5);
    const qint64 p95 = percentileUs(latencies, 0.95);
    const qint64 max = latencies.isEmpty() ? 0 : *std::max_element(latencies.cbegin(), latencies.cend());
    const qint64 min = latencies.isEmpty() ? 0 : *std::min_element(latencies.cbegin(), latencies.cend());
    const qint64 slaUs = static_cast<qint64>(targetSlaMs) * 1000LL;
    const bool meetsSla = (p95 <= slaUs);
    const char* suggestion = meetsSla ? "PASS: within target."
                                      : "POTENTIAL_OPTIMIZE: cache window hit results by geometry / throttle scans.";

    fprintf(stderr,
            "[capture_perf] hoveredWindowAt benchmark: duration=%dms interval=%dms "
            "samples=%d p50=%lldus p95=%lldus min=%lldus max=%lldus "
            "sla=%dms meets=%s\n"
            "[capture_perf] suggestion: %s\n",
            targetDurationMs,
            targetIntervalMs,
            static_cast<int>(latencies.size()),
            p50,
            p95,
            min,
            max,
            targetSlaMs,
            meetsSla ? "yes" : "no",
            suggestion);
}

}  // namespace

int main(int argc, char* argv[]) {
    QCoreApplication::setOrganizationName("Kuclaw");
    QCoreApplication::setOrganizationDomain("kuclaw.local");
    QCoreApplication::setApplicationName("Kuclaw");

    QApplication app(argc, argv);
    app.setQuitOnLastWindowClosed(false);

    if (!qEnvironmentVariableIsEmpty("KUCLAW_CAPTURE_HOVER_BENCHMARK")) {
        ScreenCaptureManager manager;
        runHoverWindowBenchmarkMs(&manager);
        return 0;
    }

    SingleInstanceGuard singleInstanceGuard("kuclaw-desktop.lock");
    if (singleInstanceGuard.isAnotherInstanceRunning()) {
        Logger::warn("app", "Another Kuclaw instance is already running.");
        return 0;
    }

    ApplicationCoordinator coordinator;
    coordinator.initialize();

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("appCoordinator", &coordinator);
    engine.rootContext()->setContextProperty("captureViewModel", coordinator.captureViewModel());
    engine.rootContext()->setContextProperty("appLanguageViewModel",
                                             coordinator.appLanguageViewModel());
    engine.rootContext()->setContextProperty("colorHistoryViewModel", coordinator.colorHistoryViewModel());
    engine.rootContext()->setContextProperty("pinboardViewModel", coordinator.pinboardViewModel());
    engine.rootContext()->setContextProperty("settingsViewModel", coordinator.settingsViewModel());
    engine.rootContext()->setContextProperty("windowChromeViewModel",
                                             coordinator.windowChromeViewModel());

    QObject::connect(&app, &QCoreApplication::aboutToQuit,
                     &coordinator, &ApplicationCoordinator::shutdown);

    engine.loadFromModule("Kuclaw", "Main");
    if (engine.rootObjects().isEmpty()) {
        Logger::error("app", "Failed to load QML module Kuclaw.Main.");
        return -1;
    }

    return app.exec();
}

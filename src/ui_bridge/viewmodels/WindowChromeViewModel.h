#pragma once

#include <functional>

#include <QEvent>
#include <QObject>
#include <QPointer>
#include <QPlatformSurfaceEvent>
#include <QTimer>
#include <QWindow>

#include "integration/platform/MacWindowChrome.h"

class WindowChromeViewModel final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool usesNativeTrafficLights READ usesNativeTrafficLights NOTIFY metricsChanged)
    Q_PROPERTY(int trafficLightsSafeWidth READ trafficLightsSafeWidth NOTIFY metricsChanged)
    Q_PROPERTY(int titleBarHeight READ titleBarHeight NOTIFY metricsChanged)

public:
    using AttachFunction = std::function<WindowChromeMetrics(QWindow*)>;

    explicit WindowChromeViewModel(QObject* parent = nullptr,
                                   AttachFunction attachFunction = {});

    bool usesNativeTrafficLights() const;
    int trafficLightsSafeWidth() const;
    int titleBarHeight() const;

    Q_INVOKABLE void attach(QObject* windowObject);

signals:
    void metricsChanged();

protected:
    bool eventFilter(QObject* watched, QEvent* event) override;

private:
    void attachToWindow(QWindow* window);
    void tryAttach();
    void scheduleRetry();
    void resetRetryState();
    bool shouldRetry() const;
    void clearTrackedWindow();
    void setMetrics(const WindowChromeMetrics& metrics);

    AttachFunction attachFunction_;
    WindowChromeMetrics metrics_;
    QPointer<QWindow> trackedWindow_;
    QTimer retryTimer_;
    int retryAttempts_ = 0;
};

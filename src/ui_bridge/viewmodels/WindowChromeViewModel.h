#pragma once

#include <functional>

#include <QObject>

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

private:
    void setMetrics(const WindowChromeMetrics& metrics);

    AttachFunction attachFunction_;
    WindowChromeMetrics metrics_;
};

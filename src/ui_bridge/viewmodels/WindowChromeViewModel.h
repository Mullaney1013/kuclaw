#pragma once

#include <functional>

#include <QEvent>
#include <QObject>
#include <QPointer>
#include <QPlatformSurfaceEvent>
#include <QTimer>
#include <QVariant>
#include <QWindow>

#include "integration/platform/MacWindowChrome.h"

class WindowChromeViewModel final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool usesNativeTrafficLights READ usesNativeTrafficLights NOTIFY metricsChanged)
    Q_PROPERTY(int trafficLightsSafeWidth READ trafficLightsSafeWidth NOTIFY metricsChanged)
    Q_PROPERTY(int titleBarHeight READ titleBarHeight NOTIFY metricsChanged)

public:
    using AttachFunction = std::function<WindowChromeMetrics(
        QWindow*,
        std::function<void()>,
        std::function<void()>,
        std::function<void()>)>;
    using DragFunction = std::function<bool(QWindow*)>;
    using ToggleFullscreenFunction = std::function<bool(QWindow*)>;
    using DetachFunction = std::function<void(QWindow*, WId)>;
    using UpdateToolbarStateFunction = std::function<void(QWindow*, bool, bool)>;

    explicit WindowChromeViewModel(QObject* parent = nullptr,
                                   AttachFunction attachFunction = {},
                                   DragFunction dragFunction = {},
                                   ToggleFullscreenFunction toggleFullscreenFunction = {},
                                   DetachFunction detachFunction = {},
                                   UpdateToolbarStateFunction updateToolbarStateFunction = {});
    ~WindowChromeViewModel() override;

    bool usesNativeTrafficLights() const;
    int trafficLightsSafeWidth() const;
    int titleBarHeight() const;

    Q_INVOKABLE void attach(QObject* windowObject);
    Q_INVOKABLE bool beginSystemDrag();
    Q_INVOKABLE bool toggleNativeFullscreen();
    Q_INVOKABLE void updateNativeToolbarState(bool backEnabled, bool forwardEnabled);

signals:
    void metricsChanged();
    void sidebarToggleRequested();
    void backRequested();
    void forwardRequested();

protected:
    bool eventFilter(QObject* watched, QEvent* event) override;

private:
    void attachToWindow(QWindow* window);
    void tryAttach();
    void scheduleRetry();
    void resetRetryState();
    bool shouldRetry() const;
    void clearTrackedWindow(QWindow* detachWindow = nullptr, bool allowNativeDetach = true);
    void setMetrics(const WindowChromeMetrics& metrics);
    void detachNativeChrome(QWindow* window, WId nativeId);
    bool invokeTrackedWindowMethod(const char* method);
    bool invokeTrackedWindowMethod(const char* method, const QVariant& argument);
    void notifySidebarToggleRequested();
    void notifyBackRequested();
    void notifyForwardRequested();

    AttachFunction attachFunction_;
    DragFunction dragFunction_;
    ToggleFullscreenFunction toggleFullscreenFunction_;
    DetachFunction detachFunction_;
    UpdateToolbarStateFunction updateToolbarStateFunction_;
    MacWindowChrome chrome_;
    WindowChromeMetrics metrics_;
    QPointer<QWindow> trackedWindow_;
    QWindow* nativeChromeDetachWindow_ = nullptr;
    WId nativeChromeDetachId_ = 0;
    QTimer retryTimer_;
    int retryAttempts_ = 0;
    bool nativeChromeAttached_ = false;
    bool ownsNativeChromeAttachment_ = false;
    bool nativeBackEnabled_ = false;
    bool nativeForwardEnabled_ = false;
};

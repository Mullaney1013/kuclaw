#pragma once

#include <QObject>
#include <QEvent>
#include <QTimer>

#include "core/annotation/AnnotationManager.h"
#include "core/capture/CaptureCoordinator.h"
#include "core/capture/CaptureSessionController.h"
#include "core/capture/ScreenCaptureManager.h"
#include "core/clipboard/ClipboardManager.h"
#include "core/hotkey/HotkeyManager.h"
#include "core/pin/PinWindowManager.h"
#include "core/settings/SettingsManager.h"
#include "core/tray/TrayManager.h"
#include "ui_bridge/viewmodels/CaptureViewModel.h"
#include "ui_bridge/viewmodels/ColorHistoryViewModel.h"
#include "ui_bridge/viewmodels/PinboardViewModel.h"
#include "ui_bridge/viewmodels/SettingsViewModel.h"
#include "ui_bridge/viewmodels/WindowChromeViewModel.h"

class ApplicationCoordinator final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool captureInProgress READ captureInProgress NOTIFY captureInProgressChanged)
    Q_PROPERTY(QString captureBackend READ captureBackend CONSTANT)

public:
    explicit ApplicationCoordinator(QObject* parent = nullptr);

    void initialize();

    bool captureInProgress() const;
    QString captureBackend() const;
    CaptureViewModel* captureViewModel();
    ColorHistoryViewModel* colorHistoryViewModel();
    PinboardViewModel* pinboardViewModel();
    SettingsViewModel* settingsViewModel();
    WindowChromeViewModel* windowChromeViewModel();

public slots:
    void beginCapture();
    void pinFromClipboard();
    void hideAllPins();
    void restoreLastClosedPin();
    void shutdown();

signals:
    void captureStarted();
    void captureFinished();
    void captureInProgressChanged();
    void reopenRequested();
    void fatalErrorOccurred(const QString& message);

private:
    bool eventFilter(QObject* watched, QEvent* event) override;
    bool shouldHandleGlobalEscape() const;
    void suppressReopenOnce();
    void wireSignals();

    SettingsManager settingsManager_;
    ClipboardManager clipboardManager_;
    AnnotationManager annotationManager_;
    ScreenCaptureManager screenCaptureManager_;
    CaptureSessionController captureSessionController_;
    CaptureCoordinator captureCoordinator_;
    PinWindowManager pinWindowManager_;
    HotkeyManager hotkeyManager_;
    TrayManager trayManager_;
    CaptureViewModel captureViewModel_;
    ColorHistoryViewModel colorHistoryViewModel_;
    PinboardViewModel pinboardViewModel_;
    SettingsViewModel settingsViewModel_;
    WindowChromeViewModel windowChromeViewModel_;
    QTimer reopenSuppressionTimer_;
    bool suppressNextReopen_ = false;
    bool initialized_ = false;
};

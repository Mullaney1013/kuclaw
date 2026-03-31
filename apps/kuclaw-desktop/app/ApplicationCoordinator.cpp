#include "app/ApplicationCoordinator.h"

#include <QApplication>
#include <QCoreApplication>
#include <QKeyEvent>
#include <QtGlobal>

#include "core/capture/CaptureCoordinator.h"
#include "core/capture/NativeScreenHelperFactory.h"
#include "core/common/Logger.h"

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
#include "integration/platform/MacHotkeyRegistrar.h"
#elif defined(Q_OS_WIN)
#include "integration/platform/WinHotkeyRegistrar.h"
#else
#include "integration/platform/NoopHotkeyRegistrar.h"
#endif

ApplicationCoordinator::ApplicationCoordinator(QObject* parent)
    : QObject(parent),
      captureSessionController_(&screenCaptureManager_, &clipboardManager_, &annotationManager_, this),
      captureCoordinator_(createNativeScreenHelper(), &clipboardManager_, &settingsManager_, this),
      pinWindowManager_(&clipboardManager_, this),
      hotkeyManager_(
          std::unique_ptr<IHotkeyRegistrar>(
              #if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
              new MacHotkeyRegistrar()
              #elif defined(Q_OS_WIN)
              new WinHotkeyRegistrar()
              #else
              new NoopHotkeyRegistrar()
              #endif
          ),
          &settingsManager_,
          this),
      trayManager_(this),
      captureViewModel_(&captureSessionController_, this),
      colorHistoryViewModel_(&clipboardManager_, this),
      pinboardViewModel_(&pinWindowManager_, this),
      settingsViewModel_(&settingsManager_, this),
      windowChromeViewModel_(this) {
    reopenSuppressionTimer_.setSingleShot(true);
    reopenSuppressionTimer_.setInterval(1200);
    connect(&reopenSuppressionTimer_, &QTimer::timeout, this, [this]() {
        suppressNextReopen_ = false;
    });
}

bool ApplicationCoordinator::captureInProgress() const {
    return captureCoordinator_.isCaptureActive();
}

QString ApplicationCoordinator::captureBackend() const {
    return captureCoordinator_.backendName();
}

void ApplicationCoordinator::initialize() {
    if (initialized_) {
        return;
    }

    wireSignals();
    trayManager_.show();
    hotkeyManager_.registerDefaults();
    QCoreApplication::instance()->installEventFilter(this);
    initialized_ = true;

    Logger::info("app", "ApplicationCoordinator initialized.");
}

CaptureViewModel* ApplicationCoordinator::captureViewModel() {
    return &captureViewModel_;
}

ColorHistoryViewModel* ApplicationCoordinator::colorHistoryViewModel() {
    return &colorHistoryViewModel_;
}

PinboardViewModel* ApplicationCoordinator::pinboardViewModel() {
    return &pinboardViewModel_;
}

SettingsViewModel* ApplicationCoordinator::settingsViewModel() {
    return &settingsViewModel_;
}

WindowChromeViewModel* ApplicationCoordinator::windowChromeViewModel() {
    return &windowChromeViewModel_;
}

void ApplicationCoordinator::beginCapture() {
    captureCoordinator_.triggerCapture();
}

void ApplicationCoordinator::pinFromClipboard() {
    pinWindowManager_.createPinFromClipboard();
}

void ApplicationCoordinator::hideAllPins() {
    pinWindowManager_.hideAllPins();
}

void ApplicationCoordinator::restoreLastClosedPin() {
    pinWindowManager_.restoreLastClosedPin();
}

void ApplicationCoordinator::shutdown() {
    if (!initialized_) {
        return;
    }

    QCoreApplication::instance()->removeEventFilter(this);
    hotkeyManager_.unregisterAll();
    trayManager_.hide();
    initialized_ = false;
    Logger::info("app", "ApplicationCoordinator shut down.");
}

bool ApplicationCoordinator::eventFilter(QObject* /*watched*/, QEvent* event) {
    if (event == nullptr) {
        return false;
    }

    if ((event->type() == QEvent::ApplicationActivate
         || event->type() == QEvent::ApplicationStateChange)
        && qApp->applicationState() == Qt::ApplicationActive
        && !captureCoordinator_.isCaptureActive()) {
        if (suppressNextReopen_) {
            return false;
        }
        emit reopenRequested();
    }

    if (!shouldHandleGlobalEscape() || event->type() != QEvent::KeyPress) {
        return false;
    }

    const auto* keyEvent = static_cast<const QKeyEvent*>(event);
    if (keyEvent->key() == Qt::Key_Escape) {
        captureCoordinator_.cancelCapture();
        return true;
    }

    return false;
}

bool ApplicationCoordinator::shouldHandleGlobalEscape() const {
    return captureCoordinator_.isCaptureActive();
}

void ApplicationCoordinator::suppressReopenOnce() {
    suppressNextReopen_ = true;
    reopenSuppressionTimer_.start();
}

void ApplicationCoordinator::wireSignals() {
    connect(&trayManager_, &TrayManager::captureRequested,
            this, &ApplicationCoordinator::beginCapture);
    connect(&trayManager_, &TrayManager::pinRequested,
            this, &ApplicationCoordinator::pinFromClipboard);
    connect(&trayManager_, &TrayManager::restoreLastClosedPinRequested,
            this, &ApplicationCoordinator::restoreLastClosedPin);
    connect(&trayManager_, &TrayManager::hideAllPinsRequested,
            this, &ApplicationCoordinator::hideAllPins);
    connect(&trayManager_, &TrayManager::quitRequested,
            qApp, &QCoreApplication::quit);

    connect(&hotkeyManager_, &HotkeyManager::hotkeyTriggered, this,
            [this](const QString& id) {
                if (id == "capture.start") {
                    beginCapture();
                } else if (id == "pin.create") {
                    pinFromClipboard();
                } else if (id == "pin.hide_all") {
                    hideAllPins();
                }
            });

    connect(&hotkeyManager_, &HotkeyManager::registrationFailed, this,
            [this](const QString& id, const QString& reason) {
                const QString message = QString("Failed to register hotkey %1: %2").arg(id, reason);
                Logger::warn("hotkey", message);
                emit fatalErrorOccurred(message);
            });

    connect(&captureCoordinator_, &CaptureCoordinator::captureActiveChanged, this,
            [this]() {
                emit captureInProgressChanged();
                if (captureCoordinator_.isCaptureActive()) {
                    emit captureStarted();
                }
            });

    connect(&captureCoordinator_, &CaptureCoordinator::captureCompleted, this,
            [this](const SelectionResult&, const QImage&) {
                emit captureFinished();
            });

    connect(&captureCoordinator_, &CaptureCoordinator::colorCopied, this,
            [this](const QString& colorValue,
                   const QString& swatchHex,
                   const QPoint& globalPoint) {
                colorHistoryViewModel_.recordCopiedColor(colorValue,
                                                         swatchHex,
                                                         globalPoint.x(),
                                                         globalPoint.y());
            });

    connect(&captureCoordinator_, &CaptureCoordinator::captureCanceling, this,
            [this]() {
                suppressReopenOnce();
            });

    connect(&captureCoordinator_, &CaptureCoordinator::captureCompleting, this,
            [this]() {
                suppressReopenOnce();
            });

    connect(&captureCoordinator_, &CaptureCoordinator::captureError, this,
            [this](const QString& message) {
                Logger::warn("capture", message);
                emit fatalErrorOccurred(message);
            });
}

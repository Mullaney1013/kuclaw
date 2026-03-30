#include "core/hotkey/HotkeyManager.h"
#include "core/settings/SettingsManager.h"

HotkeyManager::HotkeyManager(std::unique_ptr<IHotkeyRegistrar> registrar,
                             SettingsManager* settingsManager,
                             QObject* parent)
    : QObject(parent),
      registrar_(std::move(registrar)),
      settingsManager_(settingsManager) {
    if (registrar_ != nullptr) {
        registrar_->setHotkeyTriggeredCallback([this](const QString& id) {
            emit hotkeyTriggered(id);
        });
    }
}

bool HotkeyManager::registerDefaults() {
    const QKeySequence captureSequence =
        settingsManager_ == nullptr ? QKeySequence("F1")
                                   : settingsManager_->captureHotkey();
    const QKeySequence pinSequence =
        settingsManager_ == nullptr ? QKeySequence("F3")
                                   : settingsManager_->pinHotkey();

    bool ok = true;
    ok = registerHotkey("capture.start", captureSequence) && ok;
    ok = registerHotkey("pin.create", pinSequence) && ok;
    ok = registerHotkey("pin.hide_all", QKeySequence("Shift+F3")) && ok;
    return ok;
}

bool HotkeyManager::registerHotkey(const QString& id, const QKeySequence& sequence) {
    if (registrar_ == nullptr) {
        emit registrationFailed(id, "No hotkey registrar available.");
        return false;
    }

    const bool success = registrar_->registerHotkey(id, sequence);
    if (!success) {
        emit registrationFailed(id, registrar_->lastError());
        return false;
    }

    return true;
}

void HotkeyManager::unregisterAll() {
    if (registrar_ != nullptr) {
        registrar_->unregisterAll();
    }
}

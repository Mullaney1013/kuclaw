#include "ui_bridge/viewmodels/SettingsViewModel.h"

#include "core/settings/SettingsManager.h"

SettingsViewModel::SettingsViewModel(SettingsManager* settingsManager,
                                     QObject* parent)
    : QObject(parent),
      settingsManager_(settingsManager) {}

QString SettingsViewModel::captureHotkey() const {
    return settingsManager_->captureHotkey().toString();
}

QString SettingsViewModel::pinHotkey() const {
    return settingsManager_->pinHotkey().toString();
}

bool SettingsViewModel::keepCurrentWindowOnCapture() const {
    return settingsManager_->keepCurrentWindowOnCapture();
}

bool SettingsViewModel::magnifierEnabled() const {
    return settingsManager_->magnifierEnabled();
}

QString SettingsViewModel::defaultColorFormat() const {
    return settingsManager_->defaultColorFormat();
}

QString SettingsViewModel::defaultSaveDirectory() const {
    return settingsManager_->defaultSaveDirectory();
}

void SettingsViewModel::setKeepCurrentWindowOnCapture(bool enabled) {
    if (settingsManager_->keepCurrentWindowOnCapture() == enabled) {
        return;
    }

    settingsManager_->setValue("capture/keepCurrentWindowOnCapture", enabled);
    emit settingsChanged();
}

void SettingsViewModel::setMagnifierEnabled(bool enabled) {
    if (settingsManager_->magnifierEnabled() == enabled) {
        return;
    }

    settingsManager_->setValue("capture/magnifierEnabled", enabled);
    emit settingsChanged();
}

void SettingsViewModel::setDefaultColorFormat(const QString& format) {
    const QString normalized = format.trimmed().toUpper();
    const QString nextFormat =
        normalized == QStringLiteral("HEX") ? QStringLiteral("HEX")
                                            : QStringLiteral("RGB");
    if (settingsManager_->defaultColorFormat() == nextFormat) {
        return;
    }

    settingsManager_->setValue("capture/defaultColorFormat", nextFormat);
    emit settingsChanged();
}

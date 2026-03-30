#include "core/settings/SettingsManager.h"

#include <QStandardPaths>

SettingsManager::SettingsManager(QObject* parent)
    : QObject(parent),
      settings_() {}

QVariant SettingsManager::value(const QString& key, const QVariant& defaultValue) const {
    return settings_.value(key, defaultValue);
}

void SettingsManager::setValue(const QString& key, const QVariant& value) {
    settings_.setValue(key, value);
}

QKeySequence SettingsManager::captureHotkey() const {
    return value("hotkeys/capture", QKeySequence("F1")).value<QKeySequence>();
}

QKeySequence SettingsManager::pinHotkey() const {
    return value("hotkeys/pin", QKeySequence("F3")).value<QKeySequence>();
}

bool SettingsManager::keepCurrentWindowOnCapture() const {
    return value("capture/keepCurrentWindowOnCapture", true).toBool();
}

bool SettingsManager::magnifierEnabled() const {
    return value("capture/magnifierEnabled", true).toBool();
}

QString SettingsManager::defaultColorFormat() const {
    return value("capture/defaultColorFormat", QStringLiteral("RGB")).toString().toUpper();
}

QString SettingsManager::defaultSaveDirectory() const {
    return value("capture/defaultSaveDirectory",
                 QStandardPaths::writableLocation(QStandardPaths::PicturesLocation)).toString();
}

int SettingsManager::closedPinRestoreLimit() const {
    return value("pin/closedRestoreLimit", 1).toInt();
}

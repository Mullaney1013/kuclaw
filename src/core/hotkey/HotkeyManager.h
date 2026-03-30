#pragma once

#include <memory>

#include <QObject>
#include <QKeySequence>

#include "core/hotkey/IHotkeyRegistrar.h"

class SettingsManager;

class HotkeyManager final : public QObject {
    Q_OBJECT

public:
    explicit HotkeyManager(std::unique_ptr<IHotkeyRegistrar> registrar,
                           SettingsManager* settingsManager,
                           QObject* parent = nullptr);

    bool registerDefaults();
    bool registerHotkey(const QString& id, const QKeySequence& sequence);
    void unregisterAll();

signals:
    void hotkeyTriggered(const QString& id);
    void registrationFailed(const QString& id, const QString& reason);

private:
    std::unique_ptr<IHotkeyRegistrar> registrar_;
    SettingsManager* settingsManager_ = nullptr;
};

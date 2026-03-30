#pragma once

#include <QKeySequence>
#include <QString>
#include <functional>

class IHotkeyRegistrar {
public:
    virtual ~IHotkeyRegistrar() = default;

    using HotkeyCallback = std::function<void(const QString&)>;

    virtual bool registerHotkey(const QString& id, const QKeySequence& sequence) = 0;
    virtual void unregisterHotkey(const QString& id) = 0;
    virtual void unregisterAll() = 0;
    virtual QString lastError() const = 0;
    virtual void setHotkeyTriggeredCallback(HotkeyCallback callback) = 0;
};

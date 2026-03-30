#pragma once

#include <QHash>

#include "core/hotkey/IHotkeyRegistrar.h"

class NoopHotkeyRegistrar final : public IHotkeyRegistrar {
public:
    bool registerHotkey(const QString& id, const QKeySequence& sequence) override;
    void unregisterHotkey(const QString& id) override;
    void unregisterAll() override;
    QString lastError() const override;
    void setHotkeyTriggeredCallback(HotkeyCallback callback) override;

private:
    QHash<QString, QKeySequence> registeredHotkeys_;
    QString lastError_;
    HotkeyCallback callback_;
};

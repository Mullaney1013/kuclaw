#pragma once

#include <QAbstractNativeEventFilter>
#include <QHash>
#include <QKeySequence>
#include <QString>

#include "core/hotkey/IHotkeyRegistrar.h"

class WinHotkeyRegistrar final : public IHotkeyRegistrar, public QAbstractNativeEventFilter {
public:
    WinHotkeyRegistrar();
    ~WinHotkeyRegistrar() override;

    bool registerHotkey(const QString& id, const QKeySequence& sequence) override;
    void unregisterHotkey(const QString& id) override;
    void unregisterAll() override;
    QString lastError() const override;
    void setHotkeyTriggeredCallback(HotkeyCallback callback) override;
    bool nativeEventFilter(const QByteArray& eventType, void* message, qintptr* result) override;

private:
    struct HotkeyRegistration {
        int nativeId = 0;
        QKeySequence sequence;
    };

    bool ensureInstalled();
    bool parseSequence(const QKeySequence& sequence,
                       unsigned int& modifiers,
                       unsigned int& vkCode,
                       QString& errorMessage) const;

    QHash<QString, HotkeyRegistration> registrations_;
    QHash<int, QString> idByNativeId_;
    QString lastError_;
    HotkeyCallback callback_;
    int nextNativeId_ = 1;
    bool installed_ = false;
};

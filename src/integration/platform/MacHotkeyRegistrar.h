#pragma once

#include <QHash>
#include <QKeySequence>
#include <QString>

#include "core/hotkey/IHotkeyRegistrar.h"

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
#include <Carbon/Carbon.h>
#endif

class MacHotkeyRegistrar final : public IHotkeyRegistrar {
public:
    MacHotkeyRegistrar();
    ~MacHotkeyRegistrar() override;

    bool registerHotkey(const QString& id, const QKeySequence& sequence) override;
    void unregisterHotkey(const QString& id) override;
    void unregisterAll() override;
    QString lastError() const override;
    void setHotkeyTriggeredCallback(HotkeyCallback callback) override;

private:
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    using HotKeyRef = EventHotKeyRef;
#else
    using HotKeyRef = void*;
#endif

    bool parseSequence(const QKeySequence& sequence,
                       unsigned int& keyCode,
                       unsigned int& modifierMask,
                       QString& errorMessage);
    bool ensureEventHandlerInstalled();
    void clear();
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    static OSStatus eventHandler(EventHandlerCallRef nextHandler, EventRef event, void* userData);
#endif

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    QHash<QString, HotKeyRef> hotkeys_;
    QHash<int, QString> idByNumericId_;
    QHash<QString, int> numericIdByHotkeyId_;
#else
    QHash<QString, HotKeyRef> hotkeys_;
    QHash<int, QString> idByNumericId_;
    QHash<QString, int> numericIdByHotkeyId_;
#endif
    QString lastError_;
    HotkeyCallback callback_;
    int nextHotKeyId_ = 1;
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    EventHandlerRef eventHandlerRef_ = nullptr;
#else
    void* eventHandlerRef_ = nullptr;
#endif
};

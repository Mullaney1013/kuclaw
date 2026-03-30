#include "integration/platform/MacHotkeyRegistrar.h"

#include <QKeySequence>
#include <QString>

MacHotkeyRegistrar::MacHotkeyRegistrar() = default;

MacHotkeyRegistrar::~MacHotkeyRegistrar() {
    clear();
}

bool MacHotkeyRegistrar::registerHotkey(const QString& id, const QKeySequence& sequence) {
    lastError_.clear();

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    unsigned int keyCode = 0;
    unsigned int modifierMask = 0;
    QString errorMessage;
    if (!parseSequence(sequence, keyCode, modifierMask, errorMessage)) {
        lastError_ = errorMessage;
        return false;
    }

    if (!ensureEventHandlerInstalled()) {
        return false;
    }

    if (hotkeys_.contains(id)) {
        unregisterHotkey(id);
    }

    const EventHotKeyID eventId{
        'KCLU',
        static_cast<UInt32>(nextHotKeyId_),
    };

    EventHotKeyRef hotKeyRef = nullptr;
    const OSStatus status = RegisterEventHotKey(
        static_cast<UInt32>(keyCode),
        static_cast<UInt32>(modifierMask),
        eventId,
        GetApplicationEventTarget(),
        0,
        &hotKeyRef);

    if (status != noErr) {
        lastError_ = QString("RegisterEventHotKey failed: %1").arg(status);
        return false;
    }

    hotkeys_[id] = hotKeyRef;
    idByNumericId_[nextHotKeyId_] = id;
    numericIdByHotkeyId_[id] = nextHotKeyId_;
    ++nextHotKeyId_;
    return true;
#else
    Q_UNUSED(id);
    Q_UNUSED(sequence);
    lastError_ = "Unsupported platform for native hotkey registration.";
    return false;
#endif
}

void MacHotkeyRegistrar::unregisterHotkey(const QString& id) {
    if (!hotkeys_.contains(id)) {
        return;
    }

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    const auto ref = hotkeys_.value(id, nullptr);
    if (ref != nullptr) {
        UnregisterEventHotKey(ref);
    }
#else
    Q_UNUSED(id);
#endif

    const int numericId = numericIdByHotkeyId_.value(id, -1);
    hotkeys_.remove(id);
    numericIdByHotkeyId_.remove(id);
    if (numericId >= 0) {
        idByNumericId_.remove(numericId);
    }
}

void MacHotkeyRegistrar::unregisterAll() {
    clear();
}

QString MacHotkeyRegistrar::lastError() const {
    return lastError_;
}

void MacHotkeyRegistrar::setHotkeyTriggeredCallback(HotkeyCallback callback) {
    callback_ = std::move(callback);
}

void MacHotkeyRegistrar::clear() {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    for (auto it = hotkeys_.constBegin(); it != hotkeys_.constEnd(); ++it) {
        if (it.value() != nullptr) {
            UnregisterEventHotKey(it.value());
        }
    }

    if (eventHandlerRef_ != nullptr) {
        RemoveEventHandler(eventHandlerRef_);
        eventHandlerRef_ = nullptr;
    }
#else
    Q_UNUSED(this);
#endif
    hotkeys_.clear();
    idByNumericId_.clear();
    numericIdByHotkeyId_.clear();
}

bool MacHotkeyRegistrar::parseSequence(const QKeySequence& sequence,
                                      unsigned int& keyCode,
                                      unsigned int& modifierMask,
                                      QString& errorMessage) {
    errorMessage.clear();
    keyCode = 0;
    modifierMask = 0;

    const QStringList parts = sequence.toString(QKeySequence::PortableText).split('+', Qt::SkipEmptyParts);
    if (parts.isEmpty()) {
        errorMessage = "Empty hotkey sequence.";
        return false;
    }

    const QString keyText = parts.constLast();
    if (keyText == u"F1") {
        keyCode = 0x7A;
    } else if (keyText == u"F2") {
        keyCode = 0x78;
    } else if (keyText == u"F3") {
        keyCode = 0x63;
    } else if (keyText == u"Esc" || keyText == u"Escape") {
        keyCode = 0x35;
    } else {
        errorMessage = QString("Unsupported hotkey key: %1").arg(keyText);
        return false;
    }

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    for (int i = 0; i < parts.size() - 1; ++i) {
        if (parts[i] == u"Shift") {
            modifierMask |= shiftKey;
        } else if (parts[i] == u"Ctrl") {
            modifierMask |= controlKey;
        } else if (parts[i] == u"Alt") {
            modifierMask |= optionKey;
        } else if (parts[i] == u"Meta" || parts[i] == u"Cmd" || parts[i] == u"Command") {
            modifierMask |= cmdKey;
        } else if (!parts[i].isEmpty()) {
            // Ignore unknown modifiers in user-configurable sequence for now.
        }
    }
#endif

    return true;
}

bool MacHotkeyRegistrar::ensureEventHandlerInstalled() {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (eventHandlerRef_ != nullptr) {
        return true;
    }

    EventTypeSpec typeSpec{kEventClassKeyboard, kEventHotKeyPressed};
    const EventHandlerUPP handler = NewEventHandlerUPP(MacHotkeyRegistrar::eventHandler);
    const OSStatus status = InstallEventHandler(
        GetApplicationEventTarget(),
        handler,
        1,
        &typeSpec,
        this,
        &eventHandlerRef_);

    if (status != noErr) {
        lastError_ = QString("InstallEventHandler failed: %1").arg(status);
        return false;
    }

    return true;
#else
    return false;
#endif
}

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
OSStatus MacHotkeyRegistrar::eventHandler(EventHandlerCallRef nextHandler, EventRef event, void* userData) {
    Q_UNUSED(nextHandler);
    if (userData == nullptr) {
        return noErr;
    }

    auto* self = static_cast<MacHotkeyRegistrar*>(userData);
    EventHotKeyID hotkeyID;
    OSStatus status = GetEventParameter(event, kEventParamDirectObject, typeEventHotKeyID,
                                        nullptr, sizeof(EventHotKeyID), nullptr, &hotkeyID);
    if (status != noErr) {
        return status;
    }

    const auto it = self->idByNumericId_.find(hotkeyID.id);
    if (it == self->idByNumericId_.end()) {
        return noErr;
    }

    if (self->callback_) {
        self->callback_(it.value());
    }
    return noErr;
}
#endif

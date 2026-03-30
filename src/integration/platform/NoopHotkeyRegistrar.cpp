#include "integration/platform/NoopHotkeyRegistrar.h"

bool NoopHotkeyRegistrar::registerHotkey(const QString& id, const QKeySequence& sequence) {
    registeredHotkeys_.insert(id, sequence);
    lastError_.clear();
    return true;
}

void NoopHotkeyRegistrar::setHotkeyTriggeredCallback(HotkeyCallback callback) {
    callback_ = std::move(callback);
}

void NoopHotkeyRegistrar::unregisterHotkey(const QString& id) {
    registeredHotkeys_.remove(id);
}

void NoopHotkeyRegistrar::unregisterAll() {
    registeredHotkeys_.clear();
}

QString NoopHotkeyRegistrar::lastError() const {
    return lastError_;
}

#include "integration/platform/WinHotkeyRegistrar.h"

#include <QAbstractEventDispatcher>
#include <QCoreApplication>
#include <QStringList>

#if defined(Q_OS_WIN)
#include <windows.h>

namespace {

bool parseFunctionKeyToken(const QString& token, unsigned int& vkCode) {
    if (!token.startsWith(u'F')) {
        return false;
    }

    bool ok = false;
    const int number = token.mid(1).toInt(&ok);
    if (!ok || number < 1 || number > 24) {
        return false;
    }

    vkCode = static_cast<unsigned int>(VK_F1 + (number - 1));
    return true;
}

bool parseNamedVirtualKey(const QString& token, unsigned int& vkCode) {
    const QString normalized = token.trimmed().toUpper();
    if (normalized.isEmpty()) {
        return false;
    }

    if (normalized.size() == 1) {
        const ushort ch = normalized.at(0).unicode();
        if (ch >= 'A' && ch <= 'Z') {
            vkCode = ch;
            return true;
        }
        if (ch >= '0' && ch <= '9') {
            vkCode = ch;
            return true;
        }
    }

    if (parseFunctionKeyToken(normalized, vkCode)) {
        return true;
    }

    static const QHash<QString, unsigned int> keyMap = {
        {QStringLiteral("ESC"), VK_ESCAPE},
        {QStringLiteral("ESCAPE"), VK_ESCAPE},
        {QStringLiteral("TAB"), VK_TAB},
        {QStringLiteral("SPACE"), VK_SPACE},
        {QStringLiteral("SPACEBAR"), VK_SPACE},
        {QStringLiteral("ENTER"), VK_RETURN},
        {QStringLiteral("RETURN"), VK_RETURN},
        {QStringLiteral("BACKSPACE"), VK_BACK},
        {QStringLiteral("BS"), VK_BACK},
        {QStringLiteral("INS"), VK_INSERT},
        {QStringLiteral("INSERT"), VK_INSERT},
        {QStringLiteral("DEL"), VK_DELETE},
        {QStringLiteral("DELETE"), VK_DELETE},
        {QStringLiteral("HOME"), VK_HOME},
        {QStringLiteral("END"), VK_END},
        {QStringLiteral("PGUP"), VK_PRIOR},
        {QStringLiteral("PAGEUP"), VK_PRIOR},
        {QStringLiteral("PGDN"), VK_NEXT},
        {QStringLiteral("PAGEDOWN"), VK_NEXT},
        {QStringLiteral("LEFT"), VK_LEFT},
        {QStringLiteral("RIGHT"), VK_RIGHT},
        {QStringLiteral("UP"), VK_UP},
        {QStringLiteral("DOWN"), VK_DOWN},
        {QStringLiteral("CAPSLOCK"), VK_CAPITAL},
        {QStringLiteral("PRINT"), VK_SNAPSHOT},
        {QStringLiteral("PRINTSCREEN"), VK_SNAPSHOT},
        {QStringLiteral("PAUSE"), VK_PAUSE},
        {QStringLiteral("MENU"), VK_APPS},
    };

    const auto it = keyMap.constFind(normalized);
    if (it == keyMap.constEnd()) {
        return false;
    }

    vkCode = it.value();
    return true;
}

}  // namespace

#endif

WinHotkeyRegistrar::WinHotkeyRegistrar() = default;

WinHotkeyRegistrar::~WinHotkeyRegistrar() {
    unregisterAll();

    if (installed_ && QCoreApplication::instance() != nullptr) {
        QCoreApplication::instance()->removeNativeEventFilter(this);
    }
}

bool WinHotkeyRegistrar::registerHotkey(const QString& id, const QKeySequence& sequence) {
    lastError_.clear();

#if defined(Q_OS_WIN)
    if (!ensureInstalled()) {
        return false;
    }

    unsigned int modifiers = 0;
    unsigned int vkCode = 0;
    QString errorMessage;
    if (!parseSequence(sequence, modifiers, vkCode, errorMessage)) {
        lastError_ = errorMessage;
        return false;
    }

    if (registrations_.contains(id)) {
        unregisterHotkey(id);
    }

    const int nativeId = nextNativeId_++;
    if (!RegisterHotKey(nullptr, nativeId, modifiers | MOD_NOREPEAT, vkCode)) {
        lastError_ = QStringLiteral("RegisterHotKey failed: %1").arg(GetLastError());
        return false;
    }

    registrations_.insert(id, {nativeId, sequence});
    idByNativeId_.insert(nativeId, id);
    return true;
#else
    Q_UNUSED(id);
    Q_UNUSED(sequence);
    lastError_ = QStringLiteral("Unsupported platform for RegisterHotKey.");
    return false;
#endif
}

void WinHotkeyRegistrar::unregisterHotkey(const QString& id) {
#if defined(Q_OS_WIN)
    const auto it = registrations_.find(id);
    if (it == registrations_.end()) {
        return;
    }

    UnregisterHotKey(nullptr, it->nativeId);
    idByNativeId_.remove(it->nativeId);
    registrations_.erase(it);
#else
    Q_UNUSED(id);
#endif
}

void WinHotkeyRegistrar::unregisterAll() {
    const QStringList ids = registrations_.keys();
    for (const QString& id : ids) {
        unregisterHotkey(id);
    }
}

QString WinHotkeyRegistrar::lastError() const {
    return lastError_;
}

void WinHotkeyRegistrar::setHotkeyTriggeredCallback(HotkeyCallback callback) {
    callback_ = std::move(callback);
}

bool WinHotkeyRegistrar::nativeEventFilter(const QByteArray& eventType,
                                           void* message,
                                           qintptr* result) {
    Q_UNUSED(result);

#if defined(Q_OS_WIN)
    if (eventType != "windows_generic_MSG" && eventType != "windows_dispatcher_MSG") {
        return false;
    }

    auto* msg = static_cast<MSG*>(message);
    if (msg == nullptr || msg->message != WM_HOTKEY) {
        return false;
    }

    const int nativeId = static_cast<int>(msg->wParam);
    const auto it = idByNativeId_.find(nativeId);
    if (it == idByNativeId_.end()) {
        return false;
    }

    if (callback_) {
        callback_(it.value());
    }
    return true;
#else
    Q_UNUSED(eventType);
    Q_UNUSED(message);
    return false;
#endif
}

bool WinHotkeyRegistrar::ensureInstalled() {
    if (installed_) {
        return true;
    }

    if (QCoreApplication::instance() == nullptr) {
        lastError_ = QStringLiteral("QCoreApplication is not initialized.");
        return false;
    }

    QCoreApplication::instance()->installNativeEventFilter(this);
    installed_ = true;
    return true;
}

bool WinHotkeyRegistrar::parseSequence(const QKeySequence& sequence,
                                       unsigned int& modifiers,
                                       unsigned int& vkCode,
                                       QString& errorMessage) const {
    modifiers = 0;
    vkCode = 0;
    errorMessage.clear();

    if (sequence.count() != 1) {
        errorMessage = QStringLiteral("Windows 全局热键不支持多段组合，请使用单段快捷键。");
        return false;
    }

    const QStringList parts =
        sequence.toString(QKeySequence::PortableText).split('+', Qt::SkipEmptyParts);
    if (parts.isEmpty()) {
        errorMessage = QStringLiteral("Empty hotkey sequence.");
        return false;
    }

#if defined(Q_OS_WIN)
    for (int index = 0; index < parts.size() - 1; ++index) {
        const QString token = parts.at(index).trimmed();
        if (token == u"Shift") {
            modifiers |= MOD_SHIFT;
        } else if (token == u"Ctrl") {
            modifiers |= MOD_CONTROL;
        } else if (token == u"Alt") {
            modifiers |= MOD_ALT;
        } else if (token == u"Meta" || token == u"Win") {
            modifiers |= MOD_WIN;
        } else if (!token.isEmpty()) {
            errorMessage = QStringLiteral("Unsupported hotkey modifier: %1").arg(token);
            return false;
        }
    }

    const QString keyText = parts.constLast().trimmed();
    if (!parseNamedVirtualKey(keyText, vkCode)) {
        errorMessage = QStringLiteral("Unsupported hotkey key: %1").arg(keyText);
        return false;
    }
#else
    Q_UNUSED(parts);
#endif

    return true;
}

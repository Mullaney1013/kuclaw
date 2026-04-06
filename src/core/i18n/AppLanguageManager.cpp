#include "core/i18n/AppLanguageManager.h"

#include <QLocale>

#include "core/settings/SettingsManager.h"

namespace {
constexpr auto kEnglishLocale = "en_US";
constexpr auto kChineseLocale = "zh_CN";
}

AppLanguageManager::AppLanguageManager(SettingsManager* settingsManager, QObject* parent)
    : QObject(parent),
      settingsManager_(settingsManager) {}

QString AppLanguageManager::currentLocale() const {
    return currentLocale_;
}

QStringList AppLanguageManager::supportedLocales() const {
    return {QString::fromLatin1(kEnglishLocale), QString::fromLatin1(kChineseLocale)};
}

QString AppLanguageManager::resolveInitialLocale(const QLocale& systemLocale) const {
    return systemLocale.name() == QString::fromLatin1(kChineseLocale)
               ? QString::fromLatin1(kChineseLocale)
               : QString::fromLatin1(kEnglishLocale);
}

QString AppLanguageManager::effectiveLocale(const QLocale& systemLocale) const {
    if (settingsManager_ != nullptr) {
        const QString savedLocale = settingsManager_->appLanguage();
        if (isSupportedLocale(savedLocale)) {
            return savedLocale;
        }
    }

    return resolveInitialLocale(systemLocale);
}

bool AppLanguageManager::setCurrentLocale(const QString& localeCode) {
    if (!isSupportedLocale(localeCode)) {
        return false;
    }

    if (currentLocale_ == localeCode) {
        return true;
    }

    currentLocale_ = localeCode;
    if (settingsManager_ != nullptr) {
        settingsManager_->setAppLanguage(localeCode);
    }

    emit currentLocaleChanged();
    return true;
}

bool AppLanguageManager::initialize() {
    const QString localeCode = effectiveLocale(QLocale::system());
    if (!isSupportedLocale(localeCode)) {
        return false;
    }

    if (currentLocale_ == localeCode) {
        return true;
    }

    currentLocale_ = localeCode;
    emit currentLocaleChanged();
    return true;
}

bool AppLanguageManager::isSupportedLocale(const QString& localeCode) const {
    return localeCode == QString::fromLatin1(kEnglishLocale)
           || localeCode == QString::fromLatin1(kChineseLocale);
}

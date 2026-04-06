#include "core/i18n/AppLanguageManager.h"

#include <QCoreApplication>
#include <QGuiApplication>
#include <QLocale>
#include <QTranslator>

#include "core/settings/SettingsManager.h"

namespace {
constexpr auto kEnglishLocale = "en_US";
constexpr auto kChineseLocale = "zh_CN";

QString translationResourcePath(const QString& localeCode) {
    return QStringLiteral(":/translations/kuclaw_%1.qm").arg(localeCode);
}
}

AppLanguageManager::AppLanguageManager(SettingsManager* settingsManager, QObject* parent)
    : QObject(parent),
      settingsManager_(settingsManager),
      app_(qobject_cast<QGuiApplication*>(QCoreApplication::instance())),
      translator_(new QTranslator(this)) {}

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
    return applyLocale(localeCode, true);
}

bool AppLanguageManager::initialize() {
    return applyLocale(effectiveLocale(QLocale::system()), false);
}

bool AppLanguageManager::applyLocale(const QString& localeCode, const bool persistSelection) {
    if (!isSupportedLocale(localeCode) || app_ == nullptr || translator_ == nullptr) {
        return false;
    }

    app_->removeTranslator(translator_);
    if (!translator_->load(translationResourcePath(localeCode))) {
        return false;
    }
    app_->installTranslator(translator_);

    const bool localeChanged = currentLocale_ != localeCode;
    currentLocale_ = localeCode;
    if (persistSelection && settingsManager_ != nullptr) {
        settingsManager_->setAppLanguage(localeCode);
    }
    if (localeChanged) {
        emit currentLocaleChanged();
    }

    return true;
}

bool AppLanguageManager::isSupportedLocale(const QString& localeCode) const {
    return localeCode == QString::fromLatin1(kEnglishLocale)
           || localeCode == QString::fromLatin1(kChineseLocale);
}

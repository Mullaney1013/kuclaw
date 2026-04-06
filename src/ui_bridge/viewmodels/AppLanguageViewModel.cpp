#include "ui_bridge/viewmodels/AppLanguageViewModel.h"

#include "core/i18n/AppLanguageManager.h"

AppLanguageViewModel::AppLanguageViewModel(AppLanguageManager* languageManager,
                                           QObject* parent)
    : QObject(parent),
      languageManager_(languageManager) {
    if (languageManager_ != nullptr) {
        connect(languageManager_, &AppLanguageManager::currentLocaleChanged,
                this, &AppLanguageViewModel::currentLocaleChanged);
    }
}

QString AppLanguageViewModel::currentLocale() const {
    return languageManager_ != nullptr ? languageManager_->currentLocale() : QString();
}

QStringList AppLanguageViewModel::supportedLocales() const {
    return languageManager_ != nullptr ? languageManager_->supportedLocales() : QStringList{};
}

void AppLanguageViewModel::selectLocale(const QString& localeCode) {
    if (languageManager_ == nullptr) {
        return;
    }

    languageManager_->setCurrentLocale(localeCode);
}

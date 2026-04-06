#include <QtTest>

#include "core/i18n/AppLanguageManager.h"
#include "core/settings/SettingsManager.h"
#include "ui_bridge/viewmodels/AppLanguageViewModel.h"

class AppLanguageManagerTest final : public QObject {
    Q_OBJECT

private slots:
    void initTestCase() {
        QCoreApplication::setOrganizationName(QStringLiteral("Kuclaw"));
        QCoreApplication::setOrganizationDomain(QStringLiteral("kuclaw.local"));
        QCoreApplication::setApplicationName(QStringLiteral("Kuclaw"));
    }

    void settingsManagerPersistsExplicitLanguage() {
        {
            SettingsManager settings;
            settings.clearForTesting();
        }

        {
            SettingsManager settings;
            QCOMPARE(settings.appLanguage().isEmpty(), true);

            settings.setAppLanguage(QStringLiteral("zh_CN"));
        }

        {
            SettingsManager settings;
            QCOMPARE(settings.appLanguage(), QStringLiteral("zh_CN"));

            settings.setAppLanguage(QStringLiteral("en_US"));
        }

        {
            SettingsManager settings;
            QCOMPARE(settings.appLanguage(), QStringLiteral("en_US"));
        }
    }

    void resolvesFirstLaunchFromSupportedSystemLocale() {
        SettingsManager settings;
        settings.clearForTesting();
        AppLanguageManager languageManager(&settings);

        QCOMPARE(languageManager.resolveInitialLocale(QLocale(QStringLiteral("zh_CN"))),
                 QStringLiteral("zh_CN"));
        QCOMPARE(languageManager.resolveInitialLocale(QLocale(QStringLiteral("en_US"))),
                 QStringLiteral("en_US"));
    }

    void fallsBackToEnglishForUnsupportedSystemLocale() {
        SettingsManager settings;
        settings.clearForTesting();
        AppLanguageManager languageManager(&settings);

        QCOMPARE(languageManager.resolveInitialLocale(QLocale(QStringLiteral("ja_JP"))),
                 QStringLiteral("en_US"));
    }

    void persistedLanguageOverridesSystemLocale() {
        SettingsManager settings;
        settings.clearForTesting();
        settings.setAppLanguage(QStringLiteral("zh_CN"));
        AppLanguageManager languageManager(&settings);

        QCOMPARE(languageManager.effectiveLocale(QLocale(QStringLiteral("en_US"))),
                 QStringLiteral("zh_CN"));
    }

    void initializeUsesSystemDefaultWithoutPersistingPreference() {
        SettingsManager settings;
        settings.clearForTesting();
        AppLanguageManager languageManager(&settings);

        const QString expectedLocale = languageManager.effectiveLocale(QLocale::system());
        QVERIFY(languageManager.initialize());
        QCOMPARE(languageManager.currentLocale(), expectedLocale);
        QCOMPARE(settings.appLanguage().isEmpty(), true);
        QCOMPARE(QCoreApplication::translate("AppLanguageProbe",
                                             "Settings language probe"),
                 expectedLocale == QStringLiteral("zh_CN")
                     ? QStringLiteral("设置语言探针")
                     : QStringLiteral("Settings language probe"));
    }

    void setCurrentLocalePersistsExplicitChoice() {
        SettingsManager settings;
        settings.clearForTesting();
        AppLanguageManager languageManager(&settings);

        QVERIFY(languageManager.setCurrentLocale(QStringLiteral("zh_CN")));
        QCOMPARE(languageManager.currentLocale(), QStringLiteral("zh_CN"));
        QCOMPARE(settings.appLanguage(), QStringLiteral("zh_CN"));
        QCOMPARE(QCoreApplication::translate("AppLanguageProbe",
                                             "Settings language probe"),
                 QStringLiteral("设置语言探针"));

        QVERIFY(languageManager.setCurrentLocale(QStringLiteral("en_US")));
        QCOMPARE(QCoreApplication::translate("AppLanguageProbe",
                                             "Settings language probe"),
                 QStringLiteral("Settings language probe"));
    }

    void viewModelReflectsCurrentLocaleAndCanSwitch() {
        SettingsManager settings;
        settings.clearForTesting();
        AppLanguageManager languageManager(&settings);
        AppLanguageViewModel viewModel(&languageManager);

        QVERIFY(languageManager.setCurrentLocale(QStringLiteral("en_US")));
        QCOMPARE(viewModel.currentLocale(), QStringLiteral("en_US"));
        QCOMPARE(QCoreApplication::translate("AppLanguageProbe",
                                             "Settings language probe"),
                 QStringLiteral("Settings language probe"));

        viewModel.selectLocale(QStringLiteral("zh_CN"));
        QCOMPARE(viewModel.currentLocale(), QStringLiteral("zh_CN"));
        QCOMPARE(settings.appLanguage(), QStringLiteral("zh_CN"));
        QCOMPARE(QCoreApplication::translate("AppLanguageProbe",
                                             "Settings language probe"),
                 QStringLiteral("设置语言探针"));
    }
};

QTEST_MAIN(AppLanguageManagerTest)
#include "tst_app_language_manager.moc"

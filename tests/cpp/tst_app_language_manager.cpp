#include <QtTest>

#include "core/settings/SettingsManager.h"

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
};

QTEST_MAIN(AppLanguageManagerTest)
#include "tst_app_language_manager.moc"

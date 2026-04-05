#include <QtTest>

#include "core/settings/SettingsManager.h"

class AppLanguageManagerTest final : public QObject {
    Q_OBJECT

private slots:
    void settingsManagerPersistsExplicitLanguage() {
        SettingsManager settings;
        settings.clearForTesting();

        QCOMPARE(settings.appLanguage().isEmpty(), true);

        settings.setAppLanguage(QStringLiteral("zh_CN"));
        QCOMPARE(settings.appLanguage(), QStringLiteral("zh_CN"));

        settings.setAppLanguage(QStringLiteral("en_US"));
        QCOMPARE(settings.appLanguage(), QStringLiteral("en_US"));
    }
};

QTEST_MAIN(AppLanguageManagerTest)
#include "tst_app_language_manager.moc"

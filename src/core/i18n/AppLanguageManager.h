#pragma once

#include <QObject>
#include <QLocale>
#include <QStringList>

class SettingsManager;

class AppLanguageManager final : public QObject {
    Q_OBJECT

public:
    explicit AppLanguageManager(SettingsManager* settingsManager,
                                QObject* parent = nullptr);

    QString currentLocale() const;
    QStringList supportedLocales() const;
    QString resolveInitialLocale(const QLocale& systemLocale) const;
    QString effectiveLocale(const QLocale& systemLocale) const;
    bool setCurrentLocale(const QString& localeCode);
    bool initialize();

signals:
    void currentLocaleChanged();

private:
    bool isSupportedLocale(const QString& localeCode) const;

    SettingsManager* settingsManager_ = nullptr;
    QString currentLocale_;
};

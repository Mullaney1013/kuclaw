#pragma once

#include <QObject>
#include <QStringList>

class AppLanguageManager;

class AppLanguageViewModel final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentLocale READ currentLocale NOTIFY currentLocaleChanged)
    Q_PROPERTY(QStringList supportedLocales READ supportedLocales CONSTANT)

public:
    explicit AppLanguageViewModel(AppLanguageManager* languageManager,
                                  QObject* parent = nullptr);

    QString currentLocale() const;
    QStringList supportedLocales() const;

    Q_INVOKABLE void selectLocale(const QString& localeCode);

signals:
    void currentLocaleChanged();

private:
    AppLanguageManager* languageManager_ = nullptr;
};

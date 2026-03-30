#pragma once

#include <QObject>

class SettingsManager;

class SettingsViewModel final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString captureHotkey READ captureHotkey NOTIFY settingsChanged)
    Q_PROPERTY(QString pinHotkey READ pinHotkey NOTIFY settingsChanged)
    Q_PROPERTY(bool keepCurrentWindowOnCapture READ keepCurrentWindowOnCapture WRITE setKeepCurrentWindowOnCapture NOTIFY settingsChanged)
    Q_PROPERTY(bool magnifierEnabled READ magnifierEnabled WRITE setMagnifierEnabled NOTIFY settingsChanged)
    Q_PROPERTY(QString defaultColorFormat READ defaultColorFormat WRITE setDefaultColorFormat NOTIFY settingsChanged)
    Q_PROPERTY(QString defaultSaveDirectory READ defaultSaveDirectory NOTIFY settingsChanged)

public:
    explicit SettingsViewModel(SettingsManager* settingsManager,
                               QObject* parent = nullptr);

    QString captureHotkey() const;
    QString pinHotkey() const;
    bool keepCurrentWindowOnCapture() const;
    bool magnifierEnabled() const;
    QString defaultColorFormat() const;
    QString defaultSaveDirectory() const;
    Q_INVOKABLE void setKeepCurrentWindowOnCapture(bool enabled);
    Q_INVOKABLE void setMagnifierEnabled(bool enabled);
    Q_INVOKABLE void setDefaultColorFormat(const QString& format);

signals:
    void settingsChanged();

private:
    SettingsManager* settingsManager_ = nullptr;
};

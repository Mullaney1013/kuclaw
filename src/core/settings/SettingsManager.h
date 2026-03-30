#pragma once

#include <QObject>
#include <QSettings>
#include <QVariant>
#include <QKeySequence>

class SettingsManager final : public QObject {
    Q_OBJECT

public:
    explicit SettingsManager(QObject* parent = nullptr);

    QVariant value(const QString& key,
                   const QVariant& defaultValue = {}) const;
    void setValue(const QString& key, const QVariant& value);

    QKeySequence captureHotkey() const;
    QKeySequence pinHotkey() const;
    bool keepCurrentWindowOnCapture() const;
    bool magnifierEnabled() const;
    QString defaultColorFormat() const;
    QString defaultSaveDirectory() const;
    int closedPinRestoreLimit() const;

private:
    QSettings settings_;
};

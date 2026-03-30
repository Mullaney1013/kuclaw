#pragma once

#include <QObject>

class PinWindowManager;

class PinboardViewModel final : public QObject {
    Q_OBJECT
    Q_PROPERTY(int pinCount READ pinCount NOTIFY pinCountChanged)
    Q_PROPERTY(QString lastCreatedPinId READ lastCreatedPinId NOTIFY lastCreatedPinIdChanged)

public:
    explicit PinboardViewModel(PinWindowManager* pinWindowManager,
                               QObject* parent = nullptr);

    int pinCount() const;
    QString lastCreatedPinId() const;

    Q_INVOKABLE void pinFromClipboard();
    Q_INVOKABLE void hideAllPins();
    Q_INVOKABLE void restoreLastClosed();

signals:
    void pinCountChanged();
    void lastCreatedPinIdChanged();

private:
    PinWindowManager* pinWindowManager_ = nullptr;
    QString lastCreatedPinId_;
};

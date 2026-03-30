#pragma once

#include <QHash>
#include <QObject>

#include "domain/models/ClipboardPayload.h"
#include "domain/models/PinItem.h"

class ClipboardManager;

class PinWindowManager final : public QObject {
    Q_OBJECT

public:
    explicit PinWindowManager(ClipboardManager* clipboardManager,
                              QObject* parent = nullptr);

    Q_INVOKABLE QString createPinFromClipboard();
    QString createPin(const ClipboardPayload& payload);
    QString createPinFromImage(const QImage& image);
    Q_INVOKABLE void closePin(const QString& pinId);
    Q_INVOKABLE void destroyPin(const QString& pinId);
    Q_INVOKABLE void restoreLastClosedPin();
    Q_INVOKABLE void hideAllPins();
    Q_INVOKABLE void showAllPins();
    Q_INVOKABLE void setPinOpacity(const QString& pinId, qreal opacity);
    Q_INVOKABLE void setPinScale(const QString& pinId, qreal scale);
    Q_INVOKABLE void togglePassthrough(const QString& pinId);

    int pinCount() const;

signals:
    void pinCreated(const QString& pinId);
    void pinClosed(const QString& pinId);
    void pinDestroyed(const QString& pinId);
    void pinsChanged();

private:
    QImage buildTextImage(const QString& text) const;
    QImage buildColorImage(const QColor& color) const;

    ClipboardManager* clipboardManager_ = nullptr;
    QHash<QString, PinItem> pins_;
    QHash<QString, PinItem> closedPins_;
    QStringList pinOrder_;
    QStringList closedOrder_;
};

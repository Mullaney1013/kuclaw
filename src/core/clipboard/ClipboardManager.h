#pragma once

#include <QObject>

#include "domain/models/ClipboardPayload.h"

class QClipboard;
class QMimeData;

class ClipboardManager final : public QObject {
    Q_OBJECT

public:
    explicit ClipboardManager(QObject* parent = nullptr);

    ClipboardPayload currentPayload() const;
    void setImage(const QImage& image);
    void setText(const QString& text);

signals:
    void clipboardChanged(const ClipboardPayload& payload);

private:
    ClipboardPayload parseMimeData(const QMimeData* mimeData) const;

    QClipboard* clipboard_ = nullptr;
};

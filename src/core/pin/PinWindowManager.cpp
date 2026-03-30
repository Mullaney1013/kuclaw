#include "core/pin/PinWindowManager.h"

#include <QDateTime>
#include <QPainter>
#include <QtGlobal>
#include <QUuid>

#include "core/clipboard/ClipboardManager.h"

PinWindowManager::PinWindowManager(ClipboardManager* clipboardManager,
                                   QObject* parent)
    : QObject(parent),
      clipboardManager_(clipboardManager) {}

QString PinWindowManager::createPinFromClipboard() {
    return createPin(clipboardManager_->currentPayload());
}

QString PinWindowManager::createPin(const ClipboardPayload& payload) {
    PinItem item;
    item.pinId = QUuid::createUuid().toString(QUuid::WithoutBraces);
    item.createdAt = QDateTime::currentDateTime();

    switch (payload.type) {
    case ClipboardPayloadType::Image:
        item.contentType = PinContentType::Image;
        item.image = payload.image;
        item.title = "Clipboard Image";
        break;
    case ClipboardPayloadType::Color:
        item.contentType = PinContentType::Color;
        item.image = buildColorImage(payload.color);
        item.title = payload.color.name(QColor::HexRgb);
        break;
    case ClipboardPayloadType::Text:
    case ClipboardPayloadType::Html:
    case ClipboardPayloadType::FileList:
        item.contentType = PinContentType::Text;
        item.image = buildTextImage(!payload.text.isEmpty()
                                        ? payload.text
                                        : payload.filePaths.join("\n"));
        item.title = "Clipboard Text";
        break;
    case ClipboardPayloadType::Unknown:
    default:
        return {};
    }

    if (item.image.isNull()) {
        return {};
    }

    pins_.insert(item.pinId, item);
    pinOrder_.append(item.pinId);
    emit pinCreated(item.pinId);
    emit pinsChanged();
    return item.pinId;
}

QString PinWindowManager::createPinFromImage(const QImage& image) {
    ClipboardPayload payload;
    payload.type = ClipboardPayloadType::Image;
    payload.source = ClipboardSource::CaptureResult;
    payload.image = image;
    return createPin(payload);
}

void PinWindowManager::closePin(const QString& pinId) {
    if (!pins_.contains(pinId)) {
        return;
    }

    closedPins_.insert(pinId, pins_.take(pinId));
    pinOrder_.removeAll(pinId);
    closedOrder_.append(pinId);
    emit pinClosed(pinId);
    emit pinsChanged();
}

void PinWindowManager::destroyPin(const QString& pinId) {
    pins_.remove(pinId);
    closedPins_.remove(pinId);
    pinOrder_.removeAll(pinId);
    closedOrder_.removeAll(pinId);
    emit pinDestroyed(pinId);
    emit pinsChanged();
}

void PinWindowManager::restoreLastClosedPin() {
    if (closedOrder_.isEmpty()) {
        return;
    }

    const QString pinId = closedOrder_.takeLast();
    pins_.insert(pinId, closedPins_.take(pinId));
    pinOrder_.append(pinId);
    emit pinsChanged();
}

void PinWindowManager::hideAllPins() {
    for (auto it = pins_.begin(); it != pins_.end(); ++it) {
        it->isHidden = true;
    }
    emit pinsChanged();
}

void PinWindowManager::showAllPins() {
    for (auto it = pins_.begin(); it != pins_.end(); ++it) {
        it->isHidden = false;
    }
    emit pinsChanged();
}

void PinWindowManager::setPinOpacity(const QString& pinId, qreal opacity) {
    if (!pins_.contains(pinId)) {
        return;
    }

    pins_[pinId].opacity = qBound<qreal>(0.1, opacity, 1.0);
    emit pinsChanged();
}

void PinWindowManager::setPinScale(const QString& pinId, qreal scale) {
    if (!pins_.contains(pinId)) {
        return;
    }

    pins_[pinId].scale = qMax<qreal>(0.1, scale);
    emit pinsChanged();
}

void PinWindowManager::togglePassthrough(const QString& pinId) {
    if (!pins_.contains(pinId)) {
        return;
    }

    pins_[pinId].isPassthrough = !pins_[pinId].isPassthrough;
    emit pinsChanged();
}

int PinWindowManager::pinCount() const {
    return pins_.size();
}

QImage PinWindowManager::buildTextImage(const QString& text) const {
    QImage image(360, 140, QImage::Format_ARGB32_Premultiplied);
    image.fill(QColor("#FFF8D9"));

    QPainter painter(&image);
    painter.setRenderHint(QPainter::Antialiasing);
    painter.setPen(QColor("#1C1C1C"));
    painter.drawRect(image.rect().adjusted(0, 0, -1, -1));
    painter.drawText(image.rect().adjusted(16, 16, -16, -16),
                     Qt::TextWordWrap | Qt::AlignLeft | Qt::AlignTop,
                     text.isEmpty() ? QStringLiteral("Clipboard payload") : text);
    return image;
}

QImage PinWindowManager::buildColorImage(const QColor& color) const {
    QImage image(220, 120, QImage::Format_ARGB32_Premultiplied);
    image.fill(color);

    QPainter painter(&image);
    painter.setPen(color.lightness() > 128 ? Qt::black : Qt::white);
    painter.drawText(image.rect(), Qt::AlignCenter, color.name(QColor::HexRgb));
    return image;
}

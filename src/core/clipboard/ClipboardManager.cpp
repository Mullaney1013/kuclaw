#include "core/clipboard/ClipboardManager.h"

#include <QClipboard>
#include <QGuiApplication>
#include <QMimeData>
#include <QUrl>

namespace {

bool tryParseColor(const QString& text, QColor* color) {
    const QColor parsed(text.trimmed());
    if (!parsed.isValid()) {
        return false;
    }

    *color = parsed;
    return true;
}

}  // namespace

ClipboardManager::ClipboardManager(QObject* parent)
    : QObject(parent),
      clipboard_(QGuiApplication::clipboard()) {
    connect(clipboard_, &QClipboard::changed, this, [this]() {
        emit clipboardChanged(currentPayload());
    });
}

ClipboardPayload ClipboardManager::currentPayload() const {
    return parseMimeData(clipboard_->mimeData());
}

void ClipboardManager::setImage(const QImage& image) {
    clipboard_->setImage(image);
}

void ClipboardManager::setText(const QString& text) {
    clipboard_->setText(text);
}

ClipboardPayload ClipboardManager::parseMimeData(const QMimeData* mimeData) const {
    ClipboardPayload payload;

    if (mimeData == nullptr) {
        return payload;
    }

    payload.mimeTypes = mimeData->formats();

    if (mimeData->hasImage()) {
        payload.type = ClipboardPayloadType::Image;
        payload.image = qvariant_cast<QImage>(mimeData->imageData());
        return payload;
    }

    if (mimeData->hasUrls()) {
        payload.type = ClipboardPayloadType::FileList;
        for (const QUrl& url : mimeData->urls()) {
            payload.filePaths.append(url.toLocalFile());
        }
        return payload;
    }

    if (mimeData->hasHtml()) {
        payload.type = ClipboardPayloadType::Html;
        payload.html = mimeData->html();
        payload.text = mimeData->text();
        return payload;
    }

    if (mimeData->hasText()) {
        payload.text = mimeData->text();

        QColor parsedColor;
        if (tryParseColor(payload.text, &parsedColor)) {
            payload.type = ClipboardPayloadType::Color;
            payload.color = parsedColor;
        } else {
            payload.type = ClipboardPayloadType::Text;
        }
    }

    return payload;
}

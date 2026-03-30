#pragma once

#include <QColor>
#include <QImage>
#include <QString>
#include <QStringList>

enum class ClipboardPayloadType {
    Unknown,
    Image,
    Text,
    Html,
    Color,
    FileList
};

enum class ClipboardSource {
    Clipboard,
    CaptureResult,
    DragDrop
};

struct ClipboardPayload {
    ClipboardPayloadType type = ClipboardPayloadType::Unknown;
    ClipboardSource source = ClipboardSource::Clipboard;
    QImage image;
    QString text;
    QString html;
    QColor color;
    QStringList filePaths;
    QStringList mimeTypes;
};

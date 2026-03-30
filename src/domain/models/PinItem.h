#pragma once

#include <QDateTime>
#include <QImage>
#include <QString>

enum class PinContentType {
    Image,
    Text,
    Color,
    Unknown
};

struct PinItem {
    QString pinId;
    PinContentType contentType = PinContentType::Unknown;
    QImage image;
    QString title;
    qreal opacity = 1.0;
    qreal scale = 1.0;
    qreal rotation = 0.0;
    bool isPassthrough = false;
    bool isHidden = false;
    bool canRestore = true;
    QDateTime createdAt = QDateTime::currentDateTime();
};

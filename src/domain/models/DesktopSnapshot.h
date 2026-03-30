#pragma once

#include <QImage>
#include <QList>
#include <QRect>
#include <QString>

struct DesktopScreenInfo {
    QString screenId;
    QRect geometry;
    qreal devicePixelRatio = 1.0;
};

struct DesktopSnapshot {
    QImage image;
    QRect virtualGeometry;
    QList<DesktopScreenInfo> screens;
};

#pragma once

#include <QObject>
#include <QColor>
#include <QImage>
#include <QPoint>
#include <QRect>
#include <QtGlobal>

#include "domain/models/DesktopSnapshot.h"

class ScreenCaptureManager final : public QObject {
    Q_OBJECT

public:
    explicit ScreenCaptureManager(QObject* parent = nullptr);

    DesktopSnapshot captureDesktop() const;
    QImage captureRegion(const QRect& logicalRect) const;
    QColor sampleColor(const QPoint& logicalPoint) const;
    QImage buildMagnifierImage(const QPoint& logicalPoint,
                               int radius,
                               int scaleFactor) const;
    bool hoveredWindowAt(const QPoint& logicalPoint,
                         QRect* windowBounds = nullptr,
                         qint64* handle = nullptr,
                         bool* visible = nullptr) const;
};

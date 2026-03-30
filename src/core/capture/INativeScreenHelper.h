#pragma once

#include <QImage>
#include <QRect>
#include <QString>
#include <QVector>

struct WindowCandidate {
    QRect overlayRect;
    QRect nativeRect;
    quint64 nativeId = 0;
    QString ownerAppName;
    QString windowTitle;
    int zIndex = 0;
    bool valid = false;
};

struct CaptureDisplaySegment {
    QRect logicalRect;
    QRect pixelRect;
};

struct CaptureResult {
    QImage frozenDesktop;
    QRect virtualDesktopRect;
    qreal deviceScaleHint = 1.0;
    QVector<CaptureDisplaySegment> displaySegments;
};

struct SelectionResult {
    QRect overlayRect;
    QRect globalLogicalRect;
    QRect nativeRect;
    quint64 nativeId = 0;
    QString ownerAppName;
    QString windowTitle;
    bool canceled = false;
};

class INativeScreenHelper {
public:
    virtual ~INativeScreenHelper() = default;

    virtual bool ensurePermissions(QString* errorMessage) = 0;
    virtual CaptureResult captureFrozenDesktop() = 0;
    virtual QVector<WindowCandidate> enumerateWindowCandidates(const QRect& virtualDesktopRect) = 0;
    virtual QString backendName() const = 0;
};

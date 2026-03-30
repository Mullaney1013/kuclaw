#pragma once

#include <QPoint>
#include <QRect>
#include <QString>
#include <QVector>

#include "core/capture/INativeScreenHelper.h"

#if defined(Q_OS_WIN)
#include <windows.h>
#else
struct tagPOINT {
    long x = 0;
    long y = 0;
};
struct tagRECT {
    long left = 0;
    long top = 0;
    long right = 0;
    long bottom = 0;
};
#endif

class NativeScreenHelperWin final : public INativeScreenHelper {
public:
    NativeScreenHelperWin();
    ~NativeScreenHelperWin() override;

    bool ensurePermissions(QString* errorMessage) override;
    CaptureResult captureFrozenDesktop() override;
    QVector<WindowCandidate> enumerateWindowCandidates(const QRect& virtualDesktopRect) override;
    QString backendName() const override;

private:
    struct MonitorDescriptor {
        QString deviceName;
        QRect logicalRect;
        qreal scale = 1.0;
        tagRECT physicalRect{};
    };

    QVector<MonitorDescriptor> buildMonitorMap() const;
    QPoint physicalToLogical(const tagPOINT& point) const;
    QRect nativeRectToLogical(const tagRECT& rect) const;

    QVector<MonitorDescriptor> monitors_;
    QRect virtualDesktopRect_;
};

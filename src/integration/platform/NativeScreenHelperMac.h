#pragma once

#include <memory>

#include "core/capture/INativeScreenHelper.h"

class NativeScreenHelperMacPrivate;

class NativeScreenHelperMac final : public INativeScreenHelper {
public:
    NativeScreenHelperMac();
    ~NativeScreenHelperMac() override;

    bool ensurePermissions(QString* errorMessage) override;
    CaptureResult captureFrozenDesktop() override;
    QVector<WindowCandidate> enumerateWindowCandidates(const QRect& virtualDesktopRect) override;
    QString backendName() const override;

private:
    std::unique_ptr<NativeScreenHelperMacPrivate> d;
};

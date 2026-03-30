#include "core/capture/NativeScreenHelperFactory.h"

#include <memory>

#include "core/capture/INativeScreenHelper.h"

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
#include "integration/platform/NativeScreenHelperMac.h"
#elif defined(Q_OS_WIN)
#include "integration/platform/NativeScreenHelperWin.h"
#endif

namespace {

class NullNativeScreenHelper final : public INativeScreenHelper {
public:
    bool ensurePermissions(QString* errorMessage) override {
        if (errorMessage != nullptr) {
            *errorMessage = QStringLiteral("当前平台未接入冻结式截图后端。");
        }
        return false;
    }

    CaptureResult captureFrozenDesktop() override {
        return {};
    }

    QVector<WindowCandidate> enumerateWindowCandidates(const QRect& virtualDesktopRect) override {
        Q_UNUSED(virtualDesktopRect);
        return {};
    }

    QString backendName() const override {
        return QStringLiteral("null");
    }
};

}  // namespace

std::unique_ptr<INativeScreenHelper> createNativeScreenHelper() {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    return std::make_unique<NativeScreenHelperMac>();
#elif defined(Q_OS_WIN)
    return std::make_unique<NativeScreenHelperWin>();
#else
    return std::make_unique<NullNativeScreenHelper>();
#endif
}

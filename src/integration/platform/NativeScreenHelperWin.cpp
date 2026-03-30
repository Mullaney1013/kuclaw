#include "integration/platform/NativeScreenHelperWin.h"

#if defined(Q_OS_WIN)

#include <windows.h>
#include <dwmapi.h>

#include <QFileInfo>
#include <QGuiApplication>
#include <QImage>
#include <QPainter>
#include <QPixmap>
#include <QScreen>
#include <string>

namespace {

bool isZeroRect(const RECT& rect) {
    return rect.left >= rect.right || rect.top >= rect.bottom;
}

QRect qRectFromRECT(const RECT& rect) {
    return QRect(rect.left,
                 rect.top,
                 qMax(1L, rect.right - rect.left),
                 qMax(1L, rect.bottom - rect.top));
}

QString processNameForPid(const DWORD processId) {
    if (processId == 0) {
        return {};
    }

    HANDLE processHandle = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, processId);
    if (processHandle == nullptr) {
        return {};
    }

    std::wstring processPath;
    processPath.resize(1024);
    DWORD size = static_cast<DWORD>(processPath.size());
    const bool ok = QueryFullProcessImageNameW(processHandle, 0, processPath.data(), &size) != FALSE;
    CloseHandle(processHandle);

    if (!ok || size == 0) {
        return {};
    }

    processPath.resize(size);
    return QFileInfo(QString::fromStdWString(processPath)).completeBaseName().trimmed();
}

QString windowTitleForHandle(HWND hwnd) {
    const int titleLength = GetWindowTextLengthW(hwnd);
    if (titleLength <= 0) {
        return {};
    }

    std::wstring title;
    title.resize(static_cast<size_t>(titleLength) + 1);
    const int copied = GetWindowTextW(hwnd, title.data(), static_cast<int>(title.size()));
    if (copied <= 0) {
        return {};
    }

    title.resize(static_cast<size_t>(copied));
    return QString::fromStdWString(title).trimmed();
}

}  // namespace

NativeScreenHelperWin::NativeScreenHelperWin() = default;
NativeScreenHelperWin::~NativeScreenHelperWin() = default;

bool NativeScreenHelperWin::ensurePermissions(QString* errorMessage) {
    Q_UNUSED(errorMessage);
    return true;
}

CaptureResult NativeScreenHelperWin::captureFrozenDesktop() {
    monitors_ = buildMonitorMap();

    CaptureResult result;
    QRect virtualRect;
    QRect physicalRect;
    qreal maxScale = 1.0;

    for (const auto& monitor : monitors_) {
        if (isZeroRect(monitor.physicalRect)) {
            continue;
        }

        virtualRect = virtualRect.united(monitor.logicalRect);
        physicalRect = physicalRect.united(qRectFromRECT(monitor.physicalRect));
        maxScale = qMax(maxScale, monitor.scale);
    }

    if (!virtualRect.isValid() || virtualRect.isEmpty()
        || !physicalRect.isValid() || physicalRect.isEmpty()) {
        return result;
    }

    QImage canvas(physicalRect.size(), QImage::Format_ARGB32_Premultiplied);
    canvas.fill(Qt::transparent);

    QPainter painter(&canvas);
    const auto screens = QGuiApplication::screens();
    for (const auto& monitor : monitors_) {
        if (isZeroRect(monitor.physicalRect)) {
            continue;
        }

        QScreen* matchedScreen = nullptr;
        for (QScreen* screen : screens) {
            if (screen != nullptr
                && screen->name().compare(monitor.deviceName, Qt::CaseInsensitive) == 0) {
                matchedScreen = screen;
                break;
            }
        }
        if (matchedScreen == nullptr) {
            continue;
        }

        const QPixmap shot = matchedScreen->grabWindow(0);
        const QRect targetRect =
            qRectFromRECT(monitor.physicalRect).translated(-physicalRect.topLeft());
        painter.drawImage(targetRect, shot.toImage());

        CaptureDisplaySegment segment;
        segment.logicalRect = monitor.logicalRect;
        segment.pixelRect = targetRect;
        result.displaySegments.push_back(segment);
    }
    painter.end();

    virtualDesktopRect_ = virtualRect;
    result.virtualDesktopRect = virtualRect;
    result.deviceScaleHint = maxScale;
    result.frozenDesktop = canvas;
    return result;
}

QVector<WindowCandidate> NativeScreenHelperWin::enumerateWindowCandidates(const QRect& virtualDesktopRect) {
    virtualDesktopRect_ = virtualDesktopRect;

    QVector<WindowCandidate> out;
    struct Context {
        NativeScreenHelperWin* self = nullptr;
        QVector<WindowCandidate>* out = nullptr;
    } context{this, &out};

    EnumWindows(
        [](HWND hwnd, LPARAM userData) -> BOOL {
            auto* context = reinterpret_cast<Context*>(userData);
            auto* self = context->self;
            auto* out = context->out;

            if (!IsWindowVisible(hwnd) || IsIconic(hwnd)) {
                return TRUE;
            }

            DWORD ownerPid = 0;
            GetWindowThreadProcessId(hwnd, &ownerPid);
            if (ownerPid == GetCurrentProcessId()) {
                return TRUE;
            }

            BOOL cloaked = FALSE;
            DwmGetWindowAttribute(hwnd, DWMWA_CLOAKED, &cloaked, sizeof(cloaked));
            if (cloaked) {
                return TRUE;
            }

            const LONG_PTR exStyle = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
            if ((exStyle & WS_EX_TOOLWINDOW) != 0) {
                return TRUE;
            }

            RECT nativeRect{};
            if (!GetWindowRect(hwnd, &nativeRect) || isZeroRect(nativeRect)) {
                return TRUE;
            }

            const QRect logicalRect =
                self->nativeRectToLogical(nativeRect).intersected(self->virtualDesktopRect_);
            if (!logicalRect.isValid() || logicalRect.isEmpty()) {
                return TRUE;
            }

            WindowCandidate candidate;
            candidate.overlayRect = logicalRect.translated(-self->virtualDesktopRect_.topLeft());
            candidate.nativeRect = logicalRect;
            candidate.nativeId = reinterpret_cast<quint64>(hwnd);
            candidate.ownerAppName = processNameForPid(ownerPid);
            candidate.windowTitle = windowTitleForHandle(hwnd);
            candidate.zIndex = out->size();
            candidate.valid = candidate.overlayRect.isValid() && !candidate.overlayRect.isEmpty();
            if (candidate.valid) {
                out->push_back(candidate);
            }

            return TRUE;
        },
        reinterpret_cast<LPARAM>(&context));

    return out;
}

QString NativeScreenHelperWin::backendName() const {
    return QStringLiteral("Win32+QtFreeze");
}

QVector<NativeScreenHelperWin::MonitorDescriptor> NativeScreenHelperWin::buildMonitorMap() const {
    QVector<MonitorDescriptor> monitors;
    const auto screens = QGuiApplication::screens();
    monitors.reserve(screens.size());

    for (QScreen* screen : screens) {
        if (screen == nullptr) {
            continue;
        }

        MonitorDescriptor descriptor;
        descriptor.deviceName = screen->name();
        descriptor.logicalRect = screen->geometry();
        descriptor.scale = screen->devicePixelRatio();
        monitors.push_back(descriptor);
    }

    EnumDisplayMonitors(
        nullptr,
        nullptr,
        [](HMONITOR monitor, HDC, LPRECT, LPARAM userData) -> BOOL {
            auto* monitors = reinterpret_cast<QVector<MonitorDescriptor>*>(userData);

            MONITORINFOEXW info{};
            info.cbSize = sizeof(info);
            if (!GetMonitorInfoW(monitor, &info)) {
                return TRUE;
            }

            const QString deviceName = QString::fromWCharArray(info.szDevice);
            for (auto& descriptor : *monitors) {
                if (descriptor.deviceName.compare(deviceName, Qt::CaseInsensitive) == 0) {
                    descriptor.physicalRect = info.rcMonitor;
                    break;
                }
            }
            return TRUE;
        },
        reinterpret_cast<LPARAM>(&monitors));

    return monitors;
}

QPoint NativeScreenHelperWin::physicalToLogical(const POINT& point) const {
    for (const auto& monitor : monitors_) {
        if (point.x >= monitor.physicalRect.left
            && point.x < monitor.physicalRect.right
            && point.y >= monitor.physicalRect.top
            && point.y < monitor.physicalRect.bottom) {
            const qreal logicalX =
                monitor.logicalRect.x() + (point.x - monitor.physicalRect.left) / monitor.scale;
            const qreal logicalY =
                monitor.logicalRect.y() + (point.y - monitor.physicalRect.top) / monitor.scale;
            return {qRound(logicalX), qRound(logicalY)};
        }
    }

    return {point.x, point.y};
}

QRect NativeScreenHelperWin::nativeRectToLogical(const RECT& rect) const {
    const POINT topLeftPhys{rect.left, rect.top};
    const POINT bottomRightPhys{rect.right - 1, rect.bottom - 1};

    const QPoint topLeft = physicalToLogical(topLeftPhys);
    const QPoint bottomRight = physicalToLogical(bottomRightPhys);

    QRect logical(topLeft, bottomRight);
    logical = logical.normalized();
    logical.adjust(0, 0, 1, 1);
    return logical;
}

#else

#include "integration/platform/NativeScreenHelperWin.h"

NativeScreenHelperWin::NativeScreenHelperWin() = default;
NativeScreenHelperWin::~NativeScreenHelperWin() = default;

bool NativeScreenHelperWin::ensurePermissions(QString* errorMessage) {
    if (errorMessage != nullptr) {
        *errorMessage = QStringLiteral("Windows native capture backend unavailable on this platform.");
    }
    return false;
}

CaptureResult NativeScreenHelperWin::captureFrozenDesktop() {
    return {};
}

QVector<WindowCandidate> NativeScreenHelperWin::enumerateWindowCandidates(const QRect& virtualDesktopRect) {
    Q_UNUSED(virtualDesktopRect);
    return {};
}

QString NativeScreenHelperWin::backendName() const {
    return QStringLiteral("Win32+QtFreeze");
}

QVector<NativeScreenHelperWin::MonitorDescriptor> NativeScreenHelperWin::buildMonitorMap() const {
    return {};
}

QPoint NativeScreenHelperWin::physicalToLogical(const tagPOINT& point) const {
    Q_UNUSED(point);
    return {};
}

QRect NativeScreenHelperWin::nativeRectToLogical(const tagRECT& rect) const {
    Q_UNUSED(rect);
    return {};
}

#endif

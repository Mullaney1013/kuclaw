#include "core/capture/ScreenCaptureManager.h"

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
#include <ApplicationServices/ApplicationServices.h>
#endif

#include <QCoreApplication>
#include <QGuiApplication>
#include <QPainter>
#include <QScreen>

ScreenCaptureManager::ScreenCaptureManager(QObject* parent)
    : QObject(parent) {}

namespace {

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
bool readBooleanDictionaryValue(const CFDictionaryRef dictionary,
                               const CFStringRef key,
                               bool defaultValue) {
    const void* rawValue = CFDictionaryGetValue(dictionary, key);
    if (rawValue == nullptr) {
        return defaultValue;
    }

    const CFTypeRef value = static_cast<CFTypeRef>(rawValue);
    if (CFGetTypeID(value) != CFBooleanGetTypeID()) {
        return defaultValue;
    }

    return CFBooleanGetValue(static_cast<CFBooleanRef>(value));
}

bool readNumberDictionaryValue(const CFDictionaryRef dictionary,
                              const CFStringRef key,
                              qint64& outValue) {
    const void* rawValue = CFDictionaryGetValue(dictionary, key);
    if (rawValue == nullptr) {
        return false;
    }

    const CFTypeRef value = static_cast<CFTypeRef>(rawValue);
    if (CFGetTypeID(value) != CFNumberGetTypeID()) {
        return false;
    }

    const auto* numberValue = static_cast<const CFNumberRef>(value);
    return CFNumberGetValue(numberValue, kCFNumberLongLongType, &outValue);
}

bool readRectFromDictionary(const CFDictionaryRef dictionary,
                           const CFStringRef key,
                           QRect& outRect) {
    const void* rawValue = CFDictionaryGetValue(dictionary, key);
    if (rawValue == nullptr) {
        return false;
    }

    const CFTypeRef value = static_cast<CFTypeRef>(rawValue);
    if (CFGetTypeID(value) != CFDictionaryGetTypeID()) {
        return false;
    }

    CGRect cgRect{};
    if (!CGRectMakeWithDictionaryRepresentation(static_cast<CFDictionaryRef>(value), &cgRect)) {
        return false;
    }

    const auto x = qRound(cgRect.origin.x);
    const auto y = qRound(cgRect.origin.y);
    const auto width = qRound(cgRect.size.width);
    const auto height = qRound(cgRect.size.height);
    outRect = QRect(x, y, width, height);
    return outRect.isValid();
}

QRect translateCoreGraphicsRectToQt(const QRect& virtualGeometry, const QRect& cgRect) {
    Q_UNUSED(virtualGeometry);

    // CGWindowList 返回的 bounds 已经是左上角坐标系，不需要再次翻转。
    return QRect(cgRect.x(),
                 cgRect.y(),
                 cgRect.width(),
                 cgRect.height());
}
#endif

} // namespace

DesktopSnapshot ScreenCaptureManager::captureDesktop() const {
    DesktopSnapshot snapshot;
    const QList<QScreen*> screens = QGuiApplication::screens();

    QRect virtualGeometry;
    for (QScreen* screen : screens) {
        virtualGeometry = virtualGeometry.united(screen->geometry());
    }

    if (virtualGeometry.isNull()) {
        return snapshot;
    }

    QImage desktopImage(virtualGeometry.size(), QImage::Format_ARGB32_Premultiplied);
    desktopImage.fill(Qt::transparent);

    QPainter painter(&desktopImage);
    for (QScreen* screen : screens) {
        const QRect geometry = screen->geometry();
        const QPixmap pixmap = screen->grabWindow(0);
        painter.drawPixmap(geometry.topLeft() - virtualGeometry.topLeft(), pixmap);

        snapshot.screens.push_back({
            screen->name(),
            geometry,
            screen->devicePixelRatio()
        });
    }
    painter.end();

    snapshot.virtualGeometry = virtualGeometry;
    snapshot.image = desktopImage;
    return snapshot;
}

QImage ScreenCaptureManager::captureRegion(const QRect& logicalRect) const {
    const DesktopSnapshot snapshot = captureDesktop();
    if (snapshot.image.isNull()) {
        return {};
    }

    const QRect translatedRect = logicalRect.translated(-snapshot.virtualGeometry.topLeft());
    return snapshot.image.copy(translatedRect.intersected(snapshot.image.rect()));
}

QColor ScreenCaptureManager::sampleColor(const QPoint& logicalPoint) const {
    const DesktopSnapshot snapshot = captureDesktop();
    if (snapshot.image.isNull()) {
        return Qt::transparent;
    }

    const QPoint translatedPoint = logicalPoint - snapshot.virtualGeometry.topLeft();
    if (!snapshot.image.rect().contains(translatedPoint)) {
        return Qt::transparent;
    }

    return QColor::fromRgba(snapshot.image.pixel(translatedPoint));
}

QImage ScreenCaptureManager::buildMagnifierImage(const QPoint& logicalPoint,
                                                 int radius,
                                                 int scaleFactor) const {
    const DesktopSnapshot snapshot = captureDesktop();
    if (snapshot.image.isNull()) {
        return {};
    }

    const QPoint center = logicalPoint - snapshot.virtualGeometry.topLeft();
    const QRect sourceRect(center.x() - radius, center.y() - radius,
                           radius * 2 + 1, radius * 2 + 1);
    const QRect clippedSourceRect = sourceRect.intersected(snapshot.image.rect());
    const QImage cropped = snapshot.image.copy(clippedSourceRect);

    return cropped.scaled(cropped.width() * scaleFactor,
                          cropped.height() * scaleFactor,
                          Qt::KeepAspectRatio,
                          Qt::FastTransformation);
}

bool ScreenCaptureManager::hoveredWindowAt(const QPoint& logicalPoint,
                                          QRect* windowBounds,
                                          qint64* handle,
                                          bool* visible) const {
    if (windowBounds != nullptr) {
        windowBounds->setRect(0, 0, 0, 0);
    }
    if (handle != nullptr) {
        *handle = 0;
    }
    if (visible != nullptr) {
        *visible = false;
    }

    const QList<QScreen*> screens = QGuiApplication::screens();
    QRect virtualGeometry;
    for (QScreen* screen : screens) {
        virtualGeometry = virtualGeometry.united(screen->geometry());
    }
    if (virtualGeometry.isNull()) {
        return false;
    }

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    const qint64 currentProcessId = QCoreApplication::applicationPid();
    const CFArrayRef windowList = CGWindowListCopyWindowInfo(
        kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,
        kCGNullWindowID);
    if (windowList == nullptr) {
        return false;
    }

    const CFIndex windowCount = CFArrayGetCount(windowList);
    for (CFIndex i = 0; i < windowCount; ++i) {
        const void* rawWindow = CFArrayGetValueAtIndex(windowList, i);
        const auto* window = static_cast<CFDictionaryRef>(rawWindow);
        if (window == nullptr) {
            continue;
        }

        const bool isOnscreen = readBooleanDictionaryValue(window, kCGWindowIsOnscreen, false);
        if (!isOnscreen) {
            continue;
        }

        qint64 ownerPid = 0;
        if (!readNumberDictionaryValue(window, kCGWindowOwnerPID, ownerPid) || ownerPid <= 0) {
            continue;
        }
        if (ownerPid == currentProcessId) {
            continue;
        }

        qint64 windowLayer = 0;
        if (readNumberDictionaryValue(window, kCGWindowLayer, windowLayer)
            && windowLayer > 100000) {
            continue;
        }

        QRect nativeRect;
        if (!readRectFromDictionary(window, kCGWindowBounds, nativeRect) || !nativeRect.isValid()) {
            continue;
        }

        const QRect qtRect = translateCoreGraphicsRectToQt(virtualGeometry, nativeRect);
        if (qtRect.isEmpty() || !qtRect.isValid()) {
            continue;
        }

        if (!qtRect.contains(logicalPoint)) {
            continue;
        }

        qint64 numberWindowId = 0;
        const bool haveWindowId = readNumberDictionaryValue(window, kCGWindowNumber, numberWindowId);
        if (!haveWindowId) {
            continue;
        }

        if (windowBounds != nullptr) {
            *windowBounds = qtRect;
        }
        if (handle != nullptr) {
            *handle = numberWindowId;
        }
        if (visible != nullptr) {
            *visible = isOnscreen;
        }

        CFRelease(windowList);
        return true;
    }

    CFRelease(windowList);
    return false;
#else
    Q_UNUSED(logicalPoint);
    return false;
#endif
}

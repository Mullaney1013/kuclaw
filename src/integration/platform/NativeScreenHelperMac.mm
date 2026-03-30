#include "integration/platform/NativeScreenHelperMac.h"

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)

#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

#include <algorithm>
#include <limits>
#include <unistd.h>

#include <QGuiApplication>
#include <QImage>
#include <QPainter>
#include <QPixmap>
#include <QScreen>

namespace {

struct MacDisplayDescriptor {
    CGDirectDisplayID displayId = kCGNullDirectDisplay;
    QRect logicalRect;
    CGRect cocoaFrame = CGRectZero;
    CGRect topLeftFrame = CGRectZero;
    CGRect cgPixelFrame = CGRectZero;
    CGRect topLeftPixelFrame = CGRectZero;
    qreal scale = 1.0;
};

bool readBool(CFDictionaryRef dictionary, CFStringRef key, bool defaultValue = false) {
    const void* rawValue = CFDictionaryGetValue(dictionary, key);
    if (rawValue == nullptr) {
        return defaultValue;
    }

    const auto value = static_cast<CFTypeRef>(rawValue);
    if (CFGetTypeID(value) != CFBooleanGetTypeID()) {
        return defaultValue;
    }

    return CFBooleanGetValue(static_cast<CFBooleanRef>(value));
}

bool readInt64(CFDictionaryRef dictionary, CFStringRef key, qint64* outValue) {
    const void* rawValue = CFDictionaryGetValue(dictionary, key);
    if (rawValue == nullptr || outValue == nullptr) {
        return false;
    }

    const auto value = static_cast<CFTypeRef>(rawValue);
    if (CFGetTypeID(value) != CFNumberGetTypeID()) {
        return false;
    }

    return CFNumberGetValue(static_cast<CFNumberRef>(value),
                            kCFNumberLongLongType,
                            outValue);
}

bool readCGRect(CFDictionaryRef dictionary, CFStringRef key, CGRect* outRect) {
    const void* rawValue = CFDictionaryGetValue(dictionary, key);
    if (rawValue == nullptr || outRect == nullptr) {
        return false;
    }

    const auto value = static_cast<CFTypeRef>(rawValue);
    if (CFGetTypeID(value) != CFDictionaryGetTypeID()) {
        return false;
    }

    return CGRectMakeWithDictionaryRepresentation(static_cast<CFDictionaryRef>(value), outRect);
}

QString readString(CFDictionaryRef dictionary, CFStringRef key) {
    const void* rawValue = CFDictionaryGetValue(dictionary, key);
    if (rawValue == nullptr) {
        return {};
    }

    const auto value = static_cast<CFTypeRef>(rawValue);
    if (CFGetTypeID(value) != CFStringGetTypeID()) {
        return {};
    }

    NSString* stringValue = (__bridge NSString*)static_cast<CFStringRef>(value);
    if (stringValue == nil) {
        return {};
    }

    return QString::fromUtf8(stringValue.UTF8String ?: "");
}

SCShareableContent* fetchShareableContentSync(NSError** outError) {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block SCShareableContent* content = nil;
    __block NSError* localError = nil;

    [SCShareableContent getShareableContentExcludingDesktopWindows:NO
                                               onScreenWindowsOnly:YES
                                                completionHandler:^(SCShareableContent * _Nullable shareableContent,
                                                                    NSError * _Nullable error) {
        content = shareableContent;
        localError = error;
        dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if (outError != nullptr) {
        *outError = localError;
    }
    return content;
}

QRect rectFromCGRect(const CGRect& rect) {
    const int left = qFloor(CGRectGetMinX(rect));
    const int top = qFloor(CGRectGetMinY(rect));
    const int right = qCeil(CGRectGetMaxX(rect));
    const int bottom = qCeil(CGRectGetMaxY(rect));
    return QRect(left,
                 top,
                 qMax(1, right - left),
                 qMax(1, bottom - top));
}

}  // namespace

@interface KuclawSingleFrameStreamSink : NSObject <SCStreamOutput>
@property(nonatomic, readonly) dispatch_semaphore_t semaphore;
@property(nonatomic, assign) CMSampleBufferRef sampleBuffer;
@end

@implementation KuclawSingleFrameStreamSink

- (instancetype)init {
    self = [super init];
    if (self) {
        _semaphore = dispatch_semaphore_create(0);
        _sampleBuffer = nullptr;
    }
    return self;
}

- (void)dealloc {
    if (_sampleBuffer != nullptr) {
        CFRelease(_sampleBuffer);
        _sampleBuffer = nullptr;
    }
}

- (void)stream:(SCStream *)stream
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        ofType:(SCStreamOutputType)type {
    Q_UNUSED(stream);
    if (type != SCStreamOutputTypeScreen
        || sampleBuffer == nullptr
        || !CMSampleBufferIsValid(sampleBuffer)
        || _sampleBuffer != nullptr) {
        return;
    }

    _sampleBuffer = (CMSampleBufferRef)CFRetain(sampleBuffer);
    dispatch_semaphore_signal(_semaphore);
}

@end

class NativeScreenHelperMacPrivate {
public:
    QVector<MacDisplayDescriptor> displays;

    QVector<MacDisplayDescriptor> buildDisplayMap() const {
        QVector<MacDisplayDescriptor> displays;
        NSArray<NSScreen*>* screens = [NSScreen screens];
        if (screens.count == 0) {
            return displays;
        }

        CGFloat maxY = 0.0;
        CGFloat maxPixelY = 0.0;
        for (NSScreen* screen in screens) {
            maxY = std::max(maxY, NSMaxY(screen.frame));

            NSNumber* screenNumber = screen.deviceDescription[@"NSScreenNumber"];
            if (screenNumber != nil) {
                const CGDirectDisplayID displayId =
                    static_cast<CGDirectDisplayID>(screenNumber.unsignedIntValue);
                const CGRect pixelBounds = CGDisplayBounds(displayId);
                maxPixelY = std::max(maxPixelY, CGRectGetMaxY(pixelBounds));
            }
        }

        displays.reserve(static_cast<int>(screens.count));
        const QList<QScreen*> qtScreens = QGuiApplication::screens();
        QVector<bool> qtScreenUsed(qtScreens.size(), false);

        for (NSScreen* screen in screens) {
            NSNumber* screenNumber = screen.deviceDescription[@"NSScreenNumber"];
            if (screenNumber == nil) {
                continue;
            }

            const NSRect frame = screen.frame;
            const QRect fallbackLogicalRect(qRound(frame.origin.x),
                                            qRound(maxY - NSMaxY(frame)),
                                            qRound(frame.size.width),
                                            qRound(frame.size.height));

            QRect logicalRect = fallbackLogicalRect;
            qreal logicalScale = screen.backingScaleFactor;

            int bestQtScreenIndex = -1;
            qint64 bestScore = std::numeric_limits<qint64>::max();
            for (int index = 0; index < qtScreens.size(); ++index) {
                if (qtScreenUsed[index] || qtScreens.at(index) == nullptr) {
                    continue;
                }

                const QRect geometry = qtScreens.at(index)->geometry();
                const qreal dpr = qtScreens.at(index)->devicePixelRatio();
                const qint64 score =
                    qAbs(geometry.x() - fallbackLogicalRect.x())
                    + qAbs(geometry.y() - fallbackLogicalRect.y())
                    + qAbs(geometry.width() - fallbackLogicalRect.width())
                    + qAbs(geometry.height() - fallbackLogicalRect.height())
                    + qRound(qAbs(dpr - screen.backingScaleFactor) * 1000.0);

                if (score < bestScore) {
                    bestScore = score;
                    bestQtScreenIndex = index;
                }
            }

            if (bestQtScreenIndex >= 0) {
                logicalRect = qtScreens.at(bestQtScreenIndex)->geometry();
                logicalScale = qtScreens.at(bestQtScreenIndex)->devicePixelRatio();
                qtScreenUsed[bestQtScreenIndex] = true;
            }

            MacDisplayDescriptor descriptor;
            descriptor.displayId = static_cast<CGDirectDisplayID>(screenNumber.unsignedIntValue);
            descriptor.logicalRect = logicalRect;
            descriptor.cocoaFrame = NSRectToCGRect(frame);
            descriptor.topLeftFrame = CGRectMake(frame.origin.x,
                                                 maxY - NSMaxY(frame),
                                                 frame.size.width,
                                                 frame.size.height);
            descriptor.cgPixelFrame = CGDisplayBounds(descriptor.displayId);
            descriptor.topLeftPixelFrame = CGRectMake(
                CGRectGetMinX(descriptor.cgPixelFrame),
                maxPixelY - CGRectGetMaxY(descriptor.cgPixelFrame),
                CGRectGetWidth(descriptor.cgPixelFrame),
                CGRectGetHeight(descriptor.cgPixelFrame));
            descriptor.scale = logicalScale;
            displays.push_back(descriptor);
        }

        return displays;
    }

    bool containsPointInclusive(const CGRect& rect, const CGPoint& point) const {
        return point.x >= CGRectGetMinX(rect)
            && point.x <= CGRectGetMaxX(rect)
            && point.y >= CGRectGetMinY(rect)
            && point.y <= CGRectGetMaxY(rect);
    }

    QPointF mapFramePointToLogical(const CGPoint& point,
                                   const CGRect& sourceFrame,
                                   const QRect& logicalRect) const {
        const qreal frameWidth = CGRectGetWidth(sourceFrame);
        const qreal frameHeight = CGRectGetHeight(sourceFrame);
        if (frameWidth <= 0.0 || frameHeight <= 0.0) {
            return QPointF(point.x, point.y);
        }

        const qreal scaleX = static_cast<qreal>(logicalRect.width()) / frameWidth;
        const qreal scaleY = static_cast<qreal>(logicalRect.height()) / frameHeight;

        return QPointF(
            logicalRect.x() + (point.x - CGRectGetMinX(sourceFrame)) * scaleX,
            logicalRect.y() + (point.y - CGRectGetMinY(sourceFrame)) * scaleY
        );
    }

    QPointF mapTopLeftPointToLogical(const CGPoint& point) const {
        for (const auto& display : displays) {
            if (containsPointInclusive(display.topLeftFrame, point)) {
                return mapFramePointToLogical(point,
                                              display.topLeftFrame,
                                              display.logicalRect);
            }
        }

        // CGWindowList 的 kCGWindowBounds 在当前链路里更接近 Cocoa/Qt 的点坐标。
        // 只有点坐标没有命中任何屏幕时，才退回到像素坐标映射，避免 Retina 内屏被额外缩放。
        for (const auto& display : displays) {
            if (containsPointInclusive(display.topLeftPixelFrame, point)) {
                return mapFramePointToLogical(point,
                                              display.topLeftPixelFrame,
                                              display.logicalRect);
            }
        }

        return QPointF(point.x, point.y);
    }

    QRect cgRectToLogical(const CGRect& cgRect) const {
        const QPointF topLeft = mapTopLeftPointToLogical(
            CGPointMake(CGRectGetMinX(cgRect), CGRectGetMinY(cgRect)));
        const QPointF bottomRight = mapTopLeftPointToLogical(
            CGPointMake(CGRectGetMaxX(cgRect), CGRectGetMaxY(cgRect)));

        const int left = qFloor(qMin(topLeft.x(), bottomRight.x()));
        const int top = qFloor(qMin(topLeft.y(), bottomRight.y()));
        const int right = qCeil(qMax(topLeft.x(), bottomRight.x()));
        const int bottom = qCeil(qMax(topLeft.y(), bottomRight.y()));

        return QRect(left,
                     top,
                     qMax(1, right - left),
                     qMax(1, bottom - top));
    }

    QImage cgImageToQImage(CGImageRef image) const {
        if (image == nullptr) {
            return {};
        }

        const size_t width = CGImageGetWidth(image);
        const size_t height = CGImageGetHeight(image);
        QImage out(static_cast<int>(width),
                   static_cast<int>(height),
                   QImage::Format_ARGB32_Premultiplied);
        out.fill(Qt::transparent);

        const auto bitmapInfo = static_cast<CGBitmapInfo>(
            static_cast<uint32_t>(kCGBitmapByteOrder32Little)
            | static_cast<uint32_t>(kCGImageAlphaPremultipliedFirst));

        CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        CGContextRef context = CGBitmapContextCreate(out.bits(),
                                                     width,
                                                     height,
                                                     8,
                                                     static_cast<size_t>(out.bytesPerLine()),
                                                     colorSpace,
                                                     bitmapInfo);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        return out;
    }

    QImage sampleBufferToQImage(CMSampleBufferRef sampleBuffer) const {
        if (sampleBuffer == nullptr || !CMSampleBufferIsValid(sampleBuffer)) {
            return {};
        }

        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        if (imageBuffer == nullptr) {
            return {};
        }

        CVPixelBufferRef pixelBuffer = static_cast<CVPixelBufferRef>(imageBuffer);
        CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

        const int width = static_cast<int>(CVPixelBufferGetWidth(pixelBuffer));
        const int height = static_cast<int>(CVPixelBufferGetHeight(pixelBuffer));
        const int bytesPerRow = static_cast<int>(CVPixelBufferGetBytesPerRow(pixelBuffer));
        uchar* baseAddress = static_cast<uchar*>(CVPixelBufferGetBaseAddress(pixelBuffer));

        QImage wrapped(baseAddress,
                       width,
                       height,
                       bytesPerRow,
                       QImage::Format_ARGB32_Premultiplied);
        QImage copy = wrapped.copy();

        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        return copy;
    }

    CGImageRef captureDisplayWithScreenshotManager(SCDisplay* display,
                                                   const MacDisplayDescriptor& descriptor,
                                                   NSError** outError) const {
        SCContentFilter* filter =
            [[SCContentFilter alloc] initWithDisplay:display excludingWindows:@[]];
        SCStreamConfiguration* config = [SCStreamConfiguration new];
        config.width = static_cast<size_t>(descriptor.logicalRect.width() * descriptor.scale);
        config.height = static_cast<size_t>(descriptor.logicalRect.height() * descriptor.scale);
        config.pixelFormat = kCVPixelFormatType_32BGRA;
        config.showsCursor = NO;
        config.includeChildWindows = YES;

        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        __block CGImageRef capturedImage = nullptr;
        __block NSError* localError = nil;

        [SCScreenshotManager captureImageWithFilter:filter
                                      configuration:config
                                  completionHandler:^(CGImageRef _Nullable image,
                                                      NSError * _Nullable error) {
            if (image != nullptr) {
                capturedImage = CGImageRetain(image);
            }
            localError = error;
            dispatch_semaphore_signal(semaphore);
        }];

        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if (outError != nullptr) {
            *outError = localError;
        }
        return capturedImage;
    }

    QImage captureDisplayWithStreamFallback(SCDisplay* display,
                                            const MacDisplayDescriptor& descriptor,
                                            NSError** outError) const {
        SCContentFilter* filter =
            [[SCContentFilter alloc] initWithDisplay:display excludingWindows:@[]];
        SCStreamConfiguration* config = [SCStreamConfiguration new];
        config.width = static_cast<size_t>(descriptor.logicalRect.width() * descriptor.scale);
        config.height = static_cast<size_t>(descriptor.logicalRect.height() * descriptor.scale);
        config.pixelFormat = kCVPixelFormatType_32BGRA;
        config.showsCursor = NO;
        config.queueDepth = 1;
        config.minimumFrameInterval = CMTimeMake(1, 60);
        config.includeChildWindows = YES;

        KuclawSingleFrameStreamSink* sink = [KuclawSingleFrameStreamSink new];
        dispatch_queue_t queue =
            dispatch_queue_create("com.kuclaw.capture.singleframe", DISPATCH_QUEUE_SERIAL);

        __block NSError* localError = nil;
        SCStream* stream = [[SCStream alloc] initWithFilter:filter
                                              configuration:config
                                                   delegate:nil];
        if (![stream addStreamOutput:sink
                                type:SCStreamOutputTypeScreen
                  sampleHandlerQueue:queue
                               error:&localError]) {
            if (outError != nullptr) {
                *outError = localError;
            }
            return {};
        }

        dispatch_semaphore_t startSemaphore = dispatch_semaphore_create(0);
        [stream startCaptureWithCompletionHandler:^(NSError * _Nullable error) {
            localError = error;
            dispatch_semaphore_signal(startSemaphore);
        }];
        dispatch_semaphore_wait(startSemaphore, DISPATCH_TIME_FOREVER);
        if (localError != nil) {
            if (outError != nullptr) {
                *outError = localError;
            }
            return {};
        }

        const long waitResult =
            dispatch_semaphore_wait(sink.semaphore,
                                    dispatch_time(DISPATCH_TIME_NOW, 800 * NSEC_PER_MSEC));

        dispatch_semaphore_t stopSemaphore = dispatch_semaphore_create(0);
        [stream stopCaptureWithCompletionHandler:^(NSError * _Nullable error) {
            if (localError == nil) {
                localError = error;
            }
            dispatch_semaphore_signal(stopSemaphore);
        }];
        dispatch_semaphore_wait(stopSemaphore, DISPATCH_TIME_FOREVER);

        if (waitResult != 0 || sink.sampleBuffer == nullptr) {
            if (outError != nullptr) {
                *outError = localError;
            }
            return {};
        }

        if (outError != nullptr) {
            *outError = localError;
        }
        return sampleBufferToQImage(sink.sampleBuffer);
    }
};

NativeScreenHelperMac::NativeScreenHelperMac()
    : d(new NativeScreenHelperMacPrivate) {}

NativeScreenHelperMac::~NativeScreenHelperMac() = default;

bool NativeScreenHelperMac::ensurePermissions(QString* errorMessage) {
    if (@available(macOS 12.3, *)) {
        if (!CGPreflightScreenCaptureAccess()) {
            if (!CGRequestScreenCaptureAccess()) {
                if (errorMessage != nullptr) {
                    *errorMessage =
                        QStringLiteral("缺少屏幕录制权限，请在系统设置中为 Kuclaw 打开“屏幕录制”。");
                }
                return false;
            }
        }
        return true;
    }

    if (errorMessage != nullptr) {
        *errorMessage = QStringLiteral("ScreenCaptureKit 需要 macOS 12.3 或更高版本。");
    }
    return false;
}

CaptureResult NativeScreenHelperMac::captureFrozenDesktop() {
    CaptureResult result;
    d->displays = d->buildDisplayMap();
    if (d->displays.isEmpty()) {
        return result;
    }

    QRect virtualDesktopRect;
    for (const auto& display : d->displays) {
        virtualDesktopRect = virtualDesktopRect.united(display.logicalRect);
    }

    NSError* __autoreleasing shareableError = nil;
    SCShareableContent* shareableContent = fetchShareableContentSync(&shareableError);
    if (shareableContent == nil || shareableError != nil) {
        return result;
    }

    struct CapturedDisplayFrame {
        QRect logicalRect;
        QImage frame;
    };

    QVector<CapturedDisplayFrame> capturedFrames;
    capturedFrames.reserve(d->displays.size());
    qreal maxCapturedScale = 1.0;

    for (SCDisplay* display in shareableContent.displays) {
        const auto it = std::find_if(
            d->displays.begin(),
            d->displays.end(),
            [display](const MacDisplayDescriptor& descriptor) {
                return descriptor.displayId == display.displayID;
            });
        if (it == d->displays.end()) {
            continue;
        }

        NSError* __autoreleasing frameError = nil;
        QImage frame;
        if (@available(macOS 14.0, *)) {
            CGImageRef image = d->captureDisplayWithScreenshotManager(display, *it, &frameError);
            frame = d->cgImageToQImage(image);
            if (image != nullptr) {
                CGImageRelease(image);
            }
        } else {
            frame = d->captureDisplayWithStreamFallback(display, *it, &frameError);
        }

        if (!frameError && !frame.isNull()) {
            capturedFrames.push_back({
                it->logicalRect,
                frame,
            });

            if (it->logicalRect.width() > 0) {
                maxCapturedScale = qMax(
                    maxCapturedScale,
                    static_cast<qreal>(frame.width()) / it->logicalRect.width());
            }
        }
    }

    if (capturedFrames.isEmpty()) {
        return result;
    }

    QRect physicalDesktopRect;
    QVector<CaptureDisplaySegment> segments;
    segments.reserve(capturedFrames.size());
    for (const auto& captured : capturedFrames) {
        const int left = qRound(
            (captured.logicalRect.x() - virtualDesktopRect.x()) * maxCapturedScale);
        const int top = qRound(
            (captured.logicalRect.y() - virtualDesktopRect.y()) * maxCapturedScale);
        const QRect pixelRect(left,
                              top,
                              captured.frame.width(),
                              captured.frame.height());
        physicalDesktopRect = physicalDesktopRect.united(pixelRect);

        CaptureDisplaySegment segment;
        segment.logicalRect = captured.logicalRect;
        segment.pixelRect = pixelRect;
        segments.push_back(segment);
    }

    QImage canvas(physicalDesktopRect.size(), QImage::Format_ARGB32_Premultiplied);
    canvas.fill(Qt::transparent);

    QPainter painter(&canvas);
    for (int index = 0; index < capturedFrames.size(); ++index) {
        const QRect targetRect =
            segments.at(index).pixelRect.translated(-physicalDesktopRect.topLeft());
        painter.drawImage(targetRect.topLeft(), capturedFrames.at(index).frame);
    }
    painter.end();

    result.frozenDesktop = canvas;
    result.virtualDesktopRect = virtualDesktopRect;
    result.deviceScaleHint = maxCapturedScale;
    result.displaySegments.reserve(segments.size());
    for (const auto& segment : segments) {
        CaptureDisplaySegment normalizedSegment = segment;
        normalizedSegment.pixelRect.translate(-physicalDesktopRect.topLeft());
        result.displaySegments.push_back(normalizedSegment);
    }
    return result;
}

QVector<WindowCandidate> NativeScreenHelperMac::enumerateWindowCandidates(const QRect& virtualDesktopRect) {
    QVector<WindowCandidate> candidates;
    if (d->displays.isEmpty()) {
        d->displays = d->buildDisplayMap();
    }

    const pid_t currentPid = getpid();
    CFArrayRef windows = CGWindowListCopyWindowInfo(
        kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,
        kCGNullWindowID);
    if (windows == nullptr) {
        return candidates;
    }

    const CFIndex count = CFArrayGetCount(windows);
    candidates.reserve(static_cast<int>(count));
    for (CFIndex index = 0; index < count; ++index) {
        auto* info = static_cast<CFDictionaryRef>(CFArrayGetValueAtIndex(windows, index));
        if (info == nullptr) {
            continue;
        }

        const bool isOnscreen = readBool(info, kCGWindowIsOnscreen, false);
        if (!isOnscreen) {
            continue;
        }

        qint64 ownerPid = 0;
        qint64 layer = 0;
        qint64 windowId = 0;
        if (!readInt64(info, kCGWindowOwnerPID, &ownerPid)
            || !readInt64(info, kCGWindowLayer, &layer)
            || !readInt64(info, kCGWindowNumber, &windowId)) {
            continue;
        }

        if (ownerPid == currentPid || layer != 0) {
            continue;
        }

        CGRect cgBounds = CGRectZero;
        if (!readCGRect(info, kCGWindowBounds, &cgBounds)
            || CGRectIsEmpty(cgBounds)
            || CGRectGetWidth(cgBounds) < 1
            || CGRectGetHeight(cgBounds) < 1) {
            continue;
        }

        const QRect logicalRect =
            d->cgRectToLogical(cgBounds).intersected(virtualDesktopRect);
        if (!logicalRect.isValid() || logicalRect.isEmpty()) {
            continue;
        }

        WindowCandidate candidate;
        candidate.nativeId = static_cast<quint64>(windowId);
        candidate.nativeRect = logicalRect;
        candidate.overlayRect = logicalRect.translated(-virtualDesktopRect.topLeft());
        candidate.ownerAppName = readString(info, kCGWindowOwnerName).trimmed();
        candidate.windowTitle = readString(info, kCGWindowName).trimmed();
        candidate.zIndex = static_cast<int>(candidates.size());
        candidate.valid = true;
        candidates.push_back(candidate);
    }

    CFRelease(windows);
    return candidates;
}

QString NativeScreenHelperMac::backendName() const {
    return QStringLiteral("ScreenCaptureKit+CGWindowList");
}

#endif

#include "core/tray/MacStatusItemBackend.h"

#include <algorithm>
#include <cmath>
#include <cstring>

#include <QFileInfo>
#include <QIcon>
#include <QImage>
#include <QPixmap>
#include <QSize>
#include <QString>

#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>

static constexpr CGFloat kMenuBarIconPointSize = 22.0;
static constexpr CGFloat kMenuBarGlyphInsetPoints = 2.0;

@interface KuclawStatusItemTarget : NSObject

@property(nonatomic, weak) NSStatusItem* statusItem;
@property(nonatomic, strong) NSMenu* menu;
@property(nonatomic, copy) dispatch_block_t triggerCapture;
@property(nonatomic, copy) dispatch_block_t middleClickPin;
@property(nonatomic, copy) dispatch_block_t showCaptureMenuAction;
@property(nonatomic, copy) dispatch_block_t showPinMenuAction;
@property(nonatomic, copy) dispatch_block_t showRestoreMenuAction;
@property(nonatomic, copy) dispatch_block_t showHideAllMenuAction;
@property(nonatomic, copy) dispatch_block_t showQuitMenuAction;

- (void)handleStatusItemAction:(id)sender;
- (void)captureMenuTriggered:(id)sender;
- (void)pinMenuTriggered:(id)sender;
- (void)restoreMenuTriggered:(id)sender;
- (void)hideAllMenuTriggered:(id)sender;
- (void)quitMenuTriggered:(id)sender;

@end

namespace {

NSString* qtToNSString(const QString& text) {
    return [NSString stringWithUTF8String:text.toUtf8().constData()];
}

CGFloat menuBarScreenScaleFactor() {
    NSScreen* screen = NSScreen.mainScreen;
    if (screen == nil && NSScreen.screens.count > 0) {
        screen = NSScreen.screens.firstObject;
    }

    const CGFloat scale = screen != nil ? screen.backingScaleFactor : 2.0;
    return std::max<CGFloat>(1.0, std::ceil(scale));
}

QSize menuBarPixelCanvasSize(CGFloat scaleFactor) {
    const int pixels = std::max(1, static_cast<int>(std::lround(kMenuBarIconPointSize * scaleFactor)));
    return QSize(pixels, pixels);
}

QImage rasterizeNSImage(NSImage* sourceImage, const QSize& pixelCanvasSize, CGFloat scaleFactor) {
    if (sourceImage == nil || !sourceImage.isValid) {
        return {};
    }

    NSBitmapImageRep* rep =
        [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
                                                pixelsWide:pixelCanvasSize.width()
                                                pixelsHigh:pixelCanvasSize.height()
                                             bitsPerSample:8
                                           samplesPerPixel:4
                                                  hasAlpha:YES
                                                  isPlanar:NO
                                            colorSpaceName:NSCalibratedRGBColorSpace
                                               bytesPerRow:0
                                              bitsPerPixel:0];
    if (rep == nil) {
        return {};
    }

    NSGraphicsContext* context = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
    if (context == nil) {
        return {};
    }

    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:context];

    [[NSColor clearColor] set];
    NSRectFill(NSMakeRect(0.0, 0.0, pixelCanvasSize.width(), pixelCanvasSize.height()));

    const CGFloat targetSize =
        std::max<CGFloat>(1.0, (kMenuBarIconPointSize - (kMenuBarGlyphInsetPoints * 2.0)) * scaleFactor);
    const NSRect drawRect =
        NSMakeRect(kMenuBarGlyphInsetPoints * scaleFactor,
                   kMenuBarGlyphInsetPoints * scaleFactor,
                   targetSize,
                   targetSize);
    [sourceImage drawInRect:drawRect
                   fromRect:NSZeroRect
                  operation:NSCompositingOperationSourceOver
                   fraction:1.0
             respectFlipped:YES
                      hints:@{
                          NSImageHintInterpolation : @(NSImageInterpolationHigh),
                      }];

    [context flushGraphics];
    [NSGraphicsContext restoreGraphicsState];

    QImage image(pixelCanvasSize, QImage::Format_RGBA8888);
    const NSInteger bytesPerRow = rep.bytesPerRow;
    const unsigned char* bitmapData = rep.bitmapData;
    if (bitmapData == nullptr) {
        return {};
    }

    for (int y = 0; y < pixelCanvasSize.height(); ++y) {
        const unsigned char* source = bitmapData + (y * bytesPerRow);
        memcpy(image.scanLine(y), source, static_cast<size_t>(pixelCanvasSize.width()) * 4);
    }

    return image;
}

QImage menuBarTemplateGlyphFromImage(const QImage& sourceImage) {
    if (sourceImage.isNull()) {
        return {};
    }

    const QImage source = sourceImage.convertToFormat(QImage::Format_RGBA8888);
    QImage output(source.size(), QImage::Format_RGBA8888);
    output.fill(Qt::transparent);

    const int width = source.width();
    const int height = source.height();
    constexpr int kAlphaThreshold = 24;

    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            const int alpha = source.pixelColor(x, y).alpha();
            if (alpha < kAlphaThreshold) {
                continue;
            }

            // AppKit template images are intended to be black + transparent so the system
            // can tint them crisply for the current menu bar appearance.
            output.setPixelColor(x, y, QColor(0, 0, 0, 255));
        }
    }

    return output;
}

NSImage* templateImageFromQImage(const QImage& image, const QSizeF& pointSize) {
    if (image.isNull()) {
        return nil;
    }

    const QImage rgbaImage = image.convertToFormat(QImage::Format_RGBA8888);
    CFDataRef imageData = CFDataCreate(kCFAllocatorDefault,
                                       reinterpret_cast<const UInt8*>(rgbaImage.constBits()),
                                       static_cast<CFIndex>(rgbaImage.sizeInBytes()));
    if (imageData == nullptr) {
        return nil;
    }

    CGDataProviderRef provider = CGDataProviderCreateWithCFData(imageData);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(static_cast<size_t>(rgbaImage.width()),
                                       static_cast<size_t>(rgbaImage.height()),
                                       8,
                                       32,
                                       static_cast<size_t>(rgbaImage.bytesPerLine()),
                                       colorSpace,
                                       static_cast<CGBitmapInfo>(kCGBitmapByteOrderDefault)
                                           | static_cast<CGBitmapInfo>(kCGImageAlphaLast),
                                       provider,
                                       nullptr,
                                       false,
                                       kCGRenderingIntentDefault);

    NSImage* nsImage = nil;
    if (cgImage != nullptr) {
        nsImage = [[NSImage alloc] initWithCGImage:cgImage
                                              size:NSMakeSize(pointSize.width(), pointSize.height())];
        [nsImage setTemplate:YES];
    }

    if (cgImage != nullptr) {
        CGImageRelease(cgImage);
    }
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    CFRelease(imageData);

    return nsImage;
}

QImage rasterizedMenuBarTemplateImageFromFile(const QString& filePath, CGFloat scaleFactor) {
    const QFileInfo fileInfo(filePath);
    if (!fileInfo.exists() || !fileInfo.isFile()) {
        return {};
    }

    NSImage* nsImage = [[NSImage alloc] initWithContentsOfFile:qtToNSString(fileInfo.absoluteFilePath())];
    if (nsImage == nil) {
        return {};
    }

    return menuBarTemplateGlyphFromImage(rasterizeNSImage(nsImage, menuBarPixelCanvasSize(scaleFactor), scaleFactor));
}

NSImage* toTemplateImage(const QIcon& icon) {
    const CGFloat scaleFactor = menuBarScreenScaleFactor();
    const QSize pixelCanvasSize = menuBarPixelCanvasSize(scaleFactor);
    const QPixmap pixmap = icon.pixmap(pixelCanvasSize);
    if (pixmap.isNull()) {
        return nil;
    }
    return templateImageFromQImage(menuBarTemplateGlyphFromImage(
        pixmap.toImage().convertToFormat(QImage::Format_RGBA8888)),
        QSizeF(kMenuBarIconPointSize, kMenuBarIconPointSize));
}

NSImage* toTemplateImageFromFile(const QString& filePath) {
    return templateImageFromQImage(rasterizedMenuBarTemplateImageFromFile(filePath, menuBarScreenScaleFactor()),
                                   QSizeF(kMenuBarIconPointSize, kMenuBarIconPointSize));
}

void addMenuItem(NSMenu* menu,
                 NSString* title,
                 id target,
                 SEL action);

void applyStatusItemButtonImage(NSStatusBarButton* button, NSImage* image) {
    if (button == nil) {
        return;
    }

    button.image = image;
    button.imagePosition = NSImageOnly;
    button.imageScaling = NSImageScaleNone;

    if (button.image != nil) {
        [button.image setTemplate:YES];
    }
}

}  // namespace

@implementation KuclawStatusItemTarget

- (void)handleStatusItemAction:(id)sender {
    NSEvent* event = NSApp.currentEvent;
    if (event == nil) {
        if (self.triggerCapture != nil) {
            self.triggerCapture();
        }
        return;
    }

    if (event.type == NSEventTypeRightMouseUp || event.type == NSEventTypeRightMouseDown
        || event.buttonNumber == 1) {
        if (self.statusItem != nil && self.menu != nil) {
            [self.statusItem popUpStatusItemMenu:self.menu];
        }
        return;
    }

    if (event.type == NSEventTypeOtherMouseUp && event.buttonNumber == 2) {
        if (self.middleClickPin != nil) {
            self.middleClickPin();
        }
        return;
    }

    if (self.triggerCapture != nil) {
        self.triggerCapture();
    }
}

- (void)captureMenuTriggered:(id)sender {
    if (self.showCaptureMenuAction != nil) {
        self.showCaptureMenuAction();
    }
}

- (void)pinMenuTriggered:(id)sender {
    if (self.showPinMenuAction != nil) {
        self.showPinMenuAction();
    }
}

- (void)restoreMenuTriggered:(id)sender {
    if (self.showRestoreMenuAction != nil) {
        self.showRestoreMenuAction();
    }
}

- (void)hideAllMenuTriggered:(id)sender {
    if (self.showHideAllMenuAction != nil) {
        self.showHideAllMenuAction();
    }
}

- (void)quitMenuTriggered:(id)sender {
    if (self.showQuitMenuAction != nil) {
        self.showQuitMenuAction();
    }
}

@end

namespace {

void addMenuItem(NSMenu* menu,
                 NSString* title,
                 id target,
                 SEL action) {
    NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:title
                                                  action:action
                                           keyEquivalent:@""];
    item.target = target;
    [menu addItem:item];
}

}  // namespace

class MacStatusItemBackend::Impl {
public:
    explicit Impl(Callbacks callbacks)
        : callbacks_(std::move(callbacks)),
          target_([[KuclawStatusItemTarget alloc] init]) {
        target_.triggerCapture = ^{
            if (callbacks_.triggerCapture) {
                callbacks_.triggerCapture();
            }
        };
        target_.middleClickPin = ^{
            if (callbacks_.middleClickPin) {
                callbacks_.middleClickPin();
            }
        };
        target_.showCaptureMenuAction = ^{
            if (callbacks_.showCaptureMenuAction) {
                callbacks_.showCaptureMenuAction();
            }
        };
        target_.showPinMenuAction = ^{
            if (callbacks_.showPinMenuAction) {
                callbacks_.showPinMenuAction();
            }
        };
        target_.showRestoreMenuAction = ^{
            if (callbacks_.showRestoreMenuAction) {
                callbacks_.showRestoreMenuAction();
            }
        };
        target_.showHideAllMenuAction = ^{
            if (callbacks_.showHideAllMenuAction) {
                callbacks_.showHideAllMenuAction();
            }
        };
        target_.showQuitMenuAction = ^{
            if (callbacks_.showQuitMenuAction) {
                callbacks_.showQuitMenuAction();
            }
        };

        NSMenu* menu = [[NSMenu alloc] initWithTitle:@"Kuclaw"];
        addMenuItem(menu, @"开始截图", target_, @selector(captureMenuTriggered:));
        addMenuItem(menu, @"贴图", target_, @selector(pinMenuTriggered:));
        addMenuItem(menu, @"恢复最近关闭贴图", target_, @selector(restoreMenuTriggered:));
        addMenuItem(menu, @"隐藏所有贴图", target_, @selector(hideAllMenuTriggered:));
        [menu addItem:[NSMenuItem separatorItem]];
        addMenuItem(menu, @"退出", target_, @selector(quitMenuTriggered:));
        target_.menu = menu;
    }

    void setToolTip(const QString& toolTip) {
        toolTip_ = toolTip;
        if (statusItem_ != nil && statusItem_.button != nil) {
            statusItem_.button.toolTip = qtToNSString(toolTip_);
        }
    }

    void setIcon(const QIcon& icon) {
        image_ = toTemplateImage(icon);
        if (statusItem_ != nil && statusItem_.button != nil) {
            applyStatusItemButtonImage(statusItem_.button, image_);
        }
    }

    void setTemplateImageFile(const QString& filePath) {
        image_ = toTemplateImageFromFile(filePath);
        if (statusItem_ != nil && statusItem_.button != nil) {
            applyStatusItemButtonImage(statusItem_.button, image_);
        }
    }

    void show() {
        if (statusItem_ != nil) {
            return;
        }

        statusItem_ = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
        target_.statusItem = statusItem_;

        if (NSStatusBarButton* button = statusItem_.button) {
            button.target = target_;
            button.action = @selector(handleStatusItemAction:);
            button.toolTip = toolTip_.isEmpty() ? nil : qtToNSString(toolTip_);
            applyStatusItemButtonImage(button, image_);
            [button sendActionOn:NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp | NSEventMaskOtherMouseUp];
        }
    }

    void hide() {
        if (statusItem_ == nil) {
            return;
        }

        [[NSStatusBar systemStatusBar] removeStatusItem:statusItem_];
        target_.statusItem = nil;
        statusItem_ = nil;
    }

    bool isVisible() const {
        return statusItem_ != nil;
    }

    bool hasRenderableImage() const {
        return image_ != nil;
    }

    bool usesTemplateImage() const {
        return statusItem_ != nil && statusItem_.button != nil && statusItem_.button.image != nil
               && [statusItem_.button.image isTemplate];
    }

    QImage rasterizedImage() const {
        if (image_ == nil) {
            return {};
        }

        return rasterizeNSImage(image_, imagePixelSize(), imageScaleFactor());
    }

    QSize imagePixelSize() const {
        if (image_ == nil) {
            return {};
        }

        NSImageRep* rep = [image_ bestRepresentationForRect:NSMakeRect(0.0, 0.0,
                                                                       image_.size.width,
                                                                       image_.size.height)
                                                    context:nil
                                                      hints:nil];
        if (rep == nil) {
            return {};
        }

        return QSize(static_cast<int>(rep.pixelsWide), static_cast<int>(rep.pixelsHigh));
    }

    QSize imagePointSize() const {
        if (image_ == nil) {
            return {};
        }

        return QSize(static_cast<int>(std::lround(image_.size.width)),
                     static_cast<int>(std::lround(image_.size.height)));
    }

    double imageScaleFactor() const {
        const QSize pointSize = imagePointSize();
        const QSize pixelSize = imagePixelSize();
        if (pointSize.width() <= 0 || pointSize.height() <= 0) {
            return 0.0;
        }

        return static_cast<double>(pixelSize.width()) / static_cast<double>(pointSize.width());
    }

private:
    Callbacks callbacks_;
    __strong KuclawStatusItemTarget* target_;
    __strong NSStatusItem* statusItem_ = nil;
    __strong NSImage* image_ = nil;
    QString toolTip_;
};

MacStatusItemBackend::MacStatusItemBackend(Callbacks callbacks)
    : impl_(std::make_unique<Impl>(std::move(callbacks))) {}

MacStatusItemBackend::~MacStatusItemBackend() = default;

void MacStatusItemBackend::setToolTip(const QString& toolTip) {
    impl_->setToolTip(toolTip);
}

void MacStatusItemBackend::setTemplateImageFile(const QString& filePath) {
    impl_->setTemplateImageFile(filePath);
}

void MacStatusItemBackend::setIcon(const QIcon& icon) {
    impl_->setIcon(icon);
}

void MacStatusItemBackend::show() {
    impl_->show();
}

void MacStatusItemBackend::hide() {
    impl_->hide();
}

bool MacStatusItemBackend::isVisible() const {
    return impl_->isVisible();
}

bool MacStatusItemBackend::hasRenderableImage() const {
    return impl_->hasRenderableImage();
}

bool MacStatusItemBackend::usesTemplateImageForTesting() const {
    return impl_->usesTemplateImage();
}

QImage MacStatusItemBackend::rasterizedImageForTesting() const {
    return impl_->rasterizedImage();
}

QSize MacStatusItemBackend::imagePixelSizeForTesting() const {
    return impl_->imagePixelSize();
}

QSize MacStatusItemBackend::imagePointSizeForTesting() const {
    return impl_->imagePointSize();
}

double MacStatusItemBackend::imageScaleFactorForTesting() const {
    return impl_->imageScaleFactor();
}

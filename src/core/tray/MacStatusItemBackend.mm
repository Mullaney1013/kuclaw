#include "core/tray/MacStatusItemBackend.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <optional>

#include <QFileInfo>
#include <QIcon>
#include <QImage>
#include <QPainter>
#include <QPixmap>
#include <QSize>
#include <QString>

#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>

static constexpr CGFloat kMenuBarIconPointSize = 22.0;
static constexpr CGFloat kMenuBarGlyphInsetPoints = 1.0;
static constexpr int kSourceCropAlphaThreshold = 8;

@interface KuclawStatusItemTarget : NSObject <NSMenuDelegate>

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
- (void)presentStatusItemMenu;
- (void)detachPresentedMenuIfNeeded;
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

std::optional<CGFloat>& menuBarScaleFactorOverrideStorage() {
    static std::optional<CGFloat> sScaleFactorOverride;
    return sScaleFactorOverride;
}

CGFloat menuBarScreenScaleFactor() {
    if (menuBarScaleFactorOverrideStorage().has_value()) {
        return std::max<CGFloat>(1.0, menuBarScaleFactorOverrideStorage().value());
    }

    NSScreen* screen = NSScreen.mainScreen;
    if (screen == nil && NSScreen.screens.count > 0) {
        screen = NSScreen.screens.firstObject;
    }

    const CGFloat scale = screen != nil ? screen.backingScaleFactor : 2.0;
    return std::max<CGFloat>(1.0, std::ceil(scale));
}

CGFloat menuBarScreenScaleFactor(NSStatusItem* statusItem) {
    if (menuBarScaleFactorOverrideStorage().has_value()) {
        return std::max<CGFloat>(1.0, menuBarScaleFactorOverrideStorage().value());
    }

    NSScreen* screen = nil;
    if (statusItem != nil && statusItem.button != nil && statusItem.button.window != nil) {
        screen = statusItem.button.window.screen;
    }
    if (screen == nil) {
        screen = NSScreen.mainScreen;
    }
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

QImage rasterizeNSImage(NSImage* sourceImage, const QSize& pixelCanvasSize) {
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

    [sourceImage drawInRect:NSMakeRect(0.0, 0.0, pixelCanvasSize.width(), pixelCanvasSize.height())
                   fromRect:NSZeroRect
                  operation:NSCompositingOperationSourceOver
                   fraction:1.0
             respectFlipped:YES
                      hints:@{
                          NSImageHintInterpolation : @(NSImageInterpolationNone),
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

QRect alphaBounds(const QImage& image, int minAlpha) {
    if (image.isNull()) {
        return {};
    }

    int minX = image.width();
    int minY = image.height();
    int maxX = -1;
    int maxY = -1;

    for (int y = 0; y < image.height(); ++y) {
        for (int x = 0; x < image.width(); ++x) {
            if (image.pixelColor(x, y).alpha() < minAlpha) {
                continue;
            }

            minX = std::min(minX, x);
            minY = std::min(minY, y);
            maxX = std::max(maxX, x);
            maxY = std::max(maxY, y);
        }
    }

    if (maxX < minX || maxY < minY) {
        return {};
    }

    return QRect(QPoint(minX, minY), QPoint(maxX, maxY));
}

QSize preferredSourceRasterSize(NSImage* sourceImage, const QSize& fallbackSize) {
    if (sourceImage == nil || !sourceImage.isValid) {
        return fallbackSize;
    }

    const NSRect proposedRect =
        NSMakeRect(0.0, 0.0, fallbackSize.width(), fallbackSize.height());
    NSImageRep* rep = [sourceImage bestRepresentationForRect:proposedRect
                                                     context:nil
                                                       hints:nil];
    if (rep == nil || rep.pixelsWide <= 0 || rep.pixelsHigh <= 0) {
        return fallbackSize;
    }

    return QSize(static_cast<int>(rep.pixelsWide), static_cast<int>(rep.pixelsHigh));
}

QImage cropAndFitMenuBarGlyph(const QImage& sourceImage, const QSize& pixelCanvasSize, CGFloat scaleFactor) {
    if (sourceImage.isNull()) {
        return {};
    }

    const QRect sourceBounds = alphaBounds(sourceImage, kSourceCropAlphaThreshold);
    if (!sourceBounds.isValid()) {
        return {};
    }

    const int insetPixels = std::max(0, static_cast<int>(std::lround(kMenuBarGlyphInsetPoints * scaleFactor)));
    const int targetSide = std::max(1, std::min(pixelCanvasSize.width(), pixelCanvasSize.height()) - (insetPixels * 2));
    const QRect targetRect((pixelCanvasSize.width() - targetSide) / 2,
                           (pixelCanvasSize.height() - targetSide) / 2,
                           targetSide,
                           targetSide);

    QImage output(pixelCanvasSize, QImage::Format_RGBA8888);
    output.fill(Qt::transparent);

    QPainter painter(&output);
    painter.setRenderHint(QPainter::Antialiasing, false);
    painter.setRenderHint(QPainter::SmoothPixmapTransform, false);
    painter.drawImage(targetRect, sourceImage, sourceBounds);
    painter.end();

    return output;
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

QImage rasterizedMenuBarTemplateImageFromFile(const QString& filePath,
                                              CGFloat scaleFactor,
                                              QSize* sourceRasterPixelSize);

QImage rasterizedMenuBarTemplateImageFromFile(const QString& filePath, CGFloat scaleFactor) {
    return rasterizedMenuBarTemplateImageFromFile(filePath, scaleFactor, nullptr);
}

QImage rasterizedMenuBarTemplateImageFromFile(const QString& filePath,
                                              CGFloat scaleFactor,
                                              QSize* sourceRasterPixelSize) {
    const QFileInfo fileInfo(filePath);
    if (!fileInfo.exists() || !fileInfo.isFile()) {
        return {};
    }

    NSImage* nsImage = [[NSImage alloc] initWithContentsOfFile:qtToNSString(fileInfo.absoluteFilePath())];
    if (nsImage == nil) {
        return {};
    }

    const QSize pixelCanvasSize = menuBarPixelCanvasSize(scaleFactor);
    const QSize sourceRasterSize = preferredSourceRasterSize(nsImage, pixelCanvasSize);
    if (sourceRasterPixelSize != nullptr) {
        *sourceRasterPixelSize = sourceRasterSize;
    }
    const QImage sourceRaster = rasterizeNSImage(nsImage, sourceRasterSize);
    return menuBarTemplateGlyphFromImage(cropAndFitMenuBarGlyph(sourceRaster, pixelCanvasSize, scaleFactor));
}

NSImage* toTemplateImage(const QIcon& icon, CGFloat scaleFactor) {
    const QSize pixelCanvasSize = menuBarPixelCanvasSize(scaleFactor);
    const QPixmap pixmap = icon.pixmap(pixelCanvasSize);
    if (pixmap.isNull()) {
        return nil;
    }
    return templateImageFromQImage(menuBarTemplateGlyphFromImage(
        pixmap.toImage().convertToFormat(QImage::Format_RGBA8888)),
        QSizeF(kMenuBarIconPointSize, kMenuBarIconPointSize));
}

NSImage* toTemplateImageFromFile(const QString& filePath, CGFloat scaleFactor) {
    return templateImageFromQImage(rasterizedMenuBarTemplateImageFromFile(filePath, scaleFactor),
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
        [self presentStatusItemMenu];
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

- (void)presentStatusItemMenu {
    if (self.statusItem == nil || self.menu == nil) {
        return;
    }

    self.menu.delegate = self;
    self.statusItem.menu = self.menu;

    if (self.statusItem.button != nil) {
        [self.statusItem.button performClick:nil];
    }
}

- (void)detachPresentedMenuIfNeeded {
    if (self.statusItem != nil && self.statusItem.menu == self.menu) {
        self.statusItem.menu = nil;
    }
}

- (void)menuDidClose:(NSMenu*)menu {
    if (menu == self.menu) {
        [self detachPresentedMenuIfNeeded];
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
    enum class ImageSourceKind {
        None,
        Icon,
        TemplateFile,
    };

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

    ~Impl() {
        hide();
    }

    void setToolTip(const QString& toolTip) {
        toolTip_ = toolTip;
        if (statusItem_ != nil && statusItem_.button != nil) {
            statusItem_.button.toolTip = qtToNSString(toolTip_);
        }
    }

    void setIcon(const QIcon& icon) {
        imageSourceKind_ = ImageSourceKind::Icon;
        sourceIcon_ = icon;
        templateImageFilePath_.clear();
        rerenderImageForCurrentScale();
    }

    void setTemplateImageFile(const QString& filePath) {
        imageSourceKind_ = ImageSourceKind::TemplateFile;
        templateImageFilePath_ = filePath;
        sourceIcon_ = QIcon();
        rerenderImageForCurrentScale();
    }

    void show() {
        if (statusItem_ != nil) {
            return;
        }

        statusItem_ = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
        target_.statusItem = statusItem_;
        installScreenChangeObserver();
        rerenderImageForCurrentScale();

        if (NSStatusBarButton* button = statusItem_.button) {
            button.target = target_;
            button.action = @selector(handleStatusItemAction:);
            button.toolTip = toolTip_.isEmpty() ? nil : qtToNSString(toolTip_);
            applyStatusItemButtonImage(button, image_);
            [button sendActionOn:NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp | NSEventMaskOtherMouseUp];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            rerenderImageForCurrentScale();
        });
    }

    void hide() {
        if (statusItem_ == nil) {
            return;
        }

        removeScreenChangeObserver();
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

        return rasterizeNSImage(image_, imagePixelSize());
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

    QSize sourceRasterPixelSize() const {
        return sourceRasterPixelSize_;
    }

    QSize renderedRasterPixelSize() const {
        return renderedRasterPixelSize_;
    }

    bool hasAttachedStatusItemScreen() const {
        return statusItem_ != nil && statusItem_.button != nil && statusItem_.button.window != nil
               && statusItem_.button.window.screen != nil;
    }

    bool isMenuAttached() const {
        return statusItem_ != nil && target_ != nil && statusItem_.menu == target_.menu;
    }

    double attachedStatusItemScreenScale() const {
        if (!hasAttachedStatusItemScreen()) {
            return 0.0;
        }

        return static_cast<double>(std::max<CGFloat>(1.0, std::ceil(statusItem_.button.window.screen.backingScaleFactor)));
    }

    void simulateScreenConfigurationChangeForTesting() {
        rerenderImageForCurrentScale();
    }

    void simulateRightClick() {
        [target_ presentStatusItemMenu];
    }

    void simulateMenuClosedForTesting() {
        [target_ menuDidClose:target_.menu];
    }

private:
    void installScreenChangeObserver() {
        if (screenParametersObserver_ != nil) {
            return;
        }

        screenParametersObserver_ =
            [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationDidChangeScreenParametersNotification
                                                              object:nil
                                                               queue:nil
                                                          usingBlock:^(__unused NSNotification* notification) {
                                                              rerenderImageForCurrentScale();
                                                          }];
    }

    void removeScreenChangeObserver() {
        if (screenParametersObserver_ == nil) {
            return;
        }

        [[NSNotificationCenter defaultCenter] removeObserver:screenParametersObserver_];
        screenParametersObserver_ = nil;
    }

    void rerenderImageForCurrentScale() {
        const CGFloat scaleFactor = menuBarScreenScaleFactor(statusItem_);
        renderedRasterPixelSize_ = menuBarPixelCanvasSize(scaleFactor);
        sourceRasterPixelSize_ = {};

        switch (imageSourceKind_) {
            case ImageSourceKind::Icon:
                image_ = toTemplateImage(sourceIcon_, scaleFactor);
                break;
            case ImageSourceKind::TemplateFile:
                image_ = templateImageFromQImage(rasterizedMenuBarTemplateImageFromFile(templateImageFilePath_,
                                                                                        scaleFactor,
                                                                                        &sourceRasterPixelSize_),
                                                 QSizeF(kMenuBarIconPointSize, kMenuBarIconPointSize));
                break;
            case ImageSourceKind::None:
                image_ = nil;
                renderedRasterPixelSize_ = {};
                break;
        }

        if (statusItem_ != nil && statusItem_.button != nil) {
            applyStatusItemButtonImage(statusItem_.button, image_);
        }
    }

    Callbacks callbacks_;
    __strong KuclawStatusItemTarget* target_;
    __strong NSStatusItem* statusItem_ = nil;
    __strong NSImage* image_ = nil;
    id screenParametersObserver_ = nil;
    ImageSourceKind imageSourceKind_ = ImageSourceKind::None;
    QIcon sourceIcon_;
    QString templateImageFilePath_;
    QSize sourceRasterPixelSize_;
    QSize renderedRasterPixelSize_;
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

QSize MacStatusItemBackend::sourceRasterPixelSizeForTesting() const {
    return impl_->sourceRasterPixelSize();
}

QSize MacStatusItemBackend::renderedRasterPixelSizeForTesting() const {
    return impl_->renderedRasterPixelSize();
}

bool MacStatusItemBackend::hasAttachedStatusItemScreenForTesting() const {
    return impl_->hasAttachedStatusItemScreen();
}

double MacStatusItemBackend::attachedStatusItemScreenScaleForTesting() const {
    return impl_->attachedStatusItemScreenScale();
}

bool MacStatusItemBackend::isMenuAttachedForTesting() const {
    return impl_->isMenuAttached();
}

void MacStatusItemBackend::simulateRightClickForTesting() {
    impl_->simulateRightClick();
}

void MacStatusItemBackend::simulateMenuClosedForTesting() {
    impl_->simulateMenuClosedForTesting();
}

void MacStatusItemBackend::simulateScreenConfigurationChangeForTesting() {
    impl_->simulateScreenConfigurationChangeForTesting();
}

void MacStatusItemBackend::setScaleFactorOverrideForTesting(double scaleFactor) {
    menuBarScaleFactorOverrideStorage() = std::max<CGFloat>(1.0, static_cast<CGFloat>(scaleFactor));
}

void MacStatusItemBackend::clearScaleFactorOverrideForTesting() {
    menuBarScaleFactorOverrideStorage().reset();
}

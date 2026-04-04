#pragma once

#include <QImage>
#include <QSize>

#include <functional>
#include <memory>

class QIcon;
class QString;

class MacStatusItemBackend final {
public:
    struct Callbacks {
        std::function<void()> triggerCapture;
        std::function<void()> middleClickPin;
        std::function<void()> showCaptureMenuAction;
        std::function<void()> showPinMenuAction;
        std::function<void()> showRestoreMenuAction;
        std::function<void()> showHideAllMenuAction;
        std::function<void()> showQuitMenuAction;
    };

    explicit MacStatusItemBackend(Callbacks callbacks);
    ~MacStatusItemBackend();

    void setToolTip(const QString& toolTip);
    void setTemplateImageFile(const QString& filePath);
    void setIcon(const QIcon& icon);
    void show();
    void hide();
    bool isVisible() const;
    bool hasRenderableImage() const;
    bool usesTemplateImageForTesting() const;
    QImage rasterizedImageForTesting() const;
    QSize imagePixelSizeForTesting() const;
    QSize imagePointSizeForTesting() const;
    double imageScaleFactorForTesting() const;
    QSize renderedRasterPixelSizeForTesting() const;
    QSize sourceRasterPixelSizeForTesting() const;
    bool hasAttachedStatusItemScreenForTesting() const;
    double attachedStatusItemScreenScaleForTesting() const;
    void simulateScreenConfigurationChangeForTesting();
    static void setScaleFactorOverrideForTesting(double scaleFactor);
    static void clearScaleFactorOverrideForTesting();

private:
    class Impl;

    std::unique_ptr<Impl> impl_;
};

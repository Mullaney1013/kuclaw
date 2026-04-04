#include "core/tray/TrayManager.h"

#include <QFileInfo>
#include <QImage>
#include <QtTest>
#include <QSystemTrayIcon>

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
#include "core/tray/MacStatusItemBackend.h"
#endif

class TrayManagerTest : public QObject {
    Q_OBJECT

private slots:
    void menuBarIcnsRemainsLegibleAtMenuBarSize() {
        const QString iconPath = QStringLiteral(KUCLAW_MENU_BAR_ICON_FILE_PATH);
        QVERIFY2(QFileInfo::exists(iconPath),
                 "icon.icns should exist on disk for the native macOS status-item path.");

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
        MacStatusItemBackend backend(MacStatusItemBackend::Callbacks{});
        backend.setTemplateImageFile(iconPath);

        constexpr int iconSize = 22;
        const QSize pointSize = backend.imagePointSizeForTesting();
        const QSize pixelSize = backend.imagePixelSizeForTesting();
        const double scaleFactor = backend.imageScaleFactorForTesting();
        const QImage image = backend.rasterizedImageForTesting().convertToFormat(QImage::Format_RGBA8888);
        QVERIFY2(!image.isNull(), "icon.icns should rasterize into a 22px menu-bar template image.");
        QCOMPARE(pointSize, QSize(iconSize, iconSize));
        QCOMPARE(image.size(), pixelSize);
        QVERIFY2(scaleFactor >= 1.0, "menu-bar template image should report a valid AppKit backing scale.");
        QVERIFY2(pixelSize.width() >= iconSize && pixelSize.height() >= iconSize,
                 "menu-bar template image should keep at least 1x backing pixels.");
#else
        QSKIP("Native menu bar template rendering is only available on macOS.");
#endif

        int minX = image.width();
        int minY = image.height();
        int maxX = -1;
        int maxY = -1;
        int alphaPixels = 0;

        for (int y = 0; y < image.height(); ++y) {
            for (int x = 0; x < image.width(); ++x) {
                if (image.pixelColor(x, y).alpha() == 0) {
                    continue;
                }
                ++alphaPixels;
                minX = std::min(minX, x);
                minY = std::min(minY, y);
                maxX = std::max(maxX, x);
                maxY = std::max(maxY, y);
            }
        }

        const double normalizedAlphaPixels = static_cast<double>(alphaPixels) / (scaleFactor * scaleFactor);
        QVERIFY2(normalizedAlphaPixels >= 110.0,
                 qPrintable(QStringLiteral("menu-bar glyph should occupy enough ink to stay visible at 22pt; got %1 physical alpha pixels (%2 normalized)")
                                .arg(alphaPixels)
                                .arg(normalizedAlphaPixels, 0, 'f', 1)));
        QVERIFY2(maxX >= minX && maxY >= minY,
                 "menu-bar glyph should render at least one visible shape at menu-bar size.");

        const double width = static_cast<double>(maxX - minX + 1) / scaleFactor;
        const double height = static_cast<double>(maxY - minY + 1) / scaleFactor;

        QVERIFY2(width >= 14,
                 qPrintable(QStringLiteral("menu-bar glyph should span at least 14pt horizontally inside the 22pt slot; got %1")
                                .arg(width)));
        QVERIFY2(height >= 14,
                 qPrintable(QStringLiteral("menu-bar glyph should span at least 14pt vertically inside the 22pt slot; got %1")
                                .arg(height)));
    }

    void usesNativeMacStatusItemBackendOnApple() {
        TrayManager manager;
        auto* trayIcon = manager.findChild<QSystemTrayIcon*>();

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
        QVERIFY2(trayIcon == nullptr,
                 "macOS menu bar extras should use a native status-item backend, not QSystemTrayIcon.");
        QVERIFY(manager.usesNativeMacStatusItemForTesting());
        QVERIFY2(manager.hasRenderableIconForTesting(),
                 "macOS menu bar extras should render the icon.icns asset into a native NSImage.");
        manager.show();
        QVERIFY(manager.isVisibleForTesting());
#else
        QVERIFY(trayIcon != nullptr);
        QVERIFY(!manager.usesNativeMacStatusItemForTesting());
#endif
    }

    void nativeMacStatusItemUsesTemplateImageForVisibility() {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
        MacStatusItemBackend backend(MacStatusItemBackend::Callbacks{});
        backend.setTemplateImageFile(QStringLiteral(KUCLAW_MENU_BAR_ICON_FILE_PATH));
        backend.show();

        QVERIFY2(backend.hasRenderableImage(),
                 "macOS menu bar extras should render the icon.icns asset into an NSImage before showing.");
        QVERIFY2(backend.usesTemplateImageForTesting(),
                 "macOS menu bar extras should mark the status-item image as a template image.");

        backend.hide();
#endif
    }
};

QTEST_MAIN(TrayManagerTest)

#include "tst_tray_manager.moc"

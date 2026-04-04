#include "core/tray/TrayManager.h"

#include <QDir>
#include <QFileInfo>
#include <QImage>
#include <QPainter>
#include <QSystemTrayIcon>
#include <QTemporaryDir>
#include <QtTest>

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
#include "core/tray/MacStatusItemBackend.h"
#endif

namespace {

QRect alphaBounds(const QImage& image) {
    int minX = image.width();
    int minY = image.height();
    int maxX = -1;
    int maxY = -1;

    for (int y = 0; y < image.height(); ++y) {
        for (int x = 0; x < image.width(); ++x) {
            if (image.pixelColor(x, y).alpha() == 0) {
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

QImage createSharpTrayGlyphSource() {
    QImage image(QSize(64, 64), QImage::Format_RGBA8888);
    image.fill(Qt::transparent);

    QPainter painter(&image);
    painter.setRenderHint(QPainter::Antialiasing, false);
    painter.setBrush(Qt::black);
    painter.setPen(Qt::NoPen);

    constexpr int arm = 8;
    constexpr int depth = 14;
    painter.drawRect(4, 4, depth, arm);
    painter.drawRect(4, 4, arm, depth);
    painter.drawRect(64 - 4 - depth, 4, depth, arm);
    painter.drawRect(64 - 4 - arm, 4, arm, depth);
    painter.drawRect(4, 64 - 4 - arm, depth, arm);
    painter.drawRect(4, 64 - 4 - depth, arm, depth);
    painter.drawRect(64 - 4 - depth, 64 - 4 - arm, depth, arm);
    painter.drawRect(64 - 4 - arm, 64 - 4 - depth, arm, depth);

    QPen pen(Qt::black, 8, Qt::SolidLine, Qt::SquareCap, Qt::MiterJoin);
    painter.setPen(pen);
    painter.drawPolyline(QPolygonF{
        QPointF(22, 22),
        QPointF(30, 42),
        QPointF(38, 28),
        QPointF(46, 42),
        QPointF(54, 22),
    });

    painter.end();
    return image;
}

QImage expectedFastFittedGlyph(const QImage& sourceImage, const QSize& pixelCanvasSize, double scaleFactor) {
    const QRect sourceBounds = alphaBounds(sourceImage);
    if (!sourceBounds.isValid()) {
        return {};
    }

    const int insetPixels = std::max(0, qRound(scaleFactor));
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

    for (int y = 0; y < output.height(); ++y) {
        for (int x = 0; x < output.width(); ++x) {
            const int alpha = output.pixelColor(x, y).alpha();
            output.setPixelColor(x, y, alpha >= 24 ? QColor(0, 0, 0, 255) : QColor(0, 0, 0, 0));
        }
    }

    return output;
}

int differingAlphaPixels(const QImage& lhs, const QImage& rhs) {
    if (lhs.size() != rhs.size()) {
        return std::numeric_limits<int>::max();
    }

    int differingPixels = 0;
    for (int y = 0; y < lhs.height(); ++y) {
        for (int x = 0; x < lhs.width(); ++x) {
            const bool lhsVisible = lhs.pixelColor(x, y).alpha() > 0;
            const bool rhsVisible = rhs.pixelColor(x, y).alpha() > 0;
            if (lhsVisible != rhsVisible) {
                ++differingPixels;
            }
        }
    }
    return differingPixels;
}

}  // namespace

class TrayManagerTest : public QObject {
    Q_OBJECT

private slots:
    void menuBarTemplateImageAvoidsSoftenedSecondResample() {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
        QTemporaryDir tempDir;
        QVERIFY(tempDir.isValid());

        const QImage sourceImage = createSharpTrayGlyphSource();
        const QString filePath = QDir(tempDir.path()).filePath(QStringLiteral("tray-source.png"));
        QVERIFY2(sourceImage.save(filePath), "temporary tray source image should save successfully.");

        MacStatusItemBackend backend(MacStatusItemBackend::Callbacks{});
        backend.setTemplateImageFile(filePath);

        const QImage actual = backend.rasterizedImageForTesting().convertToFormat(QImage::Format_RGBA8888);
        QVERIFY2(!actual.isNull(), "temporary tray source should rasterize through the native menu-bar path.");

        const QImage expected = expectedFastFittedGlyph(sourceImage,
                                                        backend.imagePixelSizeForTesting(),
                                                        backend.imageScaleFactorForTesting());
        QVERIFY2(!expected.isNull(), "expected fast-fitted tray glyph should be generated.");

        const int differingPixels = differingAlphaPixels(actual, expected);
        QVERIFY2(differingPixels <= 24,
                 qPrintable(QStringLiteral("menu-bar glyph should stay close to a single fast fit without an extra softening pass; differing alpha pixels: %1")
                                .arg(differingPixels)));
#else
        QSKIP("Native menu bar template rendering is only available on macOS.");
#endif
    }

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
        const QSize sourceRasterSize = backend.sourceRasterPixelSizeForTesting();
        const double scaleFactor = backend.imageScaleFactorForTesting();
        const QImage image = backend.rasterizedImageForTesting().convertToFormat(QImage::Format_RGBA8888);
        QVERIFY2(!image.isNull(), "icon.icns should rasterize into a 22px menu-bar template image.");
        QCOMPARE(pointSize, QSize(iconSize, iconSize));
        QCOMPARE(image.size(), pixelSize);
        QVERIFY2(scaleFactor >= 1.0, "menu-bar template image should report a valid AppKit backing scale.");
        QVERIFY2(pixelSize.width() >= iconSize && pixelSize.height() >= iconSize,
                 "menu-bar template image should keep at least 1x backing pixels.");
        QVERIFY2(sourceRasterSize.width() >= pixelSize.width() && sourceRasterSize.height() >= pixelSize.height(),
                 qPrintable(QStringLiteral("menu-bar glyph source rep should be at least as large as the final raster; got %1x%2 for %3x%4")
                                .arg(sourceRasterSize.width())
                                .arg(sourceRasterSize.height())
                                .arg(pixelSize.width())
                                .arg(pixelSize.height())));
        QVERIFY2(sourceRasterSize.width() <= pixelSize.width() * 3
                     && sourceRasterSize.height() <= pixelSize.height() * 3,
                 qPrintable(QStringLiteral("menu-bar glyph source rep should stay close to the target size instead of always downscaling from a huge rep; got %1x%2 for %3x%4")
                                .arg(sourceRasterSize.width())
                                .arg(sourceRasterSize.height())
                                .arg(pixelSize.width())
                                .arg(pixelSize.height())));
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
        QVERIFY2(normalizedAlphaPixels >= 125.0,
                 qPrintable(QStringLiteral("menu-bar glyph should occupy enough ink to stay visible at 22pt; got %1 physical alpha pixels (%2 normalized)")
                                .arg(alphaPixels)
                                .arg(normalizedAlphaPixels, 0, 'f', 1)));
        QVERIFY2(maxX >= minX && maxY >= minY,
                 "menu-bar glyph should render at least one visible shape at menu-bar size.");

        const double width = static_cast<double>(maxX - minX + 1) / scaleFactor;
        const double height = static_cast<double>(maxY - minY + 1) / scaleFactor;

        QVERIFY2(width >= 16,
                 qPrintable(QStringLiteral("menu-bar glyph should span at least 16pt horizontally inside the 22pt slot; got %1")
                                .arg(width)));
        QVERIFY2(height >= 16,
                 qPrintable(QStringLiteral("menu-bar glyph should span at least 16pt vertically inside the 22pt slot; got %1")
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

    void menuBarIconRerasterizesWhenScreenScaleChanges() {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
        MacStatusItemBackend::setScaleFactorOverrideForTesting(1.0);

        MacStatusItemBackend backend(MacStatusItemBackend::Callbacks{});
        backend.setTemplateImageFile(QStringLiteral(KUCLAW_MENU_BAR_ICON_FILE_PATH));
        QCOMPARE(backend.renderedRasterPixelSizeForTesting(), QSize(22, 22));

        MacStatusItemBackend::setScaleFactorOverrideForTesting(2.0);
        backend.show();
        QCOMPARE(backend.renderedRasterPixelSizeForTesting(), QSize(44, 44));

        MacStatusItemBackend::setScaleFactorOverrideForTesting(3.0);
        backend.simulateScreenConfigurationChangeForTesting();
        QCOMPARE(backend.renderedRasterPixelSizeForTesting(), QSize(66, 66));

        backend.hide();
        MacStatusItemBackend::clearScaleFactorOverrideForTesting();
#else
        QSKIP("Native menu bar template rendering is only available on macOS.");
#endif
    }
};

QTEST_MAIN(TrayManagerTest)

#include "tst_tray_manager.moc"

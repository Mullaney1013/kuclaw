#pragma once

#include <QObject>
#include <QRect>
#include <QUrl>

#include "core/capture/CaptureSessionController.h"

class CaptureViewModel final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool overlayVisible READ overlayVisible NOTIFY overlayVisibleChanged)
    Q_PROPERTY(QRect desktopGeometry READ desktopGeometry NOTIFY desktopGeometryChanged)
    Q_PROPERTY(QVariantList desktopScreens READ desktopScreens NOTIFY desktopScreensChanged)
    Q_PROPERTY(QUrl desktopSnapshotUrl READ desktopSnapshotUrl NOTIFY desktopSnapshotUrlChanged)
    Q_PROPERTY(QUrl magnifierImageUrl READ magnifierImageUrl NOTIFY magnifierImageUrlChanged)
    Q_PROPERTY(QRect selectionRect READ selectionRect NOTIFY selectionRectChanged)
    Q_PROPERTY(bool hasSelection READ hasSelection NOTIFY selectionRectChanged)
    Q_PROPERTY(QString currentColorString READ currentColorString NOTIFY currentColorStringChanged)

public:
    explicit CaptureViewModel(CaptureSessionController* controller,
                              QObject* parent = nullptr);

    bool overlayVisible() const;
    QRect desktopGeometry() const;
    QVariantList desktopScreens() const;
    QUrl desktopSnapshotUrl() const;
    QUrl magnifierImageUrl() const;
    QRect selectionRect() const;
    bool hasSelection() const;
    QString currentColorString() const;

    Q_INVOKABLE void beginCapture();
    Q_INVOKABLE void cancelCapture();
    Q_INVOKABLE bool isWindowAutoSelectionEnabled() const;
    Q_INVOKABLE void setSelectionRect(int x, int y, int width, int height);
    Q_INVOKABLE void updateCursorPoint(int x, int y, bool trackWindow = true);
    Q_INVOKABLE void moveSelectionBy(int dx, int dy);
    Q_INVOKABLE void moveSelectionTo(int x, int y);
    Q_INVOKABLE void resizeSelectionBy(int left, int top, int right, int bottom);
    Q_INVOKABLE void copy();
    Q_INVOKABLE void copyFullScreen();
    Q_INVOKABLE void save();
    Q_INVOKABLE void pin();

signals:
    void overlayVisibleChanged();
    void desktopGeometryChanged();
    void desktopScreensChanged();
    void desktopSnapshotUrlChanged();
    void magnifierImageUrlChanged();
    void selectionRectChanged();
    void currentColorStringChanged();
    void toastRequested(const QString& message);

private:
    void refreshSessionPresentation();
    QUrl writeImageToTempFile(const QString& prefix, const QImage& image) const;

    CaptureSessionController* controller_ = nullptr;
    QRect desktopGeometry_;
    QVariantList desktopScreens_;
    QUrl desktopSnapshotUrl_;
    QUrl magnifierImageUrl_;
    QString currentColorString_ = "#000000";
};

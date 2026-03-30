#pragma once

#include <QImage>
#include <QPointer>
#include <QString>
#include <QTimer>
#include <QVector>

#include <memory>

#include <QObject>

#include "core/capture/FreezeOverlayWidget.h"
#include "core/capture/INativeScreenHelper.h"

class ClipboardManager;
class SettingsManager;
class QWindow;

class CaptureCoordinator final : public QObject {
    Q_OBJECT

public:
    explicit CaptureCoordinator(std::unique_ptr<INativeScreenHelper> helper,
                                ClipboardManager* clipboardManager,
                                SettingsManager* settingsManager,
                                QObject* parent = nullptr);

    void triggerCapture();
    void cancelCapture();
    bool isCaptureActive() const;
    QString backendName() const;

signals:
    void captureActiveChanged();
    void captureCanceling();
    void captureCompleting();
    void captureCompleted(const SelectionResult& result, const QImage& image);
    void captureCanceled();
    void captureError(const QString& message);
    void colorCopied(const QString& colorValue,
                     const QString& swatchHex,
                     const QPoint& globalPoint);

private:
    struct HiddenWindowState {
        QPointer<QWindow> window;
        int visibility = 0;
        bool isPrimaryWindow = false;
    };

    void performCapture();
    void closeOverlays();
    QImage selectedImageForResult(const SelectionResult& result) const;
    void completeCopy(const SelectionResult& result);
    void completeSave(const SelectionResult& result, QWidget* dialogParent);
    void finishCanceled();
    void finishError(const QString& message);
    void finishCompleted(const SelectionResult& result, const QImage& image);
    void hideOwnWindowsForCapture();
    void hidePrimaryWindowForInteraction();
    void restoreHiddenWindows(bool includePrimaryWindow);
    void setCaptureActive(bool active);

    std::unique_ptr<INativeScreenHelper> helper_;
    ClipboardManager* clipboardManager_ = nullptr;
    SettingsManager* settingsManager_ = nullptr;
    QVector<QPointer<FreezeOverlayWidget>> overlays_;
    QVector<HiddenWindowState> hiddenWindows_;
    CaptureResult currentCapture_;
    bool captureActive_ = false;
    QTimer prepareTimer_;
};

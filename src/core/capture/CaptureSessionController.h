#pragma once

#include <QColor>
#include <QImage>
#include <QList>
#include <QObject>
#include <QPoint>
#include <QRect>
#include <QElapsedTimer>

#include "core/annotation/AnnotationManager.h"
#include "domain/models/DesktopSnapshot.h"

class ClipboardManager;
class ScreenCaptureManager;

class CaptureSessionController final : public QObject {
    Q_OBJECT

public:
    enum class CaptureState {
        Idle,
        Selecting,
        Selected,
        Annotating,
        Exporting,
        Cancelled
    };
    Q_ENUM(CaptureState)
    Q_PROPERTY(QRect selectionRect READ selectionRect NOTIFY selectionRectChanged)
    Q_PROPERTY(CaptureState state READ state NOTIFY stateChanged)

    explicit CaptureSessionController(ScreenCaptureManager* screenCaptureManager,
                                      ClipboardManager* clipboardManager,
                                      AnnotationManager* annotationManager,
                                      QObject* parent = nullptr);

    QRect desktopGeometry() const;
    QImage desktopImage() const;
    QList<DesktopScreenInfo> screens() const;
    QRect selectionRect() const;
    CaptureState state() const;

    Q_INVOKABLE void beginSession();
    Q_INVOKABLE void setWindowAutoSelectionEnabled(bool enabled);
    Q_INVOKABLE bool isWindowAutoSelectionEnabled() const;
    Q_INVOKABLE void moveSelectionTo(int x, int y);
    Q_INVOKABLE void copyFullScreen();
    Q_INVOKABLE void cancelSession();
    Q_INVOKABLE void updateSelection(const QRect& rect);
    Q_INVOKABLE void updateCursorPoint(const QPoint& point, bool trackWindow = true);
    Q_INVOKABLE void nudgeSelection(int dx, int dy);
    Q_INVOKABLE void resizeSelection(int left, int top, int right, int bottom);
    Q_INVOKABLE void enterAnnotating();
    Q_INVOKABLE void copyResultToClipboard();
    Q_INVOKABLE void saveResultToFile(const QString& path);
    Q_INVOKABLE void pinResult();

signals:
    void stateChanged();
    void selectionRectChanged();
    void magnifierUpdated(const QImage& image, const QColor& color);
    void sessionCompleted(const QImage& resultImage);

private:
    QImage exportImage() const;
    void resetSessionData();
    void setState(CaptureState state);
    void recordWindowHitLatency(qint64 sessionTimeUs, qint64 latencyMicros);
    void reportWindowHitLatencySnapshot(const QString& reason) const;
    static qint64 quantileUs(const QList<qint64>& samplesUs, double q);

    struct HoverWindowLatencySample {
        qint64 elapsedSinceSessionUs = 0;
        qint64 latencyUs = 0;
    };

    bool isHoverLatencyProfilingEnabled() const;

    ScreenCaptureManager* screenCaptureManager_ = nullptr;
    ClipboardManager* clipboardManager_ = nullptr;
    AnnotationManager* annotationManager_ = nullptr;
    bool allowWindowAutoSelection_ = true;
    DesktopSnapshot desktopSnapshot_;
    QRect selectionRect_;
    CaptureState state_ = CaptureState::Idle;

    QList<HoverWindowLatencySample> hoverWindowLatencySamples_;
    QElapsedTimer hoverLatencyTimer_;
    qint64 lastHoverLatencyLogUs_ = 0;
};

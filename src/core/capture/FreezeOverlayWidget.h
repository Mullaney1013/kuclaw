#pragma once

#include <QColor>
#include <QTimer>
#include <QVariantAnimation>
#include <QWidget>

#include "core/capture/INativeScreenHelper.h"

class QFrame;
class QLabel;
class QPushButton;

class FreezeOverlayWidget final : public QWidget {
    Q_OBJECT

public:
    explicit FreezeOverlayWidget(QWidget* parent = nullptr);

    void setCaptureData(const CaptureResult& capture,
                        QVector<WindowCandidate> candidates);
    void setScreenGeometry(const QRect& screenGeometry);
    void setMagnifierEnabled(bool enabled);
    void setDefaultColorFormat(const QString& format);

signals:
    void selectionConfirmed(const SelectionResult& result);
    void selectionSaveRequested(const SelectionResult& result);
    void selectionCanceled();
    void colorPicked(const QString& colorValue,
                     const QString& swatchHex,
                     const QPoint& globalPoint);

protected:
    void paintEvent(QPaintEvent* event) override;
    void mouseMoveEvent(QMouseEvent* event) override;
    void mousePressEvent(QMouseEvent* event) override;
    void mouseReleaseEvent(QMouseEvent* event) override;
    void keyPressEvent(QKeyEvent* event) override;

private:
    enum class SelectionHandle {
        None,
        Move,
        Left,
        Right,
        Top,
        Bottom,
        TopLeft,
        TopRight,
        BottomLeft,
        BottomRight,
    };

    QPoint globalToOverlayPoint(const QPointF& globalPoint) const;
    QPoint localToOverlayPoint(const QPoint& localPoint) const;
    QRect overlayToLocalRect(const QRect& overlayRect) const;
    QRect screenSelectionOverlayRect() const;
    QRect visibleHoverRectForIndex(int index) const;
    QRect visibleScreenSelectionRect() const;
    QRect normalizedSelectionRect(const QPoint& start, const QPoint& end) const;
    QRect normalizedBoundsRect(int left, int top, int right, int bottom) const;
    int hitTestCandidateIndex(const QPoint& overlayPos) const;
    QRect visibleCommittedRect() const;
    QVector<QRect> visibleHandleRects() const;
    QRect visibleInfoRect() const;
    QRect visibleMagnifierRect() const;
    QRect visibleSafeAreaRect() const;
    QPoint infoAnchorLocalPoint() const;
    QPoint magnifierAnchorLocalPoint() const;
    bool sampleColorAtOverlayPoint(const QPoint& overlayPoint, QColor* outColor) const;
    QString formattedPointerColor() const;
    QString currentInfoAppName() const;
    void updateCopyHintMarkup(qreal emphasis);
    void triggerCopyHintFlash();
    void clearCommittedSelection();
    void commitSelection(const SelectionResult& result);
    void updateCommittedSelectionRect(const QRect& newRect);
    void setHoverState(int newIndex, bool useScreenFallback);
    void setManualSelectionRect(const QRect& newRect);
    void updateToolbarGeometry();
    void updateInfoGeometry();
    void updateMagnifier();
    void updatePointerColor();
    SelectionHandle hitTestCommittedSelection(const QPoint& overlayPos) const;
    void updateCursorForPoint(const QPoint& overlayPos);
    void updateCommittedInteraction(const QPoint& overlayPos);
    SelectionResult buildSelectionResult(const WindowCandidate& candidate) const;
    SelectionResult buildManualSelectionResult() const;
    SelectionResult buildScreenSelectionResult() const;

    CaptureResult capture_;
    QVector<WindowCandidate> candidates_;
    QRect screenGeometry_;
    QRect screenAvailableGeometry_;
    SelectionResult committedSelection_;
    bool selectionCommitted_ = false;
    int hoverIndex_ = -1;
    bool hoverUsesScreenFallback_ = false;
    QRect hoverRect_;
    bool leftButtonPressed_ = false;
    bool manualSelectionActive_ = false;
    int pressedCandidateIndex_ = -1;
    bool pressedScreenFallback_ = false;
    bool hasPointerOverlayPoint_ = false;
    QPoint pointerOverlayPoint_;
    bool hasPointerColor_ = false;
    QColor pointerColor_;
    QRect lastMagnifierRect_;
    QPoint pressOverlayPoint_;
    QRect pressCommittedRect_;
    SelectionHandle activeSelectionHandle_ = SelectionHandle::None;
    QRect manualSelectionRect_;
    QFrame* toolbar_ = nullptr;
    QFrame* infoPanel_ = nullptr;
    QLabel* copyHintLabel_ = nullptr;
    QPushButton* copyButton_ = nullptr;
    QPushButton* saveButton_ = nullptr;
    QPushButton* cancelButton_ = nullptr;
    bool magnifierEnabled_ = true;
    bool colorFormatHex_ = false;
    QTimer copyHintHoldTimer_;
    QVariantAnimation copyHintFadeAnimation_;
};

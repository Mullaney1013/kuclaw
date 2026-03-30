#pragma once

#include <memory>
#include <vector>

#include <QObject>
#include <QImage>
#include <QRectF>

enum class AnnotationTool {
    None,
    Rectangle,
    Arrow,
    Text
};

class AnnotationItem {
public:
    virtual ~AnnotationItem() = default;
    virtual QRectF boundingRect() const = 0;
};

class AnnotationManager final : public QObject {
    Q_OBJECT

public:
    explicit AnnotationManager(QObject* parent = nullptr);

    AnnotationTool activeTool() const;
    void setActiveTool(AnnotationTool tool);

    void appendItem(std::unique_ptr<AnnotationItem> item);
    void clear();
    void undo();
    void redo();
    QImage renderOverlay(const QSize& targetSize) const;

signals:
    void activeToolChanged();
    void itemsChanged();

private:
    AnnotationTool activeTool_ = AnnotationTool::None;
    std::vector<std::unique_ptr<AnnotationItem>> items_;
    std::vector<std::unique_ptr<AnnotationItem>> redoItems_;
};

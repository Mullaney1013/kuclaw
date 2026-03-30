#include "core/annotation/AnnotationManager.h"

AnnotationManager::AnnotationManager(QObject* parent)
    : QObject(parent) {}

AnnotationTool AnnotationManager::activeTool() const {
    return activeTool_;
}

void AnnotationManager::setActiveTool(AnnotationTool tool) {
    if (activeTool_ == tool) {
        return;
    }

    activeTool_ = tool;
    emit activeToolChanged();
}

void AnnotationManager::appendItem(std::unique_ptr<AnnotationItem> item) {
    if (!item) {
        return;
    }

    redoItems_.clear();
    items_.push_back(std::move(item));
    emit itemsChanged();
}

void AnnotationManager::clear() {
    items_.clear();
    redoItems_.clear();
    emit itemsChanged();
}

void AnnotationManager::undo() {
    if (items_.empty()) {
        return;
    }

    redoItems_.push_back(std::move(items_.back()));
    items_.pop_back();
    emit itemsChanged();
}

void AnnotationManager::redo() {
    if (redoItems_.empty()) {
        return;
    }

    items_.push_back(std::move(redoItems_.back()));
    redoItems_.pop_back();
    emit itemsChanged();
}

QImage AnnotationManager::renderOverlay(const QSize& targetSize) const {
    QImage overlay(targetSize, QImage::Format_ARGB32_Premultiplied);
    overlay.fill(Qt::transparent);
    return overlay;
}

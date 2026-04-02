#pragma once

#include <QGuiApplication>
#include <QWindow>
#include <Qt>

namespace ApplicationReopenPolicy {

inline bool hasVisiblePrimaryWindow(const QList<QWindow*>& windows) {
    for (QWindow* window : windows) {
        if (window == nullptr) {
            continue;
        }

        if (!window->isVisible()) {
            continue;
        }

        if (window->visibility() == QWindow::Minimized
            || window->visibility() == QWindow::Hidden) {
            continue;
        }

        if (window->flags().testFlag(Qt::Tool)
            || window->flags().testFlag(Qt::ToolTip)
            || window->flags().testFlag(Qt::Popup)) {
            continue;
        }

        return true;
    }

    return false;
}

inline bool shouldEmitReopenRequest(Qt::ApplicationState applicationState,
                                    const bool captureActive,
                                    const bool suppressNextReopen,
                                    const QList<QWindow*>& windows) {
    if (applicationState != Qt::ApplicationActive) {
        return false;
    }

    if (captureActive || suppressNextReopen) {
        return false;
    }

    return !hasVisiblePrimaryWindow(windows);
}

}  // namespace ApplicationReopenPolicy

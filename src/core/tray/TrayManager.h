#pragma once

#include <QObject>
#include <memory>

class QAction;
class QMenu;
class QSystemTrayIcon;

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
#include "core/tray/MacStatusItemBackend.h"
#endif

class TrayManager final : public QObject {
    Q_OBJECT

public:
    explicit TrayManager(QObject* parent = nullptr);
    ~TrayManager() override;

    void show();
    void hide();
    bool usesNativeMacStatusItemForTesting() const;
    bool isVisibleForTesting() const;
    bool hasRenderableIconForTesting() const;

signals:
    void captureRequested();
    void pinRequested();
    void restoreLastClosedPinRequested();
    void hideAllPinsRequested();
    void quitRequested();

private:
    void buildMenu();

    QSystemTrayIcon* trayIcon_ = nullptr;
    QMenu* menu_ = nullptr;
    QAction* captureAction_ = nullptr;
    QAction* pinAction_ = nullptr;
    QAction* restoreAction_ = nullptr;
    QAction* hideAllAction_ = nullptr;
    QAction* quitAction_ = nullptr;
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    std::unique_ptr<MacStatusItemBackend> macStatusItemBackend_;
#endif
};

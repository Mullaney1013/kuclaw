#include "core/tray/TrayManager.h"

#include <QAction>
#include <QIcon>
#include <QMenu>
#include <QSystemTrayIcon>

TrayManager::TrayManager(QObject* parent)
    : QObject(parent),
      trayIcon_(new QSystemTrayIcon(this)),
      menu_(new QMenu()) {
    buildMenu();
    trayIcon_->setContextMenu(menu_);
    trayIcon_->setToolTip("Kuclaw");
    trayIcon_->setIcon(QIcon::fromTheme("applications-graphics"));

    connect(trayIcon_, &QSystemTrayIcon::activated, this,
            [this](QSystemTrayIcon::ActivationReason reason) {
                if (reason == QSystemTrayIcon::Trigger) {
                    emit captureRequested();
                } else if (reason == QSystemTrayIcon::MiddleClick) {
                    emit pinRequested();
                }
            });
}

TrayManager::~TrayManager() {
    delete menu_;
}

void TrayManager::show() {
    if (QSystemTrayIcon::isSystemTrayAvailable()) {
        trayIcon_->show();
    }
}

void TrayManager::hide() {
    trayIcon_->hide();
}

void TrayManager::buildMenu() {
    captureAction_ = menu_->addAction("开始截图");
    pinAction_ = menu_->addAction("贴图");
    restoreAction_ = menu_->addAction("恢复最近关闭贴图");
    hideAllAction_ = menu_->addAction("隐藏所有贴图");
    menu_->addSeparator();
    quitAction_ = menu_->addAction("退出");

    connect(captureAction_, &QAction::triggered, this, &TrayManager::captureRequested);
    connect(pinAction_, &QAction::triggered, this, &TrayManager::pinRequested);
    connect(restoreAction_, &QAction::triggered, this, &TrayManager::restoreLastClosedPinRequested);
    connect(hideAllAction_, &QAction::triggered, this, &TrayManager::hideAllPinsRequested);
    connect(quitAction_, &QAction::triggered, this, &TrayManager::quitRequested);
}

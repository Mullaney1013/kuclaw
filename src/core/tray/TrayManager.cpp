#include "core/tray/TrayManager.h"

#include <QAction>
#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QIcon>
#include <QMenu>
#include <QSystemTrayIcon>

#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
#include "core/tray/MacStatusItemBackend.h"
#endif

namespace {

QString macMenuBarIconPath() {
    const QString appDir = QCoreApplication::applicationDirPath();
    const QString bundleResourcePath =
        QDir(appDir).absoluteFilePath(QStringLiteral("../Resources/assets/icons/icon.icns"));
    if (QFileInfo::exists(bundleResourcePath)) {
        return QFileInfo(bundleResourcePath).absoluteFilePath();
    }

    return QStringLiteral("/Users/Y/Documents/kuclaw/assets/icons/icon.icns");
}

}  // namespace

TrayManager::TrayManager(QObject* parent)
    : QObject(parent) {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    macStatusItemBackend_ = std::make_unique<MacStatusItemBackend>(
        MacStatusItemBackend::Callbacks{
            .triggerCapture = [this]() { emit captureRequested(); },
            .middleClickPin = [this]() { emit pinRequested(); },
            .showCaptureMenuAction = [this]() { emit captureRequested(); },
            .showPinMenuAction = [this]() { emit pinRequested(); },
            .showRestoreMenuAction = [this]() { emit restoreLastClosedPinRequested(); },
            .showHideAllMenuAction = [this]() { emit hideAllPinsRequested(); },
            .showQuitMenuAction = [this]() { emit quitRequested(); },
        });
    macStatusItemBackend_->setToolTip(QStringLiteral("Kuclaw"));
    macStatusItemBackend_->setTemplateImageFile(macMenuBarIconPath());
#else
    trayIcon_ = new QSystemTrayIcon(this);
    menu_ = new QMenu();
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
#endif
}

TrayManager::~TrayManager() {
    delete menu_;
}

void TrayManager::show() {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (macStatusItemBackend_) {
        macStatusItemBackend_->show();
    }
#else
    if (QSystemTrayIcon::isSystemTrayAvailable()) {
        trayIcon_->show();
    }
#endif
}

void TrayManager::hide() {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    if (macStatusItemBackend_) {
        macStatusItemBackend_->hide();
    }
#else
    trayIcon_->hide();
#endif
}

bool TrayManager::usesNativeMacStatusItemForTesting() const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    return macStatusItemBackend_ != nullptr;
#else
    return false;
#endif
}

bool TrayManager::isVisibleForTesting() const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    return macStatusItemBackend_ != nullptr && macStatusItemBackend_->isVisible();
#else
    return trayIcon_ != nullptr && trayIcon_->isVisible();
#endif
}

bool TrayManager::hasRenderableIconForTesting() const {
#if defined(Q_OS_MACOS) || defined(Q_OS_MAC)
    return macStatusItemBackend_ != nullptr && macStatusItemBackend_->hasRenderableImage();
#else
    return trayIcon_ != nullptr && !trayIcon_->icon().isNull();
#endif
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

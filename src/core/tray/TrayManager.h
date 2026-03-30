#pragma once

#include <QObject>

class QAction;
class QMenu;
class QSystemTrayIcon;

class TrayManager final : public QObject {
    Q_OBJECT

public:
    explicit TrayManager(QObject* parent = nullptr);
    ~TrayManager() override;

    void show();
    void hide();

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
};

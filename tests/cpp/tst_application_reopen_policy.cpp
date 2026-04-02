#include <QtTest>
#include <QWindow>

#include "app/ApplicationReopenPolicy.h"

class ApplicationReopenPolicyTest : public QObject {
    Q_OBJECT

private slots:
    void hasVisiblePrimaryWindowIgnoresHiddenAndToolWindows();
    void shouldEmitReopenRequestSkipsStartupWhenPrimaryWindowIsAlreadyVisible();
};

void ApplicationReopenPolicyTest::hasVisiblePrimaryWindowIgnoresHiddenAndToolWindows() {
    QWindow toolWindow;
    toolWindow.setFlags(Qt::Tool);
    toolWindow.setVisibility(QWindow::Windowed);

    QWindow hiddenWindow;
    hiddenWindow.setVisibility(QWindow::Hidden);

    QVERIFY(!ApplicationReopenPolicy::hasVisiblePrimaryWindow({ &toolWindow, &hiddenWindow }));

    QWindow mainWindow;
    mainWindow.setVisibility(QWindow::Windowed);

    QVERIFY(ApplicationReopenPolicy::hasVisiblePrimaryWindow({ &toolWindow, &hiddenWindow, &mainWindow }));
}

void ApplicationReopenPolicyTest::shouldEmitReopenRequestSkipsStartupWhenPrimaryWindowIsAlreadyVisible() {
    QWindow mainWindow;
    mainWindow.setVisibility(QWindow::Windowed);

    QVERIFY(!ApplicationReopenPolicy::shouldEmitReopenRequest(Qt::ApplicationActive,
                                                              false,
                                                              false,
                                                              { &mainWindow }));

    QVERIFY(ApplicationReopenPolicy::shouldEmitReopenRequest(Qt::ApplicationActive,
                                                             false,
                                                             false,
                                                             {}));
}

QTEST_MAIN(ApplicationReopenPolicyTest)

#include "tst_application_reopen_policy.moc"

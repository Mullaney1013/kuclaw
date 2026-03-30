# macOS Native Traffic Lights Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the self-drawn traffic lights in the macOS workspace shell with native `NSWindow` controls while preserving the approved Figma shell layout.

**Architecture:** Add a small macOS-only window-chrome adapter in Objective-C++ to configure the backing `NSWindow`, expose traffic-light layout metrics through a lightweight Qt view-model, and then update the QML shell to hide the fake buttons on macOS and reserve a real safe area for the native controls. Keep visual layout calculations testable in a small pure-JS helper so QML behavior can be verified without a running Cocoa window.

**Tech Stack:** Qt 6 QML, C++20, Objective-C++, AppKit (`NSWindow`, standard window buttons), `qmltestrunner`, CMake.

---

## File Map

- Create: [`/Users/Y/Documents/kuclaw/src/integration/platform/MacWindowChrome.h`](/Users/Y/Documents/kuclaw/src/integration/platform/MacWindowChrome.h)
- Create: [`/Users/Y/Documents/kuclaw/src/integration/platform/MacWindowChrome.mm`](/Users/Y/Documents/kuclaw/src/integration/platform/MacWindowChrome.mm)
- Create: [`/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/WindowChromeViewModel.h`](/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/WindowChromeViewModel.h)
- Create: [`/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/WindowChromeViewModel.cpp`](/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/WindowChromeViewModel.cpp)
- Create: [`/Users/Y/Documents/kuclaw/qml/app/TitleBarLayout.js`](/Users/Y/Documents/kuclaw/qml/app/TitleBarLayout.js)
- Create: [`/Users/Y/Documents/kuclaw/tests/qml/tst_title_bar_layout.qml`](/Users/Y/Documents/kuclaw/tests/qml/tst_title_bar_layout.qml)
- Modify: [`/Users/Y/Documents/kuclaw/qml/app/AppShell.qml`](/Users/Y/Documents/kuclaw/qml/app/AppShell.qml)
- Modify: [`/Users/Y/Documents/kuclaw/qml/app/TitleBarControls.qml`](/Users/Y/Documents/kuclaw/qml/app/TitleBarControls.qml)
- Modify: [`/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.h`](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.h)
- Modify: [`/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.cpp`](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.cpp)
- Modify: [`/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/main.cpp`](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/main.cpp)
- Modify: [`/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt`](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt)
- Test: [`/Users/Y/Documents/kuclaw/tests/qml/tst_title_bar_controls.qml`](/Users/Y/Documents/kuclaw/tests/qml/tst_title_bar_controls.qml)
- Test: [`/Users/Y/Documents/kuclaw/tests/qml/tst_title_bar_layout.qml`](/Users/Y/Documents/kuclaw/tests/qml/tst_title_bar_layout.qml)

## Task 1: Add Testable Title-Bar Layout Rules

**Files:**
- Create: [`/Users/Y/Documents/kuclaw/qml/app/TitleBarLayout.js`](/Users/Y/Documents/kuclaw/qml/app/TitleBarLayout.js)
- Create: [`/Users/Y/Documents/kuclaw/tests/qml/tst_title_bar_layout.qml`](/Users/Y/Documents/kuclaw/tests/qml/tst_title_bar_layout.qml)
- Modify: [`/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt`](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt)

- [ ] **Step 1: Write the failing QML test for native-title-bar metrics**

Create [`/Users/Y/Documents/kuclaw/tests/qml/tst_title_bar_layout.qml`](/Users/Y/Documents/kuclaw/tests/qml/tst_title_bar_layout.qml):

```qml
import QtQuick
import QtTest
import "../../qml/app/TitleBarLayout.js" as TitleBarLayout

TestCase {
    name: "TitleBarLayout"

    function test_native_mac_metrics_shift_toggle_and_hide_fake_lights() {
        const metrics = {
            usesNativeTrafficLights: true,
            trafficLightsSafeWidth: 78,
            titleBarHeight: 32
        }

        compare(TitleBarLayout.showCustomTrafficLights(metrics), false)
        compare(TitleBarLayout.sidebarToggleLeftMargin(metrics), 94)
        compare(TitleBarLayout.sidebarTopPadding(56, metrics), 68)
    }

    function test_non_native_metrics_keep_existing_shell_defaults() {
        const metrics = {
            usesNativeTrafficLights: false,
            trafficLightsSafeWidth: 0,
            titleBarHeight: 0
        }

        compare(TitleBarLayout.showCustomTrafficLights(metrics), true)
        compare(TitleBarLayout.sidebarToggleLeftMargin(metrics), 94)
        compare(TitleBarLayout.sidebarTopPadding(56, metrics), 90)
    }
}
```

- [ ] **Step 2: Run the new test to confirm it fails**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml -platform offscreen
```

Expected:
- FAIL because `TitleBarLayout.js` does not exist yet

- [ ] **Step 3: Add the minimal layout helper**

Create [`/Users/Y/Documents/kuclaw/qml/app/TitleBarLayout.js`](/Users/Y/Documents/kuclaw/qml/app/TitleBarLayout.js):

```javascript
.pragma library

function showCustomTrafficLights(metrics) {
    return !metrics || !metrics.usesNativeTrafficLights;
}

function sidebarToggleLeftMargin(metrics) {
    if (!metrics || !metrics.usesNativeTrafficLights) {
        return 94;
    }

    return metrics.trafficLightsSafeWidth + 16;
}

function sidebarTopPadding(toolbarHeight, metrics) {
    if (!metrics || !metrics.usesNativeTrafficLights) {
        return toolbarHeight + 34;
    }

    return Math.max(toolbarHeight + 12, metrics.titleBarHeight + 36);
}

function contentTopMargin(toolbarHeight, metrics) {
    if (!metrics || !metrics.usesNativeTrafficLights) {
        return toolbarHeight + 24;
    }

    return toolbarHeight + 18;
}
```

Then add it to [`/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt`](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt):

```cmake
set(KUCLAW_QML_FILES
    ${CMAKE_SOURCE_DIR}/qml/app/Main.qml
    ${CMAKE_SOURCE_DIR}/qml/app/AppShell.qml
    ${CMAKE_SOURCE_DIR}/qml/app/AutomationSectionStyles.js
    ${CMAKE_SOURCE_DIR}/qml/app/WorkspaceShellState.js
    ${CMAKE_SOURCE_DIR}/qml/app/TitleBarControls.qml
    ${CMAKE_SOURCE_DIR}/qml/app/ShellNavigation.js
    ${CMAKE_SOURCE_DIR}/qml/app/WorkspaceSelection.js
    ${CMAKE_SOURCE_DIR}/qml/app/TitleBarLayout.js
    ...
)

set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/app/TitleBarLayout.js
    PROPERTIES QT_RESOURCE_ALIAS app/TitleBarLayout.js
)
```

- [ ] **Step 4: Re-run the test suite to confirm the helper passes**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml -platform offscreen
```

Expected:
- PASS for `tst_title_bar_layout.qml`
- existing QML tests still pass

- [ ] **Step 5: Commit the helper and tests**

```bash
git add /Users/Y/Documents/kuclaw/qml/app/TitleBarLayout.js /Users/Y/Documents/kuclaw/tests/qml/tst_title_bar_layout.qml /Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt
git commit -m "Add title bar layout helper for native macOS chrome"
```

## Task 2: Add the Native macOS Chrome Bridge

**Files:**
- Create: [`/Users/Y/Documents/kuclaw/src/integration/platform/MacWindowChrome.h`](/Users/Y/Documents/kuclaw/src/integration/platform/MacWindowChrome.h)
- Create: [`/Users/Y/Documents/kuclaw/src/integration/platform/MacWindowChrome.mm`](/Users/Y/Documents/kuclaw/src/integration/platform/MacWindowChrome.mm)
- Create: [`/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/WindowChromeViewModel.h`](/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/WindowChromeViewModel.h)
- Create: [`/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/WindowChromeViewModel.cpp`](/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/WindowChromeViewModel.cpp)
- Modify: [`/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.h`](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.h)
- Modify: [`/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.cpp`](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.cpp)
- Modify: [`/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/main.cpp`](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/main.cpp)
- Modify: [`/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt`](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt)

- [ ] **Step 1: Add the bridge header and view-model interface**

Create [`/Users/Y/Documents/kuclaw/src/integration/platform/MacWindowChrome.h`](/Users/Y/Documents/kuclaw/src/integration/platform/MacWindowChrome.h):

```cpp
#pragma once

#include <QPointer>
#include <QWindow>

struct WindowChromeMetrics {
    bool usesNativeTrafficLights = false;
    int trafficLightsSafeWidth = 0;
    int titleBarHeight = 0;
};

class MacWindowChrome final {
public:
    WindowChromeMetrics attach(QWindow* window);
};
```

Create [`/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/WindowChromeViewModel.h`](/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/WindowChromeViewModel.h):

```cpp
#pragma once

#include <QObject>
#include <QWindow>

#include \"integration/platform/MacWindowChrome.h\"

class WindowChromeViewModel final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool usesNativeTrafficLights READ usesNativeTrafficLights NOTIFY metricsChanged)
    Q_PROPERTY(int trafficLightsSafeWidth READ trafficLightsSafeWidth NOTIFY metricsChanged)
    Q_PROPERTY(int titleBarHeight READ titleBarHeight NOTIFY metricsChanged)

public:
    explicit WindowChromeViewModel(QObject* parent = nullptr);

    bool usesNativeTrafficLights() const;
    int trafficLightsSafeWidth() const;
    int titleBarHeight() const;

    Q_INVOKABLE void attach(QObject* windowObject);

signals:
    void metricsChanged();

private:
    void setMetrics(const WindowChromeMetrics& metrics);

    WindowChromeMetrics metrics_;
};
```

- [ ] **Step 2: Implement the macOS-only bridge**

Create [`/Users/Y/Documents/kuclaw/src/integration/platform/MacWindowChrome.mm`](/Users/Y/Documents/kuclaw/src/integration/platform/MacWindowChrome.mm):

```objective-c++
#include \"integration/platform/MacWindowChrome.h\"

#include <QGuiApplication>
#include <QWindow>
#include <qpa/qplatformnativeinterface.h>

#if defined(Q_OS_MACOS)
#import <AppKit/AppKit.h>
#endif

WindowChromeMetrics MacWindowChrome::attach(QWindow* window)
{
    WindowChromeMetrics metrics;

#if defined(Q_OS_MACOS)
    if (!window) {
        return metrics;
    }

    auto* nativeInterface = QGuiApplication::platformNativeInterface();
    auto* nsWindow = static_cast<NSWindow*>(
        nativeInterface->nativeResourceForWindow(QByteArrayLiteral(\"nswindow\"), window));
    if (!nsWindow) {
        return metrics;
    }

    nsWindow.titleVisibility = NSWindowTitleHidden;
    nsWindow.titlebarAppearsTransparent = YES;
    nsWindow.styleMask |= NSWindowStyleMaskFullSizeContentView;

    NSButton* closeButton = [nsWindow standardWindowButton:NSWindowCloseButton];
    NSButton* zoomButton = [nsWindow standardWindowButton:NSWindowZoomButton];
    if (!closeButton || !zoomButton) {
        return metrics;
    }

    const NSRect closeFrame = closeButton.frame;
    const NSRect zoomFrame = zoomButton.frame;
    const CGFloat leftInset = NSMinX(closeFrame);
    const CGFloat rightEdge = NSMaxX(zoomFrame);

    metrics.usesNativeTrafficLights = true;
    metrics.trafficLightsSafeWidth = qCeil(rightEdge + leftInset);
    metrics.titleBarHeight = qCeil(NSHeight(nsWindow.frameRectForContentRect(nsWindow.contentLayoutRect)));
#endif

    return metrics;
}
```

Create [`/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/WindowChromeViewModel.cpp`](/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/WindowChromeViewModel.cpp):

```cpp
#include \"ui_bridge/viewmodels/WindowChromeViewModel.h\"

#include <QWindow>

WindowChromeViewModel::WindowChromeViewModel(QObject* parent)
    : QObject(parent) {}

bool WindowChromeViewModel::usesNativeTrafficLights() const { return metrics_.usesNativeTrafficLights; }
int WindowChromeViewModel::trafficLightsSafeWidth() const { return metrics_.trafficLightsSafeWidth; }
int WindowChromeViewModel::titleBarHeight() const { return metrics_.titleBarHeight; }

void WindowChromeViewModel::attach(QObject* windowObject)
{
    auto* window = qobject_cast<QWindow*>(windowObject);
    if (!window) {
        return;
    }

    MacWindowChrome chrome;
    setMetrics(chrome.attach(window));
}

void WindowChromeViewModel::setMetrics(const WindowChromeMetrics& metrics)
{
    if (metrics_.usesNativeTrafficLights == metrics.usesNativeTrafficLights
        && metrics_.trafficLightsSafeWidth == metrics.trafficLightsSafeWidth
        && metrics_.titleBarHeight == metrics.titleBarHeight) {
        return;
    }

    metrics_ = metrics;
    emit metricsChanged();
}
```

- [ ] **Step 3: Register and expose the new view-model**

Update [`/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.h`](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.h):

```cpp
#include \"ui_bridge/viewmodels/WindowChromeViewModel.h\"
...
    WindowChromeViewModel* windowChromeViewModel();
...
    WindowChromeViewModel windowChromeViewModel_;
```

Update [`/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.cpp`](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.cpp):

```cpp
      settingsViewModel_(&settingsManager_, this),
      windowChromeViewModel_(this) {
```

and:

```cpp
WindowChromeViewModel* ApplicationCoordinator::windowChromeViewModel() {
    return &windowChromeViewModel_;
}
```

Update [`/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/main.cpp`](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/main.cpp):

```cpp
engine.rootContext()->setContextProperty(\"windowChromeViewModel\",
                                         coordinator.windowChromeViewModel());
```

Update [`/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt`](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt) so the new `.cpp` and `.mm` files are compiled.

- [ ] **Step 4: Build to confirm the bridge compiles cleanly**

Run:

```bash
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

Expected:
- PASS
- no unresolved symbol errors for `MacWindowChrome` or `WindowChromeViewModel`

- [ ] **Step 5: Commit the bridge layer**

```bash
git add /Users/Y/Documents/kuclaw/src/integration/platform/MacWindowChrome.h /Users/Y/Documents/kuclaw/src/integration/platform/MacWindowChrome.mm /Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/WindowChromeViewModel.h /Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/WindowChromeViewModel.cpp /Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.h /Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.cpp /Users/Y/Documents/kuclaw/apps/kuclaw-desktop/main.cpp /Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt
git commit -m "Add macOS native window chrome bridge"
```

## Task 3: Wire the QML Shell to Native Traffic Lights

**Files:**
- Modify: [`/Users/Y/Documents/kuclaw/qml/app/AppShell.qml`](/Users/Y/Documents/kuclaw/qml/app/AppShell.qml)
- Modify: [`/Users/Y/Documents/kuclaw/qml/app/TitleBarControls.qml`](/Users/Y/Documents/kuclaw/qml/app/TitleBarControls.qml)
- Modify: [`/Users/Y/Documents/kuclaw/tests/qml/tst_title_bar_controls.qml`](/Users/Y/Documents/kuclaw/tests/qml/tst_title_bar_controls.qml)

- [ ] **Step 1: Add a failing test for hiding fake traffic lights when native mode is enabled**

Extend [`/Users/Y/Documents/kuclaw/tests/qml/tst_title_bar_controls.qml`](/Users/Y/Documents/kuclaw/tests/qml/tst_title_bar_controls.qml):

```qml
    function test_custom_traffic_lights_can_be_hidden() {
        const subject = createSubject({ showTrafficLights: false })
        compare(subject.showTrafficLights, false)
        compare(subject.width > 0, true)
    }
```

- [ ] **Step 2: Run the QML tests to see the new assertion fail**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml -platform offscreen
```

Expected:
- FAIL because `TitleBarControls` does not yet expose `showTrafficLights`

- [ ] **Step 3: Update `TitleBarControls.qml` to support native mode**

Change [`/Users/Y/Documents/kuclaw/qml/app/TitleBarControls.qml`](/Users/Y/Documents/kuclaw/qml/app/TitleBarControls.qml):

```qml
Item {
    id: root

    property bool backEnabled: false
    property bool forwardEnabled: false
    property bool showTrafficLights: true
    property real sidebarToggleLeftMargin: 94
    ...

    Row {
        visible: root.showTrafficLights
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        ...
    }

    Item {
        anchors.left: parent.left
        anchors.leftMargin: root.sidebarToggleLeftMargin
        anchors.verticalCenter: parent.verticalCenter
        width: 82
        height: 18
        ...
    }
}
```

- [ ] **Step 4: Update `AppShell.qml` to attach the native bridge and reserve the safe area**

Apply these focused changes in [`/Users/Y/Documents/kuclaw/qml/app/AppShell.qml`](/Users/Y/Documents/kuclaw/qml/app/AppShell.qml):

```qml
import \"TitleBarLayout.js\" as TitleBarLayout
...
readonly property var chromeMetrics: ({
    usesNativeTrafficLights: windowChromeViewModel ? windowChromeViewModel.usesNativeTrafficLights : false,
    trafficLightsSafeWidth: windowChromeViewModel ? windowChromeViewModel.trafficLightsSafeWidth : 0,
    titleBarHeight: windowChromeViewModel ? windowChromeViewModel.titleBarHeight : 0
})
...
Component.onCompleted: {
    if (windowChromeViewModel) {
        windowChromeViewModel.attach(root)
    }
}
...
Column {
    visible: root.shellState.showExpandedSidebar
    anchors.topMargin: TitleBarLayout.sidebarTopPadding(root.toolbarHeight, root.chromeMetrics)
    ...
}
...
Item {
    anchors.fill: parent
    anchors.topMargin: TitleBarLayout.contentTopMargin(root.toolbarHeight, root.chromeMetrics)
    ...
}
...
TitleBarControls {
    id: titleBarControls
    anchors.left: parent.left
    anchors.leftMargin: 19
    showTrafficLights: TitleBarLayout.showCustomTrafficLights(root.chromeMetrics)
    sidebarToggleLeftMargin: TitleBarLayout.sidebarToggleLeftMargin(root.chromeMetrics)
    ...
}

MouseArea {
    anchors.left: titleBarControls.right
    ...
}
```

Also make the left title-bar background width include the native safe area in macOS:

```qml
width: Math.max(root.shellState.toolbarLeftWidth,
                root.chromeMetrics.usesNativeTrafficLights
                    ? root.chromeMetrics.trafficLightsSafeWidth + 44
                    : root.shellState.toolbarLeftWidth)
```

- [ ] **Step 5: Re-run tests and build**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml -platform offscreen
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

Expected:
- PASS for the extended `tst_title_bar_controls.qml`
- PASS for all existing QML tests
- build succeeds with the native bridge linked in

- [ ] **Step 6: Manual macOS verification**

Run:

```bash
pkill -x Kuclaw 2>/dev/null || true
/Users/Y/Documents/kuclaw/build/apps/kuclaw-desktop/Kuclaw.app/Contents/MacOS/Kuclaw
```

Check manually:
- native traffic lights are visible
- no fake QML traffic lights remain
- sidebar toggle is visible to the right of the traffic lights
- sidebar content begins below the safe area
- title bar stays draggable outside interactive controls

- [ ] **Step 7: Commit the QML integration**

```bash
git add /Users/Y/Documents/kuclaw/qml/app/AppShell.qml /Users/Y/Documents/kuclaw/qml/app/TitleBarControls.qml /Users/Y/Documents/kuclaw/tests/qml/tst_title_bar_controls.qml
git commit -m "Integrate native macOS traffic lights into workspace shell"
```

## Spec Coverage Check

- Native macOS buttons instead of self-drawn traffic lights: covered by Task 2 and Task 3
- Transparent/full-size title bar: covered by Task 2
- QML safe-area reservation and sidebar-toggle repositioning: covered by Task 1 and Task 3
- Manual validation of focus/hover/native behavior: covered by Task 3 Step 6
- Fallback to custom controls if native attachment fails: covered by Task 2 implementation because default metrics remain `usesNativeTrafficLights = false` unless the bridge succeeds

## Self-Review Notes

- Placeholder scan: no `TODO` or `TBD` markers remain
- Type consistency: all QML references use the same metrics names (`usesNativeTrafficLights`, `trafficLightsSafeWidth`, `titleBarHeight`)
- Scope check: plan stays limited to macOS traffic lights integration and does not reopen unrelated shell work

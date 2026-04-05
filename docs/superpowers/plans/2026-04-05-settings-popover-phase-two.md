# Settings Popover Phase Two Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make both sidebar `Settings` entry points open the same popover, and route the popover's `Settings` row into the existing full `Settings / Preferences` page without changing the approved phase-one popover visuals.

**Architecture:** Keep `SettingsPopover.qml` presentation-focused and let it emit semantic actions. Introduce one shared controller component that owns the popup instance, active trigger anchor, outside-click dismissal, and close-then-navigate sequencing. `AppShell.qml` remains the owner of `currentPage` and consumes the controller's `settingsRequested()` signal to enter the existing `SettingsPanel` route while preserving expanded-sidebar selection styling.

**Tech Stack:** Qt Quick, Qt Quick Controls `Popup`, QML unit tests via `qmltestrunner`, existing `AppShell.qml` shell routing, existing `SettingsPanel.qml`.

---

## File Map

- **Create:** `/Users/Y/Documents/kuclaw/qml/app/SidebarSettingsPopoverController.qml`
  - Shared popover owner for expanded and collapsed sidebar settings triggers.
- **Modify:** [/Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml](/Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml)
  - Make the `Settings` row emit `settingsClicked()` while keeping other rows non-operative.
- **Modify:** [/Users/Y/Documents/kuclaw/qml/app/ExpandedSidebarSettingsPopover.qml](/Users/Y/Documents/kuclaw/qml/app/ExpandedSidebarSettingsPopover.qml)
  - Convert from self-owning popup wrapper into a trigger-only visual shell driven by external state.
- **Modify:** [/Users/Y/Documents/kuclaw/qml/app/AppShell.qml](/Users/Y/Documents/kuclaw/qml/app/AppShell.qml)
  - Instantiate the shared controller, wire the expanded trigger and collapsed `settingsIcon`, and route `settingsRequested()` to the existing settings page.
- **Modify:** [/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt)
  - Register the new controller QML file in the desktop target.
- **Modify:** [/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml](/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml)
  - Extend phase-one tests with phase-two interaction coverage through a focused QML harness.
- **Modify:** [/Users/Y/Documents/kuclaw/PRD.md](/Users/Y/Documents/kuclaw/PRD.md)
  - Sync the new popover-to-settings routing once implementation passes.

## Constraints to Preserve

- Do not change the approved phase-one popover geometry, copy, dividers, or dismissal behavior.
- Do not add `Language` expansion, `Rate limits remaining` routing, or `Log out` behavior in this phase.
- The expanded sidebar `Settings` trigger must remain highlighted while the current page is `settings`, even after the popover closes.
- Both entry points must still be able to reopen the popover when the current page is already `settings`.

## Task 1: Make the Popover `Settings` Row Emit a Real Action

**Files:**
- Modify: `/Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml`
- Test: `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`

- [ ] **Step 1: Write the failing row-action test**

Extend `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml` with a new test that proves only the `Settings` row emits:

```qml
    function test_settings_row_emits_but_other_rows_stay_inert() {
        const subject = createSubject()
        const settingsHitArea = findByObjectName(subject, "settingsHitArea")
        const languageHitArea = findByObjectName(subject, "languageHitArea")
        const rateLimitsHitArea = findByObjectName(subject, "rateLimitsHitArea")
        const logOutHitArea = findByObjectName(subject, "logOutHitArea")
        let settingsCount = 0
        let languageCount = 0
        let rateLimitsCount = 0
        let logOutCount = 0

        verify(settingsHitArea !== null)
        verify(languageHitArea !== null)
        verify(rateLimitsHitArea !== null)
        verify(logOutHitArea !== null)

        subject.settingsClicked.connect(function() { settingsCount += 1 })
        subject.languageClicked.connect(function() { languageCount += 1 })
        subject.rateLimitsClicked.connect(function() { rateLimitsCount += 1 })
        subject.logOutClicked.connect(function() { logOutCount += 1 })

        subject.open()
        tryCompare(subject, "opened", true)

        mouseClick(settingsHitArea, 24, 24, Qt.LeftButton)
        mouseClick(languageHitArea, 24, 24, Qt.LeftButton)
        mouseClick(rateLimitsHitArea, 24, 24, Qt.LeftButton)
        mouseClick(logOutHitArea, 24, 24, Qt.LeftButton)

        compare(settingsCount, 1)
        compare(languageCount, 0)
        compare(rateLimitsCount, 0)
        compare(logOutCount, 0)
        verify(subject.opened)
    }
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- FAIL in `test_settings_row_emits_but_other_rows_stay_inert`
- `settingsCount` stays `0`

- [ ] **Step 3: Implement the minimal row click routing**

Update the `MouseArea` in `/Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml`:

```qml
        MouseArea {
            id: hitArea
            objectName: row.semanticId + "HitArea"
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: function(mouse) {
                mouse.accepted = true

                if (row.semanticId === "settings") {
                    root.settingsClicked()
                }
            }
        }
```

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- PASS for `test_settings_row_emits_but_other_rows_stay_inert`

- [ ] **Step 5: Commit**

```bash
git add /Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml \
        /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml
git commit -m "feat: emit settings action from popover"
```

## Task 2: Add a Shared Controller for Both Sidebar Entry Points

**Files:**
- Create: `/Users/Y/Documents/kuclaw/qml/app/SidebarSettingsPopoverController.qml`
- Modify: `/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt`
- Test: `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`

- [ ] **Step 1: Write the failing controller harness tests**

Add a phase-two harness and two tests to `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`:

```qml
    Component {
        id: phaseTwoHarnessComponent

        Item {
            id: shellHarness
            width: 640
            height: 900

            property string currentPage: "none"
            property int settingsRequests: 0

            Rectangle {
                id: expandedAnchor
                x: 24
                y: 820
                width: 264
                height: 52
            }

            Rectangle {
                id: railAnchor
                x: 20
                y: 820
                width: 44
                height: 44
            }

            SidebarSettingsPopoverController {
                id: controller
                email: "sinobec1013@gmail.com"
                accountLabel: "Personal account"
                expandedTriggerItem: expandedAnchor
                railTriggerItem: railAnchor
                onSettingsRequested: {
                    shellHarness.settingsRequests += 1
                    shellHarness.currentPage = "settings"
                }
            }
        }
    }

    function createPhaseTwoHarness() {
        return createTemporaryObject(phaseTwoHarnessComponent, host)
    }

    function test_controller_opens_from_both_anchor_types() {
        const harness = createPhaseTwoHarness()

        harness.controller.toggleExpandedPopover()
        tryCompare(harness.controller, "popoverOpen", true)
        compare(harness.controller.activeTriggerKind, "expanded")
        verify(harness.controller.settingsPopover.y + harness.controller.settingsPopover.height <= harness.expandedAnchor.y)

        harness.controller.toggleRailPopover()
        tryCompare(harness.controller, "popoverOpen", true)
        compare(harness.controller.activeTriggerKind, "rail")
        verify(harness.controller.settingsPopover.y + harness.controller.settingsPopover.height <= harness.railAnchor.y)
    }

    function test_controller_closes_then_requests_settings_navigation() {
        const harness = createPhaseTwoHarness()

        harness.controller.toggleExpandedPopover()
        tryCompare(harness.controller, "popoverOpen", true)

        const settingsHitArea = findByObjectName(harness.controller.settingsPopover, "settingsHitArea")
        mouseClick(settingsHitArea, 24, 24, Qt.LeftButton)

        tryCompare(harness.controller, "popoverOpen", false)
        compare(harness.settingsRequests, 1)
        compare(harness.currentPage, "settings")
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- FAIL because `SidebarSettingsPopoverController` does not exist

- [ ] **Step 3: Register the controller component**

Update `/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt` to register the new QML file:

```cmake
set(KUCLAW_QML_FILES
    ${CMAKE_SOURCE_DIR}/qml/app/Main.qml
    ${CMAKE_SOURCE_DIR}/qml/app/AppShell.qml
    ${CMAKE_SOURCE_DIR}/qml/app/SettingsPopover.qml
    ${CMAKE_SOURCE_DIR}/qml/app/SidebarSettingsPopoverController.qml
    ${CMAKE_SOURCE_DIR}/qml/app/AutomationSectionStyles.js
    ...
)

set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/app/SidebarSettingsPopoverController.qml
    PROPERTIES QT_RESOURCE_ALIAS app/SidebarSettingsPopoverController.qml
)
```

- [ ] **Step 4: Create the minimal shared controller**

Create `/Users/Y/Documents/kuclaw/qml/app/SidebarSettingsPopoverController.qml`:

```qml
import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string email: ""
    property string accountLabel: ""
    property Item expandedTriggerItem: null
    property Item railTriggerItem: null
    property var settingsPopover: null
    property string activeTriggerKind: ""
    readonly property bool popoverOpen: settingsPopover ? settingsPopover.opened : false

    signal settingsRequested()

    function anchorItemFor(kind) {
        return kind === "rail" ? railTriggerItem : expandedTriggerItem
    }

    function ensureSettingsPopover() {
        if (settingsPopover) {
            settingsPopover.email = root.email
            settingsPopover.accountLabel = root.accountLabel
            return
        }

        const popupParent = Overlay.overlay ? Overlay.overlay : root
        settingsPopover = settingsPopoverComponent.createObject(popupParent, {
            email: root.email,
            accountLabel: root.accountLabel
        })
    }

    function updatePopoverPosition() {
        if (!settingsPopover || !Overlay.overlay) {
            return
        }

        const anchorItem = anchorItemFor(activeTriggerKind)
        if (!anchorItem) {
            return
        }

        const anchor = anchorItem.mapToItem(Overlay.overlay, 0, 0)
        settingsPopover.x = Math.round(anchor.x + 20)
        settingsPopover.y = Math.round(anchor.y - settingsPopover.implicitHeight - 12)
    }

    function openFor(kind) {
        if (popoverOpen && activeTriggerKind === kind) {
            closePopover()
            return
        }

        activeTriggerKind = kind
        ensureSettingsPopover()
        updatePopoverPosition()
        settingsPopover.open()
        settingsPopover.forceActiveFocus()
    }

    function toggleExpandedPopover() {
        openFor("expanded")
    }

    function toggleRailPopover() {
        openFor("rail")
    }

    function closePopover() {
        if (settingsPopover && settingsPopover.opened) {
            settingsPopover.close()
        }
    }

    Component {
        id: settingsPopoverComponent

        SettingsPopover {
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            onOpenedChanged: {
                if (opened) {
                    root.updatePopoverPosition()
                }
            }
            onSettingsClicked: {
                root.closePopover()
                root.settingsRequested()
            }
        }
    }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- PASS for `test_controller_opens_from_both_anchor_types`
- PASS for `test_controller_closes_then_requests_settings_navigation`

- [ ] **Step 6: Commit**

```bash
git add /Users/Y/Documents/kuclaw/qml/app/SidebarSettingsPopoverController.qml \
        /Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt \
        /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml
git commit -m "feat: add shared settings popover controller"
```

## Task 3: Refactor the Expanded Trigger into a Pure Visual Trigger Shell

**Files:**
- Modify: `/Users/Y/Documents/kuclaw/qml/app/ExpandedSidebarSettingsPopover.qml`
- Test: `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`

- [ ] **Step 1: Write the failing trigger-state tests**

Extend `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`:

```qml
    Component {
        id: expandedTriggerComponent

        ExpandedSidebarSettingsPopover {
            width: 264
            email: "sinobec1013@gmail.com"
            accountLabel: "Personal account"
            popoverOpen: false
            selected: false
        }
    }

    function createExpandedTrigger(properties) {
        return createTemporaryObject(expandedTriggerComponent, host, properties || {})
    }

    function test_expanded_trigger_highlights_when_selected_even_if_popover_closed() {
        const trigger = createExpandedTrigger({ selected: true, popoverOpen: false })
        verify(trigger !== null)
        compare(trigger.selected, true)
        compare(trigger.visualState.labelWeight >= 500, true)
        compare(trigger.chrome.fill, "#E9EEF5")
    }

    function test_expanded_trigger_emits_toggle_requested() {
        const trigger = createExpandedTrigger()
        let toggleCount = 0
        trigger.toggleRequested.connect(function() { toggleCount += 1 })

        mouseClick(trigger.settingsTrigger, 24, 24, Qt.LeftButton)
        compare(toggleCount, 1)
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- FAIL because `ExpandedSidebarSettingsPopover` does not yet expose external `selected` / `popoverOpen` control or `toggleRequested`

- [ ] **Step 3: Refactor the trigger component**

Replace the self-owning popup logic in `/Users/Y/Documents/kuclaw/qml/app/ExpandedSidebarSettingsPopover.qml` with an externally controlled trigger shell:

```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "WorkspaceShellStyles.js" as WorkspaceShellStyles

Item {
    id: root

    property bool popoverOpen: false
    property bool selected: false
    readonly property alias settingsTrigger: settingsTrigger
    readonly property var metrics: WorkspaceShellStyles.expandedRowMetrics()
    readonly property var contentMetrics: WorkspaceShellStyles.expandedRowContentMetrics()
    readonly property var visualState: WorkspaceShellStyles.expandedRowVisualState(
                                           root.selected || root.popoverOpen,
                                           settingsTrigger.containsMouse,
                                           true
                                       )
    readonly property var chrome: visualState.chrome

    signal toggleRequested()

    implicitWidth: metrics.width
    implicitHeight: metrics.height

    Rectangle {
        anchors.fill: parent
        radius: root.metrics.radius
        color: root.chrome.fill
        border.color: root.chrome.border
        border.width: root.chrome.borderWidth
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.contentMetrics.horizontalPadding
        anchors.rightMargin: root.contentMetrics.horizontalPadding
        spacing: root.contentMetrics.spacing

        Image {
            Layout.preferredWidth: root.contentMetrics.iconSize
            Layout.preferredHeight: root.contentMetrics.iconSize
            source: Qt.resolvedUrl("../../assets/icons/settings.svg")
            opacity: root.visualState.iconOpacity
            fillMode: Image.PreserveAspectFit
        }

        Label {
            Layout.fillWidth: true
            text: "Settings"
            font.pixelSize: root.contentMetrics.labelSize
            font.weight: root.visualState.labelWeight >= 500 ? Font.Medium : Font.Normal
            color: root.visualState.labelColor
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: settingsTrigger
        objectName: "settingsTrigger"
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleRequested()
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- PASS for the two new trigger-state tests
- Existing phase-one structure tests still PASS

- [ ] **Step 5: Commit**

```bash
git add /Users/Y/Documents/kuclaw/qml/app/ExpandedSidebarSettingsPopover.qml \
        /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml
git commit -m "refactor: externalize settings trigger state"
```

## Task 4: Wire Both Sidebar Triggers Through AppShell and Sync PRD

**Files:**
- Modify: `/Users/Y/Documents/kuclaw/qml/app/AppShell.qml`
- Modify: `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`
- Modify: `/Users/Y/Documents/kuclaw/PRD.md`

- [ ] **Step 1: Write the failing AppShell-wiring tests**

Add a phase-two shell harness to `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml` that mirrors the final `AppShell` wiring:

```qml
    Component {
        id: appShellPhaseTwoHarnessComponent

        Item {
            id: shell
            width: 640
            height: 900

            property string currentPage: "none"

            function openSettingsPageFromPopover() {
                shell.currentPage = "settings"
            }

            SidebarSettingsPopoverController {
                id: controller
                email: "sinobec1013@gmail.com"
                accountLabel: "Personal account"
                expandedTriggerItem: expandedSettings.settingsTrigger
                railTriggerItem: collapsedSettingsTrigger
                onSettingsRequested: shell.openSettingsPageFromPopover()
            }

            ExpandedSidebarSettingsPopover {
                id: expandedSettings
                x: 24
                y: 820
                width: 264
                selected: shell.currentPage === "settings"
                popoverOpen: controller.popoverOpen && controller.activeTriggerKind === "expanded"
                onToggleRequested: controller.toggleExpandedPopover()
            }

            Rectangle {
                id: collapsedSettingsTrigger
                objectName: "collapsedSettingsTrigger"
                x: 20
                y: 820
                width: 44
                height: 44

                MouseArea {
                    anchors.fill: parent
                    onClicked: controller.toggleRailPopover()
                }
            }
        }
    }

    function createPhaseTwoShellHarness() {
        return createTemporaryObject(appShellPhaseTwoHarnessComponent, host)
    }

    function test_collapsed_trigger_opens_same_popover_pattern() {
        const harness = createPhaseTwoShellHarness()
        mouseClick(findByObjectName(harness, "collapsedSettingsTrigger"), 22, 22, Qt.LeftButton)
        tryCompare(harness.controller, "popoverOpen", true)
        compare(harness.controller.activeTriggerKind, "rail")
    }

    function test_settings_row_closes_popover_and_switches_to_settings_page() {
        const harness = createPhaseTwoShellHarness()
        harness.controller.toggleExpandedPopover()
        tryCompare(harness.controller, "popoverOpen", true)

        const settingsHitArea = findByObjectName(harness.controller.settingsPopover, "settingsHitArea")
        mouseClick(settingsHitArea, 24, 24, Qt.LeftButton)

        tryCompare(harness.controller, "popoverOpen", false)
        compare(harness.currentPage, "settings")
        compare(harness.expandedSettings.selected, true)
    }

    function test_both_triggers_can_reopen_popover_while_already_on_settings_page() {
        const harness = createPhaseTwoShellHarness()
        harness.currentPage = "settings"

        harness.controller.toggleExpandedPopover()
        tryCompare(harness.controller, "popoverOpen", true)
        harness.controller.closePopover()
        tryCompare(harness.controller, "popoverOpen", false)

        mouseClick(findByObjectName(harness, "collapsedSettingsTrigger"), 22, 22, Qt.LeftButton)
        tryCompare(harness.controller, "popoverOpen", true)
        compare(harness.controller.activeTriggerKind, "rail")
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- FAIL because the current `AppShell` wiring still leaves the collapsed icon on the old route and does not wire `settingsRequested()`

- [ ] **Step 3: Wire `AppShell` to the shared controller**

Update `/Users/Y/Documents/kuclaw/qml/app/AppShell.qml` with the shared controller and popover-aware triggers:

```qml
    function openSettingsPageFromPopover() {
        root.navigateToPage("settings")
        if (root.shellState.mode === "rail") {
            root.dispatchShellEvent("SIDEBAR_LEAVE")
        }
    }

    SidebarSettingsPopoverController {
        id: settingsPopoverController
        parent: root.contentItem
        email: "sinobec1013@gmail.com"
        accountLabel: "Personal account"
        expandedTriggerItem: settingsRow.settingsTrigger
        railTriggerItem: settingsIcon
        onSettingsRequested: root.openSettingsPageFromPopover()
    }
```

Replace the expanded trigger block with external state wiring:

```qml
        ExpandedSidebarSettingsPopover {
            id: settingsRow
            visible: root.shellState.showExpandedSidebar
            anchors.left: parent.left
            anchors.leftMargin: root.expandedSidebarLayout.sideMargin
            anchors.right: parent.right
            anchors.rightMargin: root.expandedSidebarLayout.sideMargin
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.expandedSidebarSettings.bottomMargin
            selected: root.currentPage === "settings"
            popoverOpen: settingsPopoverController.popoverOpen
                         && settingsPopoverController.activeTriggerKind === "expanded"
            onToggleRequested: settingsPopoverController.toggleExpandedPopover()
        }
```

Replace the collapsed `settingsIcon` with a dedicated click-only settings trigger so it no longer routes directly through `selectSidebarPage("settings")`:

```qml
            Item {
                id: settingsIcon
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: WorkspaceShellStyles.railIconMetrics().width
                height: WorkspaceShellStyles.railIconMetrics().height

                property bool selected: settingsPopoverController.popoverOpen
                                        && settingsPopoverController.activeTriggerKind === "rail"
                property bool hovered: settingsIconMouse.containsMouse
                readonly property var metrics: WorkspaceShellStyles.railIconMetrics()
                readonly property var chrome: WorkspaceShellStyles.railIconChrome(selected, hovered)

                Rectangle {
                    anchors.fill: parent
                    radius: settingsIcon.metrics.radius
                    color: settingsIcon.chrome.fill
                    border.color: settingsIcon.chrome.border
                    border.width: settingsIcon.chrome.borderWidth
                }

                MouseArea {
                    id: settingsIconMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsPopoverController.toggleRailPopover()
                }

                Image {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    fillMode: Image.PreserveAspectFit
                    source: "qrc:/qt/qml/Kuclaw/assets/icons/settings.svg"
                    opacity: settingsIcon.selected ? 0.9 : (settingsIcon.hovered ? 0.72 : 0.58)
                    sourceSize.width: 18
                    sourceSize.height: 18
                }
            }
```

- [ ] **Step 4: Run the QML tests and desktop build**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

Expected:
- All `SettingsPopover` tests PASS
- `kuclaw_desktop` builds successfully

- [ ] **Step 5: Sync PRD for phase two**

Update `/Users/Y/Documents/kuclaw/PRD.md` by extending the existing settings-popover section with:

```md
- Both sidebar settings entry points now open the same Settings Popover:
  - expanded sidebar bottom `Settings`
  - collapsed rail `settings` icon
- Clicking the popover's `Settings` row closes the popover and enters the full
  `Settings / Preferences` page.
- When the `Settings` page is active, the expanded sidebar bottom `Settings`
  trigger stays highlighted, and both entry points can still reopen the
  popover.
```

- [ ] **Step 6: Commit**

```bash
git add /Users/Y/Documents/kuclaw/qml/app/AppShell.qml \
        /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml \
        /Users/Y/Documents/kuclaw/PRD.md
git commit -m "feat: route settings popover into settings page"
```

## Verification Checklist

- Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

- Manual QA on macOS:
  - Expanded sidebar bottom `Settings` opens the popover above the trigger.
  - Collapsed rail `settingsIcon` opens the same popover pattern above the icon.
  - Clicking the popover `Settings` row closes the popover and opens the full settings page.
  - Expanded sidebar bottom `Settings` remains highlighted while on the settings page.
  - While already on the settings page, both triggers can reopen the popover.

## Self-Review

- **Spec coverage:** This plan covers both entry points, the close-then-navigate `Settings` action, and the expanded-trigger highlight requirement while keeping `Language`, `Rate limits remaining`, and `Log out` deferred.
- **Placeholder scan:** No `TODO`, `TBD`, or “implement later” placeholders remain; each task contains concrete file paths, test code, commands, and commit points.
- **Type consistency:** The same names are used across tasks for the shared controller (`SidebarSettingsPopoverController`), routing signal (`settingsRequested()`), trigger action (`toggleRequested()`), and page route (`"settings"`).

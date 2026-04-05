# Settings Popover Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the approved phase-one `Settings Popover` above the expanded sidebar `Settings` button, matching the confirmed Figma layout and keeping all popover rows visual-only.

**Architecture:** Introduce a dedicated `SettingsPopover.qml` `Popup` and let `AppShell.qml` own the single source of truth for visibility, placement, and trigger highlighting. Phase one is intentionally static: the popover opens, renders the approved sections, and closes via outside click / `Esc` / trigger toggle, but does not yet navigate, expand `Language`, or reuse the collapsed rail icon.

**Tech Stack:** Qt Quick, Qt Quick Controls `Popup`, QML unit tests via `qmltestrunner`, existing `WorkspaceShellStyles.js`, approved Figma review file `KRodgp2B8NeCvmRwsxLSNs`.

---

## File Map

- **Create:** `/Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml`
  - The reusable popover surface that matches the approved Figma layout.
- **Create:** `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`
  - Focused QML tests for static rendering and open/close behavior.
- **Modify:** [/Users/Y/Documents/kuclaw/qml/app/AppShell.qml](/Users/Y/Documents/kuclaw/qml/app/AppShell.qml)
  - Own popover state, toggle behavior, anchor geometry, trigger highlight, and close wiring.
- **Modify:** [/Users/Y/Documents/kuclaw/qml/app/WorkspaceShellStyles.js](/Users/Y/Documents/kuclaw/qml/app/WorkspaceShellStyles.js)
  - Add popover-specific dimensions and spacing constants based on the approved Figma.
- **Modify:** [/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt)
  - Register `SettingsPopover.qml` and the three new SVG assets.
- **Modify:** [/Users/Y/Documents/kuclaw/PRD.md](/Users/Y/Documents/kuclaw/PRD.md)
  - Sync the phase-one static popover behavior after implementation passes.

## Approved Figma Notes

From Figma file `KRodgp2B8NeCvmRwsxLSNs`, node `1:4` (`Settings Popover`):

- popover width: `420`
- popover height: `444`
- account section height: `78`
- middle section height: `252`
- logout section height: `86`
- outer top gap before account section: `26`
- row left content edge: `24`
- text start x relative to popover: `68`
- trailing chevron slot width: `18`
- trailing chevron slot x: `378`

Phase-one design details that must be preserved:

- top section is text-only:
  - `sinobec1013@gmail.com`
  - `Personal account`
- separators only appear:
  - below account section
  - above logout section
- `Settings`, `Language`, `Rate limits remaining`, `Log out` rows use icons
- `Language` and `Rate limits remaining` share the same right-aligned chevron slot
- `Rate limits remaining` is a two-line label in the approved layout
- trigger row stays highlighted while the popover is open

## Task 1: Register the Popover Component and Assets

**Files:**
- Create: `/Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml`
- Create: `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`
- Modify: [/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt)

- [ ] **Step 1: Write the failing smoke test**

Create `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`:

```qml
import QtQuick
import QtTest
import "../../qml/app"

TestCase {
    name: "SettingsPopover"

    Item {
        id: host
        width: 640
        height: 900
    }

    Component {
        id: subjectComponent

        SettingsPopover {
            email: "sinobec1013@gmail.com"
            accountLabel: "Personal account"
        }
    }

    function createSubject(properties) {
        return createTemporaryObject(subjectComponent, host, properties || {})
    }

    function test_component_loads_and_exposes_copy() {
        const subject = createSubject()
        verify(subject !== null)
        compare(subject.email, "sinobec1013@gmail.com")
        compare(subject.accountLabel, "Personal account")
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- FAIL with `SettingsPopover` not found or component load failure.

- [ ] **Step 3: Register the QML file and SVG assets**

Update [/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt](/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt):

```cmake
set(KUCLAW_QML_FILES
    ${CMAKE_SOURCE_DIR}/qml/app/Main.qml
    ${CMAKE_SOURCE_DIR}/qml/app/AppShell.qml
    ${CMAKE_SOURCE_DIR}/qml/app/SettingsPopover.qml
    ${CMAKE_SOURCE_DIR}/qml/app/AutomationSectionStyles.js
    ${CMAKE_SOURCE_DIR}/qml/app/TitleBarLayout.js
    ${CMAKE_SOURCE_DIR}/qml/app/TitleBarDragRegion.qml
    ${CMAKE_SOURCE_DIR}/qml/app/WorkspaceSidebarItems.js
    ${CMAKE_SOURCE_DIR}/qml/app/WorkspaceShellState.js
    ${CMAKE_SOURCE_DIR}/qml/app/WorkspaceShellStyles.js
    ${CMAKE_SOURCE_DIR}/qml/app/TitleBarControls.qml
    ${CMAKE_SOURCE_DIR}/qml/app/ShellNavigation.js
    ${CMAKE_SOURCE_DIR}/qml/app/WorkspaceSelection.js
    ${CMAKE_SOURCE_DIR}/qml/capture/CaptureOverlay.qml
    ${CMAKE_SOURCE_DIR}/qml/capture/CaptureOverlayWindow.qml
    ${CMAKE_SOURCE_DIR}/qml/capture/CaptureToolbar.qml
    ${CMAKE_SOURCE_DIR}/qml/capture/Magnifier.qml
    ${CMAKE_SOURCE_DIR}/qml/pin/PinboardPanel.qml
    ${CMAKE_SOURCE_DIR}/qml/settings/RecentColorPanel.qml
    ${CMAKE_SOURCE_DIR}/qml/settings/SettingsPanel.qml
)

set(KUCLAW_RESOURCE_FILES
    ${CMAKE_SOURCE_DIR}/assets/icons/locus.svg
    ${CMAKE_SOURCE_DIR}/assets/icons/home.svg
    ${CMAKE_SOURCE_DIR}/assets/icons/my-projects.svg
    ${CMAKE_SOURCE_DIR}/assets/icons/team.svg
    ${CMAKE_SOURCE_DIR}/assets/icons/settings.svg
    ${CMAKE_SOURCE_DIR}/assets/icons/sidebar-toggle.svg
    ${CMAKE_SOURCE_DIR}/assets/icons/language.svg
    ${CMAKE_SOURCE_DIR}/assets/icons/rate-limits-remaining.svg
    ${CMAKE_SOURCE_DIR}/assets/icons/log-out.svg
)

set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/app/SettingsPopover.qml
    PROPERTIES QT_RESOURCE_ALIAS app/SettingsPopover.qml
)

set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/assets/icons/language.svg
    PROPERTIES QT_RESOURCE_ALIAS assets/icons/language.svg
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/assets/icons/rate-limits-remaining.svg
    PROPERTIES QT_RESOURCE_ALIAS assets/icons/rate-limits-remaining.svg
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/assets/icons/log-out.svg
    PROPERTIES QT_RESOURCE_ALIAS assets/icons/log-out.svg
)
```

- [ ] **Step 4: Add the minimal component shell**

Create `/Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml`:

```qml
import QtQuick
import QtQuick.Controls

Popup {
    id: root

    property string email: ""
    property string accountLabel: ""

    signal settingsClicked()
    signal languageClicked()
    signal rateLimitsClicked()
    signal logOutClicked()

    modal: false
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        radius: 12
        color: "#FFFFFF"
    }
}
```

- [ ] **Step 5: Run the smoke test to verify it passes**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- PASS for `test_component_loads_and_exposes_copy`

- [ ] **Step 6: Commit**

```bash
git add /Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml \
        /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml \
        /Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt \
        /Users/Y/Documents/kuclaw/assets/icons/language.svg \
        /Users/Y/Documents/kuclaw/assets/icons/rate-limits-remaining.svg \
        /Users/Y/Documents/kuclaw/assets/icons/log-out.svg
git commit -m "feat: register settings popover shell"
```

## Task 2: Build the Approved Static Popover Surface

**Files:**
- Modify: `/Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml`
- Modify: [/Users/Y/Documents/kuclaw/qml/app/WorkspaceShellStyles.js](/Users/Y/Documents/kuclaw/qml/app/WorkspaceShellStyles.js)
- Test: `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`

- [ ] **Step 1: Write the failing structure test**

Extend `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`:

```qml
    function test_figma_labels_and_slots_exist() {
        const subject = createSubject()
        verify(subject !== null)

        compare(subject.emailLabel.text, "sinobec1013@gmail.com")
        compare(subject.accountLabelItem.text, "Personal account")
        compare(subject.settingsRowLabel.text, "Settings")
        compare(subject.languageRowLabel.text, "Language")
        compare(subject.rateLimitsRowLabel.text, "Rate limits remaining")
        compare(subject.logOutRowLabel.text, "Log out")

        compare(subject.languageChevronSlot.width, 18)
        compare(subject.rateLimitsChevronSlot.width, 18)
        compare(subject.languageChevronSlot.x, subject.rateLimitsChevronSlot.x)
    }

    function test_phase_one_rows_are_visual_only() {
        const subject = createSubject()
        let settingsCount = 0
        let languageCount = 0
        subject.settingsClicked.connect(function() { settingsCount += 1 })
        subject.languageClicked.connect(function() { languageCount += 1 })

        subject.open()
        tryCompare(subject, "opened", true)
        mouseClick(subject.settingsRowHitArea, 24, 24, Qt.LeftButton)
        mouseClick(subject.languageRowHitArea, 24, 24, Qt.LeftButton)

        compare(settingsCount, 0)
        compare(languageCount, 0)
        verify(subject.opened)
    }
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- FAIL because the named labels, hit areas, and chevron slots do not exist yet.

- [ ] **Step 3: Add exact popover metrics**

Update [/Users/Y/Documents/kuclaw/qml/app/WorkspaceShellStyles.js](/Users/Y/Documents/kuclaw/qml/app/WorkspaceShellStyles.js):

```js
var SETTINGS_POPOVER_WIDTH = 420
var SETTINGS_POPOVER_RADIUS = 12
var SETTINGS_POPOVER_OUTER_TOP_PADDING = 26
var SETTINGS_POPOVER_ROW_LEFT = 24
var SETTINGS_POPOVER_TEXT_LEFT = 68
var SETTINGS_POPOVER_CHEVRON_SLOT_X = 378
var SETTINGS_POPOVER_CHEVRON_SLOT_WIDTH = 18
var SETTINGS_POPOVER_ACCOUNT_HEIGHT = 78
var SETTINGS_POPOVER_MENU_HEIGHT = 252
var SETTINGS_POPOVER_LOGOUT_HEIGHT = 86
var SETTINGS_POPOVER_STANDARD_ROW_HEIGHT = 70
var SETTINGS_POPOVER_TALL_ROW_HEIGHT = 92

function settingsPopoverMetrics() {
    return {
        width: SETTINGS_POPOVER_WIDTH,
        radius: SETTINGS_POPOVER_RADIUS,
        outerTopPadding: SETTINGS_POPOVER_OUTER_TOP_PADDING,
        rowLeft: SETTINGS_POPOVER_ROW_LEFT,
        textLeft: SETTINGS_POPOVER_TEXT_LEFT,
        chevronSlotX: SETTINGS_POPOVER_CHEVRON_SLOT_X,
        chevronSlotWidth: SETTINGS_POPOVER_CHEVRON_SLOT_WIDTH,
        accountHeight: SETTINGS_POPOVER_ACCOUNT_HEIGHT,
        menuHeight: SETTINGS_POPOVER_MENU_HEIGHT,
        logoutHeight: SETTINGS_POPOVER_LOGOUT_HEIGHT,
        standardRowHeight: SETTINGS_POPOVER_STANDARD_ROW_HEIGHT,
        tallRowHeight: SETTINGS_POPOVER_TALL_ROW_HEIGHT
    }
}
```

- [ ] **Step 4: Build the approved static surface**

Update `/Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml`:

```qml
import QtQuick
import QtQuick.Controls
import "WorkspaceShellStyles.js" as WorkspaceShellStyles

Popup {
    id: root

    readonly property var metrics: WorkspaceShellStyles.settingsPopoverMetrics()

    property string email: ""
    property string accountLabel: ""

    property alias emailLabel: emailLabel
    property alias accountLabelItem: accountLabelItem
    property alias settingsRowLabel: settingsRowLabel
    property alias languageRowLabel: languageRowLabel
    property alias rateLimitsRowLabel: rateLimitsRowLabel
    property alias logOutRowLabel: logOutRowLabel
    property alias settingsRowHitArea: settingsRowHitArea
    property alias languageRowHitArea: languageRowHitArea
    property alias rateLimitsRowHitArea: rateLimitsRowHitArea
    property alias logOutRowHitArea: logOutRowHitArea
    property alias languageChevronSlot: languageChevronSlot
    property alias rateLimitsChevronSlot: rateLimitsChevronSlot

    signal settingsClicked()
    signal languageClicked()
    signal rateLimitsClicked()
    signal logOutClicked()

    modal: false
    focus: true
    padding: 0
    width: metrics.width
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        radius: root.metrics.radius
        color: "#FFFFFF"
        border.width: 1
        border.color: "#EEF1F5"
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowOpacity: 0.14
            shadowBlur: 0.8
            shadowVerticalOffset: 10
        }
    }

    contentItem: Column {
        width: root.width
        spacing: 0

        Item {
            width: parent.width
            height: root.metrics.outerTopPadding + root.metrics.accountHeight

            Column {
                anchors.left: parent.left
                anchors.leftMargin: root.metrics.rowLeft
                anchors.top: parent.top
                anchors.topMargin: root.metrics.outerTopPadding
                spacing: 10

                Text {
                    id: emailLabel
                    text: root.email
                    color: "#5F7395"
                    font.pixelSize: 26
                    font.weight: Font.DemiBold
                }

                Text {
                    id: accountLabelItem
                    text: root.accountLabel
                    color: "#93A1B8"
                    font.pixelSize: 20
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#EEF1F5" }

        Column {
            width: parent.width
            spacing: 2

            SettingsPopoverRow {
                id: settingsRow
                width: parent.width
                rowHeight: root.metrics.standardRowHeight
                iconSource: "qrc:/qt/qml/Kuclaw/assets/icons/settings.svg"
                label: "Settings"
                labelObjectName: "settingsRowLabel"
                hitAreaObjectName: "settingsRowHitArea"
            }

            SettingsPopoverRow {
                id: languageRow
                width: parent.width
                rowHeight: root.metrics.standardRowHeight
                iconSource: "qrc:/qt/qml/Kuclaw/assets/icons/language.svg"
                label: "Language"
                labelObjectName: "languageRowLabel"
                hitAreaObjectName: "languageRowHitArea"
                chevronText: "›"
                chevronSlotObjectName: "languageChevronSlot"
            }

            SettingsPopoverRow {
                id: rateLimitsRow
                width: parent.width
                rowHeight: root.metrics.tallRowHeight
                iconSource: "qrc:/qt/qml/Kuclaw/assets/icons/rate-limits-remaining.svg"
                label: "Rate limits\nremaining"
                labelObjectName: "rateLimitsRowLabel"
                hitAreaObjectName: "rateLimitsRowHitArea"
                chevronText: "›"
                chevronSlotObjectName: "rateLimitsChevronSlot"
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#EEF1F5" }

        SettingsPopoverRow {
            id: logOutRow
            width: parent.width
            rowHeight: 64
            topPadding: 10
            bottomPadding: 12
            iconSource: "qrc:/qt/qml/Kuclaw/assets/icons/log-out.svg"
            label: "Log out"
            labelObjectName: "logOutRowLabel"
            hitAreaObjectName: "logOutRowHitArea"
        }
    }
}
```

- [ ] **Step 5: Add the row helper inside `SettingsPopover.qml`**

Append this helper to `/Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml`:

```qml
component SettingsPopoverRow: Item {
    id: row

    property alias labelItem: labelItem
    property string iconSource: ""
    property string label: ""
    property int rowHeight: 70
    property int topPadding: 0
    property int bottomPadding: 0
    property string chevronText: ""
    property string labelObjectName: ""
    property string hitAreaObjectName: ""
    property string chevronSlotObjectName: ""

    width: root.width
    height: topPadding + rowHeight + bottomPadding

    Rectangle {
        id: hoverFill
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        radius: 10
        color: hitArea.containsMouse ? "#F4F6FA" : "transparent"
    }

    Image {
        x: root.metrics.rowLeft
        y: topPadding + Math.round((rowHeight - 28) / 2)
        width: 28
        height: 28
        source: row.iconSource
        fillMode: Image.PreserveAspectFit
    }

    Text {
        id: labelItem
        objectName: row.labelObjectName
        x: root.metrics.textLeft
        y: topPadding + Math.round((rowHeight - paintedHeight) / 2)
        width: row.chevronText === "" ? 328 : 294
        text: row.label
        color: "#33486B"
        font.pixelSize: 24
        font.weight: Font.Medium
        wrapMode: Text.WordWrap
    }

    Item {
        id: chevronSlot
        objectName: row.chevronSlotObjectName
        visible: row.chevronText !== ""
        x: root.metrics.chevronSlotX
        y: topPadding + Math.round((rowHeight - 24) / 2)
        width: root.metrics.chevronSlotWidth
        height: 24

        Text {
            anchors.centerIn: parent
            text: row.chevronText
            color: "#7B8AA6"
            font.pixelSize: 20
        }
    }

    MouseArea {
        id: hitArea
        objectName: row.hitAreaObjectName
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse.accepted = true
    }
}
```

- [ ] **Step 6: Run the structure tests to verify they pass**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- PASS for label existence, chevron alignment, and phase-one visual-only rows.

- [ ] **Step 7: Commit**

```bash
git add /Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml \
        /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml \
        /Users/Y/Documents/kuclaw/qml/app/WorkspaceShellStyles.js
git commit -m "feat: build static settings popover layout"
```

## Task 3: Wire the Popover into the Expanded Sidebar Settings Trigger

**Files:**
- Modify: [/Users/Y/Documents/kuclaw/qml/app/AppShell.qml](/Users/Y/Documents/kuclaw/qml/app/AppShell.qml)
- Test: `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`

- [ ] **Step 1: Write the failing interaction tests**

Extend `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml` with an `AppShell` harness:

```qml
import QtQuick
import QtTest
import "../../qml/app"

Component {
    id: appShellComponent

    AppShell {
        width: 1440
        height: 900
        shellState.showExpandedSidebar: true
    }
}

function createShell() {
    return createTemporaryObject(appShellComponent, host)
}

function test_clicking_settings_row_toggles_popover() {
    const shell = createShell()
    verify(shell !== null)

    verify(!shell.settingsPopover.opened)
    mouseClick(shell.settingsRow, 40, 24, Qt.LeftButton)
    tryCompare(shell.settingsPopover, "opened", true)
    verify(shell.settingsRow.popoverActive)

    mouseClick(shell.settingsRow, 40, 24, Qt.LeftButton)
    tryCompare(shell.settingsPopover, "opened", false)
    verify(!shell.settingsRow.popoverActive)
}

function test_popover_opens_above_trigger_and_closes_on_escape() {
    const shell = createShell()
    verify(shell !== null)

    mouseClick(shell.settingsRow, 40, 24, Qt.LeftButton)
    tryCompare(shell.settingsPopover, "opened", true)
    verify(shell.settingsPopover.y + shell.settingsPopover.height <= shell.settingsRow.y)

    keyClick(Qt.Key_Escape)
    tryCompare(shell.settingsPopover, "opened", false)
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- FAIL because `AppShell` has no `settingsPopover`, no toggle behavior, and no trigger highlight state.

- [ ] **Step 3: Add `popoverActive` support to the expanded trigger**

Update the `ExpandedSidebarButton` usage in [/Users/Y/Documents/kuclaw/qml/app/AppShell.qml](/Users/Y/Documents/kuclaw/qml/app/AppShell.qml):

```qml
        ExpandedSidebarButton {
            id: settingsRow
            visible: root.shellState.showExpandedSidebar
            anchors.left: parent.left
            anchors.leftMargin: root.expandedSidebarLayout.sideMargin
            anchors.right: parent.right
            anchors.rightMargin: root.expandedSidebarLayout.sideMargin
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.expandedSidebarSettings.bottomMargin
            pageKey: "settings"
            title: "Settings"
            iconSource: "qrc:/qt/qml/Kuclaw/assets/icons/settings.svg"
            selectionEnabled: false
            popoverActive: settingsPopover.opened
            onClicked: root.toggleSettingsPopover()
        }
```

- [ ] **Step 4: Add popover state and placement to `AppShell.qml`**

Add these properties and handlers near the top of [/Users/Y/Documents/kuclaw/qml/app/AppShell.qml](/Users/Y/Documents/kuclaw/qml/app/AppShell.qml):

```qml
    property alias settingsPopover: settingsPopover

    function settingsPopoverX() {
        return sidebarPanel.x
             + settingsRow.x
             + expandedSidebarLayout.sideMargin
    }

    function settingsPopoverY() {
        return settingsRow.y - settingsPopover.implicitHeight - 12
    }

    function toggleSettingsPopover() {
        if (settingsPopover.opened) {
            settingsPopover.close()
        } else {
            settingsPopover.x = settingsPopoverX()
            settingsPopover.y = settingsPopoverY()
            settingsPopover.open()
            settingsPopover.forceActiveFocus()
        }
    }
```

Then instantiate the popup near the end of `AppShell.qml`, above `mainContentPanel`:

```qml
    SettingsPopover {
        id: settingsPopover
        email: "sinobec1013@gmail.com"
        accountLabel: "Personal account"
        parent: root
        z: 30
    }
```

- [ ] **Step 5: Run the interaction tests to verify they pass**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- PASS for open/close toggle, above-trigger placement, and `Esc` dismissal.

- [ ] **Step 6: Commit**

```bash
git add /Users/Y/Documents/kuclaw/qml/app/AppShell.qml \
        /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml
git commit -m "feat: wire settings popover to sidebar trigger"
```

## Task 4: Verify Outside Click Dismissal and Sync Product Docs

**Files:**
- Modify: `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`
- Modify: [/Users/Y/Documents/kuclaw/PRD.md](/Users/Y/Documents/kuclaw/PRD.md)

- [ ] **Step 1: Write the failing dismissal test**

Extend `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`:

```qml
function test_click_outside_closes_popover() {
    const shell = createShell()
    verify(shell !== null)

    mouseClick(shell.settingsRow, 40, 24, Qt.LeftButton)
    tryCompare(shell.settingsPopover, "opened", true)

    mouseClick(shell.mainContentPanel, 40, 40, Qt.LeftButton)
    tryCompare(shell.settingsPopover, "opened", false)
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- FAIL if the popup is not closing from outside click in the shell harness.

- [ ] **Step 3: Add the phase-one PRD note**

Update [/Users/Y/Documents/kuclaw/PRD.md](/Users/Y/Documents/kuclaw/PRD.md):

```md
### Sidebar Settings Popover (Phase 1)

- Clicking the expanded sidebar `Settings` button opens a floating popover above the trigger instead of immediately switching to the full settings page.
- While the popover is open, the `Settings` trigger stays highlighted.
- The popover shows account summary text plus four static rows: `Settings`, `Language`, `Rate limits remaining`, and `Log out`.
- In phase one, these rows are visual-only. They support hover styling, but do not yet navigate, expand, or log out.
- The popover closes on outside click, `Esc`, or clicking the trigger again.
```

- [ ] **Step 4: Run the full phase-one verification**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

Expected:
- all `SettingsPopover` QML tests PASS
- `kuclaw_desktop` builds successfully

- [ ] **Step 5: Commit**

```bash
git add /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml \
        /Users/Y/Documents/kuclaw/PRD.md
git commit -m "feat: finalize phase one settings popover"
```

## Self-Review

### Spec coverage

- Triggered from expanded sidebar `Settings` only: covered in Task 3.
- Popover above trigger with trigger highlight: covered in Task 3.
- Account info plus static menu rows: covered in Task 2.
- `Language` / `Rate limits remaining` chevrons aligned: covered in Task 2.
- Close on outside click / `Esc` / trigger toggle: covered in Tasks 3 and 4.
- Phase-one rows remain visual-only: covered in Task 2.
- Out-of-scope second-phase behaviors remain excluded: preserved across Tasks 2 and 3.

### Placeholder scan

- No `TODO`, `TBD`, or “similar to above” placeholders remain.
- Every task includes concrete file paths, code blocks, and commands.

### Type consistency

- Public popover API uses `settingsClicked`, `languageClicked`, `rateLimitsClicked`, `logOutClicked` consistently.
- Test aliases use the same names referenced in the component snippets.
- The `AppShell` public alias is consistently `settingsPopover`.

Plan complete and saved to `/Users/Y/Documents/kuclaw/docs/superpowers/plans/2026-04-05-settings-popover.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**

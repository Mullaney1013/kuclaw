# Workspace Shell Sidebar States Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the approved `Kuclaw Workspace Concept` shell in QML with three sidebar states (`collapsed`, `hover rail`, `expanded`), working title-bar controls, and hover styling that matches the confirmed Figma frames.

**Architecture:** Keep the workspace shell in [`/Users/Y/Documents/kuclaw/qml/app/AppShell.qml`](/Users/Y/Documents/kuclaw/qml/app/AppShell.qml), but move state transitions and width calculations into a small pure-JS helper so the tricky shell behavior is testable with `qmltestrunner` before wiring it into the full window. Use the approved Figma frames as the source of truth for dimensions and hover treatments, and treat the title bar + sidebar + content shell as one bounded feature rather than mixing in settings-page work.

**Tech Stack:** Qt Quick / QML, Qt Quick Controls, QML JS helper modules, Qt Quick Test (`qmltestrunner`)

---

## File Structure

- Modify: [`/Users/Y/Documents/kuclaw/qml/app/AppShell.qml`](/Users/Y/Documents/kuclaw/qml/app/AppShell.qml)
  - Rebuild the workspace shell around explicit sidebar states and wire title-bar interactions.
- Create: [`/Users/Y/Documents/kuclaw/qml/app/WorkspaceShellState.js`](/Users/Y/Documents/kuclaw/qml/app/WorkspaceShellState.js)
  - Pure state-transition and layout helper for `collapsed`, `rail`, and `expanded`.
- Create: [`/Users/Y/Documents/kuclaw/tests/qml/tst_workspace_shell_state.qml`](/Users/Y/Documents/kuclaw/tests/qml/tst_workspace_shell_state.qml)
  - QML test coverage for transition logic and shell width calculations.
- Modify: [`/Users/Y/Documents/kuclaw/tests/qml/tst_workspace_selection.qml`](/Users/Y/Documents/kuclaw/tests/qml/tst_workspace_selection.qml)
  - Keep existing workspace click tests passing after the shell rewrite; only update if imports or helpers move.

## Figma Source of Truth

- `Kuclaw Workspace Concept - macOS HIG`
- `Kuclaw Workspace Concept - Sidebar Collapsed`
- `Kuclaw Workspace Concept - Sidebar Hover Rail`
- `Sidebar Expanded Row Hover Spec`
- `Sidebar Hover Rail Icon Hover Spec`

## Task 1: Add a Testable Sidebar State Helper

**Files:**
- Create: [`/Users/Y/Documents/kuclaw/qml/app/WorkspaceShellState.js`](/Users/Y/Documents/kuclaw/qml/app/WorkspaceShellState.js)
- Create: [`/Users/Y/Documents/kuclaw/tests/qml/tst_workspace_shell_state.qml`](/Users/Y/Documents/kuclaw/tests/qml/tst_workspace_shell_state.qml)

- [ ] **Step 1: Write the failing test**

```qml
import QtQuick
import QtTest
import "../../qml/app/WorkspaceShellState.js" as WorkspaceShellState

TestCase {
    name: "WorkspaceShellState"

    function test_default_mode_is_collapsed() {
        const state = WorkspaceShellState.createInitialState()
        compare(state.mode, "collapsed")
        compare(state.sidebarWidth, 0)
        compare(state.toolbarLeftWidth, 0)
    }

    function test_hover_enters_rail_when_not_pinned() {
        const state = WorkspaceShellState.createInitialState()
        const nextState = WorkspaceShellState.reduce(state, { type: "LEFT_EDGE_ENTER" })
        compare(nextState.mode, "rail")
        compare(nextState.sidebarWidth, 72)
        compare(nextState.toolbarLeftWidth, 72)
    }

    function test_toggle_opens_and_closes_expanded_sidebar() {
        let state = WorkspaceShellState.createInitialState()
        state = WorkspaceShellState.reduce(state, { type: "TOGGLE_CLICKED" })
        compare(state.mode, "expanded")
        compare(state.sidebarWidth, 264)
        compare(state.toolbarLeftWidth, 264)

        state = WorkspaceShellState.reduce(state, { type: "TOGGLE_CLICKED" })
        compare(state.mode, "collapsed")
        compare(state.sidebarWidth, 0)
        compare(state.toolbarLeftWidth, 0)
    }

    function test_leaving_sidebar_collapses_unpinned_rail() {
        let state = WorkspaceShellState.createInitialState()
        state = WorkspaceShellState.reduce(state, { type: "LEFT_EDGE_ENTER" })
        state = WorkspaceShellState.reduce(state, { type: "SIDEBAR_LEAVE" })
        compare(state.mode, "collapsed")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml -platform offscreen
```

Expected:
- FAIL with `WorkspaceShellState.js unavailable` or missing symbol errors for `createInitialState` / `reduce`

- [ ] **Step 3: Write minimal implementation**

```js
.pragma library

function createInitialState() {
    return {
        pinnedOpen: false,
        hoverRailVisible: false,
        mode: "collapsed",
        sidebarWidth: 0,
        toolbarLeftWidth: 0
    }
}

function project(state) {
    const mode = state.pinnedOpen
        ? "expanded"
        : (state.hoverRailVisible ? "rail" : "collapsed")
    const sidebarWidth = mode === "expanded" ? 264 : (mode === "rail" ? 72 : 0)
    return {
        pinnedOpen: state.pinnedOpen,
        hoverRailVisible: state.hoverRailVisible,
        mode,
        sidebarWidth,
        toolbarLeftWidth: sidebarWidth
    }
}

function reduce(currentState, event) {
    const next = {
        pinnedOpen: currentState.pinnedOpen,
        hoverRailVisible: currentState.hoverRailVisible
    }

    switch (event.type) {
    case "LEFT_EDGE_ENTER":
        if (!next.pinnedOpen)
            next.hoverRailVisible = true
        break
    case "SIDEBAR_LEAVE":
        if (!next.pinnedOpen)
            next.hoverRailVisible = false
        break
    case "TOGGLE_CLICKED":
        next.pinnedOpen = !next.pinnedOpen
        next.hoverRailVisible = false
        break
    }

    return project(next)
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml -platform offscreen
```

Expected:
- PASS for `WorkspaceShellState`
- Existing `WorkspaceSelection` test still passes

- [ ] **Step 5: Commit**

```bash
git add /Users/Y/Documents/kuclaw/qml/app/WorkspaceShellState.js /Users/Y/Documents/kuclaw/tests/qml/tst_workspace_shell_state.qml
git commit -m "test: cover workspace shell sidebar state transitions"
```

## Task 2: Rebuild AppShell Around the Approved Shell States

**Files:**
- Modify: [`/Users/Y/Documents/kuclaw/qml/app/AppShell.qml`](/Users/Y/Documents/kuclaw/qml/app/AppShell.qml)
- Test: [`/Users/Y/Documents/kuclaw/tests/qml/tst_workspace_shell_state.qml`](/Users/Y/Documents/kuclaw/tests/qml/tst_workspace_shell_state.qml)

- [ ] **Step 1: Write the failing test for pinned-open behavior and toolbar width calculations**

Add this test to [`/Users/Y/Documents/kuclaw/tests/qml/tst_workspace_shell_state.qml`](/Users/Y/Documents/kuclaw/tests/qml/tst_workspace_shell_state.qml):

```qml
function test_pinned_sidebar_ignores_leave_events() {
    let state = WorkspaceShellState.createInitialState()
    state = WorkspaceShellState.reduce(state, { type: "TOGGLE_CLICKED" })
    compare(state.mode, "expanded")

    state = WorkspaceShellState.reduce(state, { type: "SIDEBAR_LEAVE" })
    compare(state.mode, "expanded")
    compare(state.sidebarWidth, 264)
    compare(state.toolbarLeftWidth, 264)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml -platform offscreen
```

Expected:
- FAIL because the helper does not yet keep `expanded` stable on `SIDEBAR_LEAVE`

- [ ] **Step 3: Update the helper and wire AppShell to it**

Update [`/Users/Y/Documents/kuclaw/qml/app/WorkspaceShellState.js`](/Users/Y/Documents/kuclaw/qml/app/WorkspaceShellState.js) to keep pinned-open state stable on leave:

```js
case "SIDEBAR_LEAVE":
    if (!next.pinnedOpen)
        next.hoverRailVisible = false
    break
```

Then refactor [`/Users/Y/Documents/kuclaw/qml/app/AppShell.qml`](/Users/Y/Documents/kuclaw/qml/app/AppShell.qml) to consume the helper:

```qml
import "WorkspaceShellState.js" as WorkspaceShellState

property var shellState: WorkspaceShellState.createInitialState()

function dispatchShellEvent(type) {
    shellState = WorkspaceShellState.reduce(shellState, { type: type })
}
```

Replace the always-open sidebar width with state-driven widths:

```qml
Rectangle {
    visible: root.currentPage !== "settings" && root.shellState.sidebarWidth > 0
    Layout.preferredWidth: root.shellState.sidebarWidth
    Layout.fillHeight: true
    color: "#F5F5F5"
}
```

Add the left-edge hot zone and stop using the full-width drag area as the only mouse target:

```qml
MouseArea {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 12
    hoverEnabled: true
    onEntered: root.dispatchShellEvent("LEFT_EDGE_ENTER")
}
```

Make the title-bar sidebar toggle actually interactive:

```qml
MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.dispatchShellEvent("TOGGLE_CLICKED")
}
```

Move main content below the 72 px toolbar:

```qml
Rectangle {
    Layout.fillWidth: true
    Layout.fillHeight: true
    anchors.topMargin: 72
}
```

- [ ] **Step 4: Run tests and build**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml -platform offscreen
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

Expected:
- `WorkspaceShellState` passes, including pinned-open leave behavior
- project build succeeds

- [ ] **Step 5: Commit**

```bash
git add /Users/Y/Documents/kuclaw/qml/app/AppShell.qml /Users/Y/Documents/kuclaw/qml/app/WorkspaceShellState.js /Users/Y/Documents/kuclaw/tests/qml/tst_workspace_shell_state.qml
git commit -m "feat: add workspace shell sidebar state system"
```

## Task 3: Match the Approved Hover States in AppShell

**Files:**
- Modify: [`/Users/Y/Documents/kuclaw/qml/app/AppShell.qml`](/Users/Y/Documents/kuclaw/qml/app/AppShell.qml)
- Test: [`/Users/Y/Documents/kuclaw/tests/qml/tst_workspace_selection.qml`](/Users/Y/Documents/kuclaw/tests/qml/tst_workspace_selection.qml)

- [ ] **Step 1: Write the failing test for preserving active workspace selection**

Extend [`/Users/Y/Documents/kuclaw/tests/qml/tst_workspace_selection.qml`](/Users/Y/Documents/kuclaw/tests/qml/tst_workspace_selection.qml):

```qml
function test_selectWorkspace_preserves_title_detail_and_trailing() {
    const input = [
        { title: "kuclaw", detail: "A", trailing: "1d", active: true },
        { title: "manycoreapis", detail: "", trailing: "", active: false }
    ]

    const output = WorkspaceSelection.activateWorkspace(input, 1)

    compare(output[1].title, "manycoreapis")
    compare(output[1].detail, "")
    compare(output[1].trailing, "")
    compare(output[1].active, true)
}
```

- [ ] **Step 2: Run tests to verify the current baseline**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml -platform offscreen
```

Expected:
- PASS on selection tests
- no hover visual behavior is validated yet; this step just locks the existing selection helper while `AppShell.qml` gets restyled

- [ ] **Step 3: Apply the approved hover styles in AppShell**

Update the expanded sidebar rows to use the confirmed `Sidebar Expanded Row Hover Spec`:

```qml
Rectangle {
    radius: 12
    color: hovered ? Qt.rgba(1, 1, 1, 0.68) : "transparent"
    border.color: hovered ? "#E8E3DA" : "transparent"
    border.width: hovered ? 1 : 0
}
```

Update the hover rail icon rows to use the confirmed `Sidebar Hover Rail Icon Hover Spec`:

```qml
Rectangle {
    width: 48
    height: 40
    radius: 14
    color: hovered ? Qt.rgba(1, 1, 1, 0.82) : "transparent"
    border.color: hovered ? "#E6E2DA" : "transparent"
    border.width: hovered ? 1 : 0
}
```

While doing this, keep these already-correct behaviors intact:

```qml
onClicked: root.selectWorkspace(index)
```

and

```qml
MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton
    onPressed: mouse => root.startSystemMove()
}
```

but only on the background drag area, not on top of interactive title-bar buttons.

- [ ] **Step 4: Run verification**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml -platform offscreen
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

Then perform a fresh manual shell check:
- collapsed by default
- hover rail appears on left-edge hover
- hover rail collapses on leave
- toggle opens full sidebar
- full sidebar stays open until toggled closed
- expanded rows show the approved hover treatment
- hover rail icons show the approved hover treatment

- [ ] **Step 5: Commit**

```bash
git add /Users/Y/Documents/kuclaw/qml/app/AppShell.qml /Users/Y/Documents/kuclaw/tests/qml/tst_workspace_selection.qml
git commit -m "feat: match approved workspace shell hover states"
```

## Self-Review

- Spec coverage: this plan covers the approved workspace shell only — toolbar shell, collapsed state, hover rail, expanded sidebar, and the two newly approved hover specs. It does not pull in settings-page implementation.
- Placeholder scan: no `TODO` or `TBD` placeholders remain; all commands, files, and expected outcomes are explicit.
- Type consistency: all tasks use the same helper names (`WorkspaceShellState.createInitialState`, `WorkspaceShellState.reduce`) and the existing workspace click API (`root.selectWorkspace(index)`).


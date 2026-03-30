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
        compare(nextState.showHoverRail, true)
        compare(nextState.showExpandedSidebar, false)
    }

    function test_toggle_opens_and_closes_expanded_sidebar() {
        let state = WorkspaceShellState.createInitialState()
        state = WorkspaceShellState.reduce(state, { type: "TOGGLE_CLICKED" })
        compare(state.mode, "expanded")
        compare(state.sidebarWidth, 264)
        compare(state.toolbarLeftWidth, 264)
        compare(state.showHoverRail, false)
        compare(state.showExpandedSidebar, true)

        state = WorkspaceShellState.reduce(state, { type: "TOGGLE_CLICKED" })
        compare(state.mode, "collapsed")
        compare(state.sidebarWidth, 0)
        compare(state.toolbarLeftWidth, 0)
        compare(state.showHoverRail, false)
        compare(state.showExpandedSidebar, false)
    }

    function test_leaving_sidebar_collapses_unpinned_rail() {
        let state = WorkspaceShellState.createInitialState()
        state = WorkspaceShellState.reduce(state, { type: "LEFT_EDGE_ENTER" })
        state = WorkspaceShellState.reduce(state, { type: "SIDEBAR_LEAVE" })
        compare(state.mode, "collapsed")
    }

    function test_leaving_hover_rail_area_collapses_unpinned_rail() {
        let state = WorkspaceShellState.createInitialState()
        state = WorkspaceShellState.reduce(state, { type: "LEFT_EDGE_ENTER" })
        state = WorkspaceShellState.reduce(state, { type: "RAIL_AREA_LEAVE" })
        compare(state.mode, "collapsed")
    }

    function test_pinned_sidebar_ignores_leave_events() {
        let state = WorkspaceShellState.createInitialState()
        state = WorkspaceShellState.reduce(state, { type: "TOGGLE_CLICKED" })
        compare(state.mode, "expanded")

        state = WorkspaceShellState.reduce(state, { type: "SIDEBAR_LEAVE" })
        compare(state.mode, "expanded")
        compare(state.sidebarWidth, 264)
        compare(state.toolbarLeftWidth, 264)
    }

    function test_motion_spec_matches_figma_decision() {
        compare(WorkspaceShellState.motionDurationMs(), 220)
        compare(WorkspaceShellState.motionEasingType(), "OutCubic")
    }

    function test_main_content_geometry_uses_stable_sidebar_width_target() {
        const geometry = WorkspaceShellState.mainContentGeometry(1440, 264)
        compare(geometry.x, 264)
        compare(geometry.width, 1176)
    }
}

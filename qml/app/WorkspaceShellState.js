.pragma library

var COLLAPSED_WIDTH = 0
var RAIL_WIDTH = 72
var EXPANDED_WIDTH = 264
var MOTION_DURATION_MS = 220
var MOTION_EASING_TYPE = "OutCubic"

function motionDurationMs() {
    return MOTION_DURATION_MS
}

function motionEasingType() {
    return MOTION_EASING_TYPE
}

function project(state) {
    var mode = "collapsed"
    if (state.pinnedOpen) {
        mode = "expanded"
    } else if (state.hoverRailVisible) {
        mode = "rail"
    }

    var sidebarWidth = mode === "expanded" ? EXPANDED_WIDTH
                    : mode === "rail" ? RAIL_WIDTH
                    : COLLAPSED_WIDTH

    return {
        pinnedOpen: state.pinnedOpen,
        hoverRailVisible: state.hoverRailVisible,
        mode: mode,
        sidebarWidth: sidebarWidth,
        toolbarLeftWidth: sidebarWidth,
        showHoverRail: mode === "rail",
        showExpandedSidebar: mode === "expanded"
    }
}

function createInitialState() {
    return project({
        pinnedOpen: false,
        hoverRailVisible: false
    })
}

function reduce(currentState, event) {
    var next = {
        pinnedOpen: currentState.pinnedOpen,
        hoverRailVisible: currentState.hoverRailVisible
    }

    switch (event.type) {
    case "LEFT_EDGE_ENTER":
        if (!next.pinnedOpen) {
            next.hoverRailVisible = true
        }
        break
    case "SIDEBAR_LEAVE":
        if (!next.pinnedOpen) {
            next.hoverRailVisible = false
        }
        break
    case "TOGGLE_CLICKED":
        next.pinnedOpen = !next.pinnedOpen
        next.hoverRailVisible = false
        break
    default:
        break
    }

    return project(next)
}

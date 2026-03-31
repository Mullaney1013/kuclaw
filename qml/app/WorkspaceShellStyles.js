.pragma library

var EXPANDED_ROW_WIDTH = 224
var EXPANDED_ROW_HEIGHT = 48
var EXPANDED_ROW_RADIUS = 14
var EXPANDED_ROW_CONTENT_HORIZONTAL_PADDING = 16
var EXPANDED_ROW_CONTENT_SPACING = 14
var EXPANDED_ROW_ICON_SIZE = 20
var EXPANDED_ROW_LABEL_SIZE = 15

var EXPANDED_SIDEBAR_TOP_MARGIN = 36
var EXPANDED_SIDEBAR_SIDE_MARGIN = 20
var EXPANDED_SIDEBAR_BOTTOM_MARGIN = 44
var EXPANDED_SIDEBAR_SETTINGS_BOTTOM_MARGIN = 16
var EXPANDED_SIDEBAR_SPACING = 18

var RAIL_ICON_WIDTH = 48
var RAIL_ICON_HEIGHT = 40
var RAIL_ICON_RADIUS = 14

function expandedRowMetrics() {
    return {
        width: EXPANDED_ROW_WIDTH,
        height: EXPANDED_ROW_HEIGHT,
        radius: EXPANDED_ROW_RADIUS
    }
}

function expandedRowContentMetrics() {
    return {
        horizontalPadding: EXPANDED_ROW_CONTENT_HORIZONTAL_PADDING,
        spacing: EXPANDED_ROW_CONTENT_SPACING,
        iconSize: EXPANDED_ROW_ICON_SIZE,
        labelSize: EXPANDED_ROW_LABEL_SIZE
    }
}

function expandedSidebarLayoutMetrics() {
    return {
        topMargin: EXPANDED_SIDEBAR_TOP_MARGIN,
        sideMargin: EXPANDED_SIDEBAR_SIDE_MARGIN,
        bottomMargin: EXPANDED_SIDEBAR_BOTTOM_MARGIN,
        spacing: EXPANDED_SIDEBAR_SPACING
    }
}

function expandedSidebarSettingsMetrics() {
    return {
        bottomMargin: EXPANDED_SIDEBAR_SETTINGS_BOTTOM_MARGIN
    }
}

function expandedRowVisualState(selected, hovered, selectionEnabled) {
    const allowSelection = selectionEnabled !== false
    const effectiveSelected = allowSelection && selected

    return {
        selected: effectiveSelected,
        iconOpacity: effectiveSelected ? 0.94 : (hovered ? 0.78 : 0.64),
        labelColor: effectiveSelected ? "#262626" : "#55616D",
        labelWeight: effectiveSelected ? 500 : 400,
        chrome: expandedRowChrome(effectiveSelected, hovered)
    }
}

function expandedRowChrome(selected, hovered) {
    if (selected) {
        return {
            fill: "#FFFFFF",
            border: "#E5E1D9",
            borderWidth: 1
        }
    }

    if (hovered) {
        return {
            fill: "#B8FFFFFF",
            border: "#E6E1D8",
            borderWidth: 1
        }
    }

    return {
        fill: "transparent",
        border: "transparent",
        borderWidth: 0
    }
}

function railIconMetrics() {
    return {
        width: RAIL_ICON_WIDTH,
        height: RAIL_ICON_HEIGHT,
        radius: RAIL_ICON_RADIUS
    }
}

function railIconChrome(selected, hovered) {
    if (selected) {
        return {
            fill: "#FFFFFF",
            border: "#EAEAEA",
            borderWidth: 1
        }
    }

    if (hovered) {
        return {
            fill: "#D1FFFFFF",
            border: "#E6E2DA",
            borderWidth: 1
        }
    }

    return {
        fill: "transparent",
        border: "transparent",
        borderWidth: 0
    }
}

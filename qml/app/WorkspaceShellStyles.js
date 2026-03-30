.pragma library

var EXPANDED_ROW_WIDTH = 224
var EXPANDED_ROW_HEIGHT = 44
var EXPANDED_ROW_RADIUS = 12

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

function expandedRowChrome(selected, hovered) {
    if (selected) {
        return {
            fill: "#FFFFFF",
            border: "#EAEAEA",
            borderWidth: 1
        }
    }

    if (hovered) {
        return {
            fill: "#ADFFFFFF",
            border: "#E8E3DA",
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

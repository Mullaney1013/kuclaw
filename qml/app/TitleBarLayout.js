.pragma library

function safeNumber(value, fallback) {
    return (typeof value === "number" && isFinite(value)) ? value : fallback
}

function safeToolbarHeight(toolbarHeight) {
    return safeNumber(toolbarHeight, 0)
}

function showCustomTrafficLights(metrics) {
    return !metrics || !metrics.usesNativeTrafficLights
}

function sidebarToggleLeftMargin(metrics) {
    if (!metrics || !metrics.usesNativeTrafficLights) {
        return 94
    }

    return safeNumber(metrics.trafficLightsSafeWidth, 0) + 16
}

function sidebarTopPadding(toolbarHeight, metrics) {
    const safeToolbarHeightValue = safeToolbarHeight(toolbarHeight)

    if (!metrics || !metrics.usesNativeTrafficLights) {
        return safeToolbarHeightValue + 34
    }

    return Math.max(
        safeToolbarHeightValue + 12,
        safeNumber(metrics.titleBarHeight, 0) + 36
    )
}

function contentTopMargin(toolbarHeight, metrics) {
    const safeToolbarHeightValue = safeToolbarHeight(toolbarHeight)

    if (!metrics || !metrics.usesNativeTrafficLights) {
        return safeToolbarHeightValue + 24
    }

    return safeToolbarHeightValue + 18
}

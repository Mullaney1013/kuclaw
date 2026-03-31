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

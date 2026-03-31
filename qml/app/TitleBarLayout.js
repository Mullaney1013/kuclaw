.pragma library

function showCustomTrafficLights(metrics) {
    return !metrics || !metrics.usesNativeTrafficLights;
}

function controlsHostLeftMargin(metrics) {
    return showCustomTrafficLights(metrics) ? 19 : 0;
}

function sidebarToggleLeftMargin(metrics) {
    if (!metrics || !metrics.usesNativeTrafficLights) {
        return 94;
    }

    return metrics.trafficLightsSafeWidth + 12;
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

function useFramelessWindow(platformOs) {
    return platformOs !== "osx" && platformOs !== "macos";
}

.pragma library

function showCustomTrafficLights(metrics) {
    return !metrics || !metrics.usesNativeTrafficLights;
}

function controlsHostLeftMargin(metrics) {
    return showCustomTrafficLights(metrics) ? 19 : 0;
}

function controlsTopMargin(toolbarHeight, controlsHeight, metrics) {
    if (!metrics || !metrics.usesNativeTrafficLights) {
        return Math.round((toolbarHeight - controlsHeight) / 2);
    }

    return Math.max(0, Math.round((metrics.titleBarHeight - controlsHeight) / 2));
}

function toolbarLayerTopMargin(topSafeInset, metrics) {
    if (!metrics || !metrics.usesNativeTrafficLights) {
        return 0;
    }

    return 0;
}

function toolbarLayerHeight(toolbarHeight, topSafeInset, metrics) {
    if (!metrics || !metrics.usesNativeTrafficLights) {
        return toolbarHeight;
    }

    return toolbarHeight + Math.max(0, Math.round(topSafeInset));
}

function sidebarToggleLeftMargin(metrics) {
    if (!metrics || !metrics.usesNativeTrafficLights) {
        return 94;
    }

    const normalizedSafeWidth = Math.min(Math.max(metrics.trafficLightsSafeWidth, 78), 96);
    return normalizedSafeWidth + 12;
}

function sidebarTopPadding(toolbarHeight, topSafeInset, metrics) {
    if (!metrics || !metrics.usesNativeTrafficLights) {
        return toolbarHeight + 34;
    }

    return Math.max(toolbarLayerHeight(toolbarHeight, topSafeInset, metrics) + 28,
                    toolbarHeight + metrics.titleBarHeight + 28);
}

function contentTopMargin(toolbarHeight, metrics) {
    if (!metrics || !metrics.usesNativeTrafficLights) {
        return toolbarHeight + 24;
    }

    return toolbarHeight + 18;
}

function useExpandedClientArea(platformOs) {
    return platformOs === "osx" || platformOs === "macos";
}

function useFramelessWindow(platformOs) {
    return !useExpandedClientArea(platformOs);
}

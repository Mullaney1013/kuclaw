import QtQuick
import QtTest
import "../../qml/app/TitleBarLayout.js" as TitleBarLayout

TestCase {
    name: "TitleBarLayout"

    function test_native_mac_metrics_shift_toggle_and_hide_fake_lights() {
        const metrics = {
            usesNativeTrafficLights: true,
            trafficLightsSafeWidth: 78,
            titleBarHeight: 32
        }

        compare(TitleBarLayout.showCustomTrafficLights(metrics), false)
        compare(TitleBarLayout.sidebarToggleLeftMargin(metrics), 94)
        compare(TitleBarLayout.sidebarTopPadding(56, metrics), 68)
        compare(TitleBarLayout.contentTopMargin(56, metrics), 74)
    }

    function test_non_native_metrics_keep_existing_shell_defaults() {
        const metrics = {
            usesNativeTrafficLights: false,
            trafficLightsSafeWidth: 0,
            titleBarHeight: 0
        }

        compare(TitleBarLayout.showCustomTrafficLights(metrics), true)
        compare(TitleBarLayout.sidebarToggleLeftMargin(metrics), 94)
        compare(TitleBarLayout.sidebarTopPadding(56, metrics), 90)
        compare(TitleBarLayout.contentTopMargin(56, metrics), 80)
    }


    function test_macos_uses_native_window_frame_for_real_traffic_lights() {
        compare(TitleBarLayout.useFramelessWindow("osx"), false)
        compare(TitleBarLayout.useFramelessWindow("macos"), false)
        compare(TitleBarLayout.useFramelessWindow("windows"), true)
    }
}

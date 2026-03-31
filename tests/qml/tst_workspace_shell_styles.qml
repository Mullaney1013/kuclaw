import QtQuick
import QtTest
import "../../qml/app/WorkspaceShellStyles.js" as WorkspaceShellStyles

TestCase {
    name: "WorkspaceShellStyles"

    function test_expanded_row_hover_matches_spec() {
        const metrics = WorkspaceShellStyles.expandedRowMetrics()
        const content = WorkspaceShellStyles.expandedRowContentMetrics()
        const hover = WorkspaceShellStyles.expandedRowChrome(false, true)
        compare(metrics.height, 48)
        compare(metrics.radius, 14)
        compare(content.horizontalPadding, 16)
        compare(content.spacing, 14)
        compare(content.iconSize, 20)
        compare(content.labelSize, 15)
        compare(hover.fill, "#B8FFFFFF")
        compare(hover.border, "#E6E1D8")
        compare(hover.borderWidth, 1)
    }


    function test_expanded_row_selected_chrome_matches_spec() {
        const selected = WorkspaceShellStyles.expandedRowChrome(true, false)
        compare(selected.fill, "#FFFFFF")
        compare(selected.border, "#E5E1D9")
        compare(selected.borderWidth, 1)
    }

    function test_expanded_sidebar_layout_matches_spec() {
        const layout = WorkspaceShellStyles.expandedSidebarLayoutMetrics()
        compare(layout.topMargin, 36)
        compare(layout.sideMargin, 20)
        compare(layout.bottomMargin, 44)
        compare(layout.spacing, 18)
    }

    function test_expanded_sidebar_settings_bottom_clearance_matches_spec() {
        const metrics = WorkspaceShellStyles.expandedSidebarSettingsMetrics()
        compare(metrics.bottomMargin, 16)
    }

    function test_expanded_row_visual_state_can_disable_selection() {
        const visual = WorkspaceShellStyles.expandedRowVisualState(true, false, false)
        compare(visual.selected, false)
        compare(visual.iconOpacity, 0.64)
        compare(visual.labelColor, "#55616D")
        compare(visual.labelWeight, 400)
        compare(visual.chrome.fill, "transparent")
        compare(visual.chrome.border, "transparent")
        compare(visual.chrome.borderWidth, 0)
    }

    function test_expanded_row_visual_state_still_hovers_when_selection_disabled() {
        const visual = WorkspaceShellStyles.expandedRowVisualState(true, true, false)
        compare(visual.selected, false)
        compare(visual.iconOpacity, 0.78)
        compare(visual.labelColor, "#55616D")
        compare(visual.labelWeight, 400)
        compare(visual.chrome.fill, "#B8FFFFFF")
        compare(visual.chrome.border, "#E6E1D8")
        compare(visual.chrome.borderWidth, 1)
    }

    function test_rail_hover_matches_spec() {
        const metrics = WorkspaceShellStyles.railIconMetrics()
        const hover = WorkspaceShellStyles.railIconChrome(false, true)
        compare(metrics.width, 48)
        compare(metrics.height, 40)
        compare(metrics.radius, 14)
        compare(hover.fill, "#D1FFFFFF")
        compare(hover.border, "#E6E2DA")
        compare(hover.borderWidth, 1)
    }

    function test_rail_settings_spacer_accounts_for_all_primary_items() {
        const spacer = WorkspaceShellStyles.railSettingsSpacerHeight(784, 4, 40, 14, 40)
        compare(spacer, 514)
    }
}

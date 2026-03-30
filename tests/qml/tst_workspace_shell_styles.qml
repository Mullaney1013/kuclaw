import QtQuick
import QtTest
import "../../qml/app/WorkspaceShellStyles.js" as WorkspaceShellStyles

TestCase {
    name: "WorkspaceShellStyles"

    function test_expanded_row_hover_matches_spec() {
        const metrics = WorkspaceShellStyles.expandedRowMetrics()
        const hover = WorkspaceShellStyles.expandedRowChrome(false, true)
        compare(metrics.radius, 12)
        compare(hover.fill, "#ADFFFFFF")
        compare(hover.border, "#E8E3DA")
        compare(hover.borderWidth, 1)
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
}

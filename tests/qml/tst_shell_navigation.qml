import QtQuick
import QtTest
import "../../qml/app/ShellNavigation.js" as ShellNavigation

TestCase {
    name: "ShellNavigation"

    function test_toggle_sidebar_flips_boolean_state() {
        compare(ShellNavigation.toggleSidebar(true), false)
        compare(ShellNavigation.toggleSidebar(false), true)
    }

    function test_navigate_records_back_history_and_clears_forward_history() {
        const state = ShellNavigation.navigate("workspace", [], ["settings"], "pins")

        compare(state.currentPage, "pins")
        compare(state.backHistory.length, 1)
        compare(state.backHistory[0], "workspace")
        compare(state.forwardHistory.length, 0)
    }

    function test_navigate_to_same_page_keeps_history_stable() {
        const state = ShellNavigation.navigate("workspace", ["pins"], [], "workspace")

        compare(state.currentPage, "workspace")
        compare(state.backHistory.length, 1)
        compare(state.backHistory[0], "pins")
        compare(state.forwardHistory.length, 0)
    }

    function test_go_back_moves_current_page_to_forward_history() {
        const state = ShellNavigation.goBack("settings", ["workspace", "pins"], [])

        compare(state.currentPage, "pins")
        compare(state.backHistory.length, 1)
        compare(state.backHistory[0], "workspace")
        compare(state.forwardHistory.length, 1)
        compare(state.forwardHistory[0], "settings")
    }

    function test_go_forward_restores_forward_entry() {
        const state = ShellNavigation.goForward("pins", ["workspace"], ["settings"])

        compare(state.currentPage, "settings")
        compare(state.backHistory.length, 2)
        compare(state.backHistory[0], "workspace")
        compare(state.backHistory[1], "pins")
        compare(state.forwardHistory.length, 0)
    }
}

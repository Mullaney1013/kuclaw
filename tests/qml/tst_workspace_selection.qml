import QtQuick
import QtTest
import "../../qml/app/WorkspaceSelection.js" as WorkspaceSelection

TestCase {
    name: "WorkspaceSelection"

    function test_selectWorkspace_activates_only_target_item() {
        const input = [
            { title: "kuclaw", active: true },
            { title: "manycoreapis", active: false },
            { title: "demo", active: false },
            { title: "codex", active: false }
        ]

        const output = WorkspaceSelection.activateWorkspace(input, 2)

        compare(output.length, 4)
        compare(output[0].active, false)
        compare(output[1].active, false)
        compare(output[2].active, true)
        compare(output[3].active, false)
    }
}

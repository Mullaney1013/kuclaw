import QtQuick
import QtTest
import "../../qml/app/AutomationSectionStyles.js" as AutomationSectionStyles

TestCase {
    name: "AutomationSectionStyles"

    function test_primary_section_style() {
        const style = AutomationSectionStyles.styleForTitle("Status reports")
        compare(style.pixelSize, 16)
        compare(style.bold, true)
        compare(style.color, "#2C2D2B")
    }

    function test_secondary_section_style() {
        const style = AutomationSectionStyles.styleForTitle("Release prep")
        compare(style.pixelSize, 14)
        compare(style.bold, false)
        compare(style.color, "#64635E")
    }
}

import QtQuick
import QtTest
import "../../qml/app/WorkspaceSidebarItems.js" as WorkspaceSidebarItems

TestCase {
    name: "WorkspaceSidebarItems"

    function test_sidebar_items_include_locus_first() {
        const items = WorkspaceSidebarItems.items()
        compare(items.length, 4)
        compare(items[0].page, "locus")
        compare(items[0].title, "Locus")
        compare(items[0].icon, "qrc:/qt/qml/Kuclaw/assets/icons/locus.svg")
        compare(items[1].page, "home")
        compare(items[2].page, "projects")
        compare(items[3].page, "team")
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "WorkspaceShellStyles.js" as WorkspaceShellStyles

Item {
    id: root

    // Kept temporarily for source compatibility until all callers finish migrating
    // to the controller-owned popover flow in the next task.
    property string email: ""
    property string accountLabel: ""
    property bool popoverOpen: false
    property bool selected: false
    signal toggleRequested()
    readonly property alias settingsTrigger: settingsTrigger
    readonly property var metrics: WorkspaceShellStyles.expandedRowMetrics()
    readonly property var contentMetrics: WorkspaceShellStyles.expandedRowContentMetrics()
    readonly property var visualState: WorkspaceShellStyles.expandedRowVisualState(
                                           root.selected || root.popoverOpen,
                                           settingsTrigger.containsMouse,
                                           true
                                       )
    readonly property var chrome: root.selected && !root.popoverOpen ? {
            fill: "#E9EEF5",
            border: "#E5E1D9",
            borderWidth: 1
        } : visualState.chrome

    implicitWidth: metrics.width
    implicitHeight: metrics.height
    width: implicitWidth
    height: implicitHeight

    Item {
        id: settingsChrome
        anchors.fill: parent
        z: 0
        Rectangle {
            anchors.fill: parent
            radius: root.metrics.radius
            color: root.chrome.fill
            border.color: root.chrome.border
            border.width: root.chrome.borderWidth
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.contentMetrics.horizontalPadding
            anchors.rightMargin: root.contentMetrics.horizontalPadding
            spacing: root.contentMetrics.spacing

            Image {
                Layout.preferredWidth: root.contentMetrics.iconSize
                Layout.preferredHeight: root.contentMetrics.iconSize
                Layout.alignment: Qt.AlignVCenter
                fillMode: Image.PreserveAspectFit
                source: Qt.resolvedUrl("../../assets/icons/settings.svg")
                opacity: root.visualState.iconOpacity
                sourceSize.width: root.contentMetrics.iconSize
                sourceSize.height: root.contentMetrics.iconSize
            }

            Label {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: "Settings"
                font.pixelSize: root.contentMetrics.labelSize
                font.weight: root.visualState.labelWeight >= 500 ? Font.Medium : Font.Normal
                color: root.visualState.labelColor
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    MouseArea {
        id: settingsTrigger
        objectName: "settingsTrigger"
        anchors.fill: parent
        z: 1
        property bool popoverActive: root.popoverOpen
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.toggleRequested()
        }
    }
}

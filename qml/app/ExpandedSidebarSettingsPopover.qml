import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "WorkspaceShellStyles.js" as WorkspaceShellStyles

Item {
    id: root

    property string email: ""
    property string accountLabel: ""
    property var settingsPopover: null
    property var outsideClickCatcher: null
    readonly property alias settingsTrigger: settingsTrigger
    readonly property bool popoverOpen: settingsPopover ? settingsPopover.opened : false
    readonly property var metrics: WorkspaceShellStyles.expandedRowMetrics()
    readonly property var contentMetrics: WorkspaceShellStyles.expandedRowContentMetrics()
    readonly property var visualState: WorkspaceShellStyles.expandedRowVisualState(
                                           root.popoverOpen,
                                           settingsTrigger.containsMouse,
                                           true
                                       )
    readonly property var chrome: visualState.chrome

    implicitWidth: metrics.width
    implicitHeight: metrics.height
    width: implicitWidth
    height: implicitHeight

    onXChanged: {
        if (root.popoverOpen) {
            root.updatePopoverPosition()
        }
    }
    onYChanged: {
        if (root.popoverOpen) {
            root.updatePopoverPosition()
        }
    }
    onWidthChanged: {
        if (root.popoverOpen) {
            root.updatePopoverPosition()
        }
    }
    onHeightChanged: {
        if (root.popoverOpen) {
            root.updatePopoverPosition()
        }
    }

    function updatePopoverPosition() {
        if (!settingsPopover || !Overlay.overlay) {
            return
        }

        const anchor = root.mapToItem(Overlay.overlay, 0, 0)
        settingsPopover.x = Math.round(anchor.x + 20)
        settingsPopover.y = Math.round(anchor.y - settingsPopover.implicitHeight - 12)
    }

    function destroyOutsideClickCatcher() {
        if (outsideClickCatcher) {
            outsideClickCatcher.destroy()
            outsideClickCatcher = null
        }
    }

    function ensureOutsideClickCatcher() {
        if (outsideClickCatcher) {
            return
        }

        const catcherParent = root.window ? root.window.contentItem
                                          : (Overlay.overlay ? Overlay.overlay : root.parent)
        if (!catcherParent) {
            return
        }

        outsideClickCatcher = outsideClickCatcherComponent.createObject(catcherParent)
    }

    function ensureSettingsPopover() {
        if (settingsPopover) {
            settingsPopover.email = root.email
            settingsPopover.accountLabel = root.accountLabel
            return
        }

        const popupParent = Overlay.overlay ? Overlay.overlay : root
        settingsPopover = settingsPopoverComponent.createObject(popupParent, {
            email: root.email,
            accountLabel: root.accountLabel
        })
    }

    function toggleSettingsPopover() {
        if (settingsPopover && settingsPopover.opened) {
            root.closeSettingsPopover()
            return
        }

        ensureSettingsPopover()
        openTimer.restart()
    }

    function closeSettingsPopover() {
        destroyOutsideClickCatcher()
        openTimer.stop()
        if (settingsPopover && settingsPopover.opened) {
            settingsPopover.close()
        }
    }

    Timer {
        id: openTimer
        interval: 0
        repeat: false
        running: false
        onTriggered: {
            root.updatePopoverPosition()
            settingsPopover.open()
            settingsPopover.forceActiveFocus()
            root.ensureOutsideClickCatcher()
        }
    }

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
            root.toggleSettingsPopover()
        }
    }

    Component {
        id: settingsPopoverComponent

        SettingsPopover {
            z: 30

            onOpenedChanged: {
                if (opened) {
                    root.updatePopoverPosition()
                } else {
                    root.destroyOutsideClickCatcher()
                }
            }
        }
    }

    Component {
        id: outsideClickCatcherComponent

        MouseArea {
            anchors.fill: parent
            z: 20
            acceptedButtons: Qt.LeftButton
            onClicked: root.closeSettingsPopover()
        }
    }
}

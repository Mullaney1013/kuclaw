import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Kuclaw
import "ShellNavigation.js" as ShellNavigation
import "WorkspaceShellState.js" as WorkspaceShellState

ApplicationWindow {
    id: root
    objectName: "KuclawMainWindow"

    property string currentPage: "none"
    property var shellState: WorkspaceShellState.createInitialState()
    property var backHistory: []
    property var forwardHistory: []

    readonly property real toolbarHeight: 56
    readonly property var sidebarItems: [
        {
            page: "home",
            title: "Home",
            icon: "qrc:/qt/qml/Kuclaw/assets/icons/home.svg"
        },
        {
            page: "projects",
            title: "My Projects",
            icon: "qrc:/qt/qml/Kuclaw/assets/icons/my-projects.svg"
        },
        {
            page: "team",
            title: "Team",
            icon: "qrc:/qt/qml/Kuclaw/assets/icons/team.svg"
        }
    ]

    width: 1440
    height: 900
    visible: true
    title: "Kuclaw"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "#F5F5F5"

    function toggleMaximized() {
        if (root.visibility === Window.Maximized) {
            root.showNormal()
        } else {
            root.showMaximized()
        }
    }

    function restoreMainWindow() {
        if (appCoordinator.captureInProgress) {
            return
        }

        if (!root.visible || root.visibility === Window.Minimized) {
            root.showNormal()
        }
        root.raise()
        root.requestActivate()
    }

    function navigateToPage(page) {
        const state = ShellNavigation.navigate(root.currentPage, root.backHistory, root.forwardHistory, page)
        root.currentPage = state.currentPage
        root.backHistory = state.backHistory
        root.forwardHistory = state.forwardHistory
    }

    function goBack() {
        const state = ShellNavigation.goBack(root.currentPage, root.backHistory, root.forwardHistory)
        root.currentPage = state.currentPage
        root.backHistory = state.backHistory
        root.forwardHistory = state.forwardHistory
    }

    function goForward() {
        const state = ShellNavigation.goForward(root.currentPage, root.backHistory, root.forwardHistory)
        root.currentPage = state.currentPage
        root.backHistory = state.backHistory
        root.forwardHistory = state.forwardHistory
    }

    function dispatchShellEvent(type) {
        root.shellState = WorkspaceShellState.reduce(root.shellState, { type: type })
    }

    function selectSidebarPage(page) {
        root.navigateToPage(page)
        if (root.shellState.mode === "rail") {
            root.dispatchShellEvent("SIDEBAR_LEAVE")
        }
    }

    function isSidebarItemSelected(page) {
        return root.currentPage === page
    }

    function closeSettingsPage() {
        if (root.backHistory.length > 0) {
            root.goBack()
            return
        }

        root.currentPage = "none"
        root.forwardHistory = []
    }

    function pageDisplayTitle(page) {
        switch (page) {
        case "home":
            return "Home"
        case "projects":
            return "My Projects"
        case "team":
            return "Team"
        default:
            return "Select an item from the sidebar"
        }
    }

    component ExpandedSidebarButton: Item {
        id: expandedButton

        required property string pageKey
        required property string title
        required property string iconSource

        readonly property bool selected: root.isSidebarItemSelected(pageKey)
        property bool hovered: buttonMouse.containsMouse

        implicitWidth: 224
        implicitHeight: 44

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: expandedButton.selected ? "#FFFFFF" : (expandedButton.hovered ? "#FAFAFA" : "transparent")
            border.color: (expandedButton.selected || expandedButton.hovered) ? "#EAEAEA" : "transparent"
            border.width: 1
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.selectSidebarPage(expandedButton.pageKey)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 12

            Image {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                fillMode: Image.PreserveAspectFit
                source: expandedButton.iconSource
                opacity: expandedButton.selected ? 0.9 : (expandedButton.hovered ? 0.72 : 0.58)
                sourceSize.width: 18
                sourceSize.height: 18
            }

            Label {
                Layout.fillWidth: true
                text: expandedButton.title
                font.pixelSize: 16
                font.weight: expandedButton.selected ? Font.Medium : Font.Normal
                color: expandedButton.selected ? "#262626" : "#5C615E"
            }
        }
    }

    component RailSidebarButton: Item {
        id: railButton

        required property string pageKey
        required property string iconSource

        readonly property bool selected: root.isSidebarItemSelected(pageKey)
        property bool hovered: iconMouse.containsMouse

        implicitWidth: 44
        implicitHeight: 44

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: railButton.selected ? "#FFFFFF" : (railButton.hovered ? "#FAFAFA" : "transparent")
            border.color: (railButton.selected || railButton.hovered) ? "#EAEAEA" : "transparent"
            border.width: 1
        }

        MouseArea {
            id: iconMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.selectSidebarPage(railButton.pageKey)
        }

        Image {
            anchors.centerIn: parent
            width: 18
            height: 18
            fillMode: Image.PreserveAspectFit
            source: railButton.iconSource
            opacity: railButton.selected ? 0.9 : (railButton.hovered ? 0.72 : 0.58)
            sourceSize.width: 18
            sourceSize.height: 18
        }
    }

    Connections {
        target: appCoordinator

        function onReopenRequested() {
            root.restoreMainWindow()
        }
    }

    Rectangle {
        id: sidebarPanel
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.shellState.sidebarWidth
        color: "#F5F5F5"
        clip: true
        z: 1

        Behavior on width {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onExited: root.dispatchShellEvent("SIDEBAR_LEAVE")
        }

        Column {
            visible: root.shellState.showExpandedSidebar
            anchors.top: parent.top
            anchors.topMargin: root.toolbarHeight + 34
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 26
            spacing: 12

            Repeater {
                model: root.sidebarItems

                delegate: ExpandedSidebarButton {
                    required property var modelData
                    pageKey: modelData.page
                    title: modelData.title
                    iconSource: modelData.icon
                }
            }

            Item {
                width: 1
                height: Math.max(0, parent.height - settingsRow.height - 168)
            }

            ExpandedSidebarButton {
                id: settingsRow
                pageKey: "settings"
                title: "Settings"
                iconSource: "qrc:/qt/qml/Kuclaw/assets/icons/settings.svg"
            }
        }

        Column {
            visible: root.shellState.showHoverRail
            anchors.top: parent.top
            anchors.topMargin: root.toolbarHeight + 34
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 26
            spacing: 14

            Repeater {
                model: root.sidebarItems

                delegate: RailSidebarButton {
                    required property var modelData
                    pageKey: modelData.page
                    iconSource: modelData.icon
                }
            }

            Item {
                width: 1
                height: Math.max(0, parent.height - settingsIcon.height - 174)
            }

            RailSidebarButton {
                id: settingsIcon
                pageKey: "settings"
                iconSource: "qrc:/qt/qml/Kuclaw/assets/icons/settings.svg"
            }
        }
    }

    Rectangle {
        id: mainContentPanel
        x: root.shellState.sidebarWidth
        y: 0
        width: root.width - x
        height: root.height
        radius: 26
        color: "#FFFFFF"
        z: 0

        Behavior on x {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Item {
            anchors.fill: parent
            anchors.topMargin: root.toolbarHeight + 24
            anchors.leftMargin: 32
            anchors.rightMargin: 32
            anchors.bottomMargin: 32

            Loader {
                anchors.fill: parent
                sourceComponent: root.currentPage === "settings" ? settingsPageComponent : placeholderPageComponent
            }
        }
    }

    Component {
        id: placeholderPageComponent

        Item {
            Label {
                anchors.centerIn: parent
                text: root.pageDisplayTitle(root.currentPage)
                font.pixelSize: root.currentPage === "none" ? 22 : 28
                font.weight: root.currentPage === "none" ? Font.Normal : Font.Medium
                color: root.currentPage === "none" ? "#9E9E9E" : "#6F6F6F"
            }
        }
    }

    Component {
        id: settingsPageComponent

        SettingsPanel {
            anchors.fill: parent
            radius: 0
            border.width: 0
            onBackRequested: root.closeSettingsPage()
        }
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.toolbarHeight
        z: 10

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.shellState.toolbarLeftWidth
            color: "#F5F5F5"

            Behavior on width {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: root.shellState.toolbarLeftWidth
            anchors.right: parent.right
            color: "#FFFFFF"

            Behavior on anchors.leftMargin {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.left: titleBarControls.right
            anchors.leftMargin: 16
            acceptedButtons: Qt.LeftButton
            onPressed: mouse => root.startSystemMove()
        }

        TitleBarControls {
            id: titleBarControls
            anchors.left: parent.left
            anchors.leftMargin: 19
            anchors.verticalCenter: parent.verticalCenter
            backEnabled: root.backHistory.length > 0
            forwardEnabled: root.forwardHistory.length > 0
            onCloseRequested: root.close()
            onMinimizeRequested: root.showMinimized()
            onMaximizeRequested: root.toggleMaximized()
            onSidebarToggleRequested: root.dispatchShellEvent("TOGGLE_CLICKED")
            onBackRequested: root.goBack()
            onForwardRequested: root.goForward()
        }
    }

    MouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 10
        z: 12
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: {
            if (root.shellState.mode === "collapsed") {
                root.dispatchShellEvent("LEFT_EDGE_ENTER")
            }
        }
    }
}

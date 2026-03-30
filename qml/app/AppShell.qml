import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Kuclaw
import "AutomationSectionStyles.js" as AutomationSectionStyles
import "ShellNavigation.js" as ShellNavigation
import "WorkspaceSelection.js" as WorkspaceSelection

ApplicationWindow {
    id: root
    objectName: "KuclawMainWindow"

    property string currentPage: "workspace"
    property bool sidebarExpanded: true
    property var backHistory: []
    property var forwardHistory: []

    width: 1440
    height: 900
    visible: true
    title: "Kuclaw"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "#D8D8D9"

    function toggleMaximized() {
        if (root.visibility === Window.Maximized) {
            root.showNormal()
        } else {
            root.showMaximized()
        }
    }

    function mainWindowCenterX() {
        return root.x + root.width / 2
    }

    function mainWindowCenterY() {
        return root.y + root.height / 2
    }

    function startCaptureWorkflow() {
        settingsMenu.close()
        appCoordinator.beginCapture()
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

    function openSettingsPage() {
        settingsMenu.close()
        root.navigateToPage("settings")
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

    function toggleSidebar() {
        root.sidebarExpanded = ShellNavigation.toggleSidebar(root.sidebarExpanded)
    }

    function selectWorkspace(index) {
        settingsMenu.close()
        root.workspaceItems = WorkspaceSelection.activateWorkspace(root.workspaceItems, index)
        root.navigateToPage("workspace")
    }

    property var workspaceItems: [
        {
            title: "kuclaw",
            detail: "制定 Kuclaw 客户端现代化架构...",
            trailing: "1d",
            active: true
        },
        {
            title: "manycoreapis",
            active: false
        },
        {
            title: "demo",
            active: false
        },
        {
            title: "codex",
            active: false
        }
    ]

    Connections {
        target: appCoordinator

        function onReopenRequested() {
            root.restoreMainWindow()
        }
    }

    Popup {
        id: settingsMenu
        parent: root.contentItem
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 0
        width: 292
        height: 259
        x: settingsAnchor.mapToItem(root.contentItem, 0, 0).x
        y: settingsAnchor.mapToItem(root.contentItem, 0, 0).y - height - 12

        background: Rectangle {
            radius: 18
            color: "#FFFFFF"
            border.color: "#E5DED2"
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Label {
                    text: "sino@kuxiaobang.com"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: "#4F524D"
                }

                Label {
                    text: "Personal account"
                    font.pixelSize: 13
                    color: "#9A9892"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#EEE7DC"
            }

            Repeater {
                model: [
                    { key: "settings", title: "Settings", trailing: "" },
                    { key: "language", title: "Language", trailing: "\u203A" },
                    { key: "limits", title: "Rate limits remaining", trailing: "\u203A" },
                    { key: "logout", title: "Log out", trailing: "" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    property bool hovered: rowMouse.containsMouse

                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 12
                    color: hovered ? "#F7F4EE" : "#FFFFFF"
                    border.color: "#EFE8DC"
                    border.width: 1

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (parent.modelData.key === "settings") {
                                root.openSettingsPage()
                            } else {
                                settingsMenu.close()
                            }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Label {
                            Layout.fillWidth: true
                            text: modelData.title
                            color: "#292A28"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }

                        Label {
                            visible: modelData.trailing.length > 0
                            text: modelData.trailing
                            color: "#9B9993"
                            font.pixelSize: 14
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            visible: root.currentPage !== "settings" && root.sidebarExpanded
            Layout.preferredWidth: 334
            Layout.fillHeight: true
            radius: 0
            color: "#D8D8D9"

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 72
                anchors.bottomMargin: 16
                spacing: 16

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 188

                    Column {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        spacing: 22

                        Label {
                            text: "New capture"
                            font.pixelSize: 18
                            font.weight: Font.Medium
                            color: "#242424"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.navigateToPage("workspace")
                            }
                        }

                        Label {
                            text: "Pinboard"
                            font.pixelSize: 18
                            color: "#3A3A39"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.navigateToPage("pins")
                            }
                        }

                        Label {
                            text: "Automations"
                            font.pixelSize: 18
                            color: "#3A3A39"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.navigateToPage("automations")
                            }
                        }
                    }

                    Label {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        text: "Workspaces"
                        color: "#9A9892"
                        font.pixelSize: 14
                    }
                }

                Repeater {
                    model: root.workspaceItems

                    delegate: Item {
                        required property var modelData
                        required property int index
                        property bool active: modelData.active
                        property bool hovered: workspaceMouse.containsMouse

                        Layout.preferredWidth: 216
                        Layout.alignment: Qt.AlignLeft
                        implicitHeight: active ? 52 : 32

                        MouseArea {
                            id: workspaceMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectWorkspace(index)
                        }

                        Column {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 0
                            anchors.topMargin: 6
                            spacing: active ? 4 : 0

                            Row {
                                spacing: 8

                                Label {
                                    text: active ? "\u2304" : "\u203A"
                                    font.pixelSize: 11
                                    color: "#8E948D"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 10
                                    height: 8
                                    radius: 2
                                    color: active ? "#2B6CFF" : "transparent"
                                    border.color: "#D9D2C5"
                                    border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Label {
                                    text: modelData.title
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: active ? "#2E3336" : "#5B6063"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Label {
                                    visible: active && modelData.trailing.length > 0
                                    text: modelData.trailing
                                    font.pixelSize: 10
                                    color: "#5B6063"
                                    leftPadding: 96
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Label {
                                visible: active && modelData.detail.length > 0
                                text: modelData.detail
                                font.pixelSize: 12
                                color: "#2E3336"
                                leftPadding: 24
                            }
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                Rectangle {
                    id: settingsAnchor
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 0
                    color: "transparent"
                    border.color: "transparent"
                    border.width: 0

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (settingsMenu.opened) {
                                settingsMenu.close()
                            } else {
                                settingsMenu.open()
                            }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 12
                        spacing: 10

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            color: "transparent"
                            border.color: "#4F524D"
                            border.width: 1
                        }

                        Label {
                            text: "Settings"
                            font.pixelSize: 16
                            font.weight: Font.Medium
                            color: "#4F524D"
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 15
            color: "#FFFFFF"
            border.color: "#D8D8D9"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 36
                anchors.rightMargin: 36
                anchors.topMargin: 36
                anchors.bottomMargin: 36
                spacing: 22

                Label {
                    text: root.currentPage === "pins"
                          ? "Pinboard"
                          : root.currentPage === "automations"
                            ? "Automations"
                            : ""
                    visible: root.currentPage === "pins" || root.currentPage === "automations"
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: "#262626"
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.currentPage === "workspace"
                                  ? 0
                                  : root.currentPage === "pins"
                                    ? 1
                                    : root.currentPage === "automations"
                                      ? 2
                                      : 3

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 20
                            width: 760
                            spacing: 20

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 64
                                height: 48
                                radius: 24
                                color: "#FFFFFF"
                                border.color: "#EEF0F4"
                                border.width: 1

                                Label {
                                    anchors.centerIn: parent
                                    text: "\u2601"
                                    font.pixelSize: 24
                                    color: "#1B69F0"
                                }
                            }

                            Label {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: "Let's capture"
                                font.pixelSize: 40
                                font.weight: Font.Bold
                                color: "#171717"
                            }

                            Label {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: "One focused desktop surface for screenshot, pinboard, colors and future"
                                font.pixelSize: 14
                                color: "#8C8A84"
                            }

                            Label {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: "automation."
                                font.pixelSize: 14
                                color: "#8C8A84"
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 14

                                Repeater {
                                    model: [
                                        { title: "Start a frozen capture flow", action: "capture" },
                                        { title: "Create a pin from clipboard", action: "pin" },
                                        { title: "Open capture settings", action: "settings" }
                                    ]

                                    delegate: Rectangle {
                                        required property var modelData

                                        width: 240
                                        height: 96
                                        radius: 18
                                        color: "#FFFFFF"
                                        border.color: "#E9E3D9"
                                        border.width: 1

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (parent.modelData.action === "capture") {
                                                    root.startCaptureWorkflow()
                                                } else if (parent.modelData.action === "pin") {
                                                    pinboardViewModel.pinFromClipboard()
                                                } else {
                                                    root.openSettingsPage()
                                                }
                                            }
                                        }

                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: 16
                                            spacing: 10

                                            Rectangle {
                                                width: 22
                                                height: 22
                                                radius: 11
                                                color: "#FFF8E8"
                                                border.color: "#F5E2AA"
                                                border.width: 1
                                            }

                                            Label {
                                                width: parent.width
                                                wrapMode: Text.WordWrap
                                                text: modelData.title
                                                font.pixelSize: 16
                                                font.weight: Font.Medium
                                                color: "#171717"
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 760
                                height: 116
                                radius: 24
                                color: "#FFFFFF"
                                border.color: "#E7E2D9"
                                border.width: 1

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 18
                                    spacing: 16

                                    Label {
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                        text: "Ask Kuclaw to capture, pin, sample colors, or prepare the next desktop action..."
                                        font.pixelSize: 15
                                        color: "#B5B3AE"
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: "#EEE8DE"
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: 22

                                        Label {
                                            text: "+"
                                            font.pixelSize: 20
                                            color: "#6D6B66"
                                        }

                                        Label {
                                            text: "GPT-5.4"
                                            font.pixelSize: 14
                                            color: "#878787"
                                        }

                                        Label {
                                            text: "Extra High"
                                            font.pixelSize: 14
                                            color: "#878787"
                                        }

                                        Item {
                                            width: 1
                                            height: 1
                                        }

                                        Label {
                                            text: "\u2726"
                                            font.pixelSize: 14
                                            color: "#1B69F0"
                                        }

                                        Item {
                                            width: 1
                                            height: 1
                                        }

                                        Label {
                                            text: "\u266A"
                                            font.pixelSize: 14
                                            color: "#878787"
                                        }

                                        Rectangle {
                                            width: 22
                                            height: 22
                                            radius: 11
                                            color: "#D7D6D6"

                                            Label {
                                                anchors.centerIn: parent
                                                text: "\u2191"
                                                font.pixelSize: 12
                                                color: "#FFFFFF"
                                            }
                                        }
                                    }
                                }
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 40

                                Label {
                                    text: "Local \u2304"
                                    font.pixelSize: 13
                                    color: "#7F7D77"
                                }

                                Label {
                                    text: "Default permissions \u2304"
                                    font.pixelSize: 13
                                    color: "#7F7D77"
                                }
                            }
                        }
                    }

                    ScrollView {
                        clip: true

                        ColumnLayout {
                            width: Math.max(parent.width - 40, 780)
                            spacing: 18

                            Label {
                                text: "Pinboard"
                                font.pixelSize: 48
                                font.weight: Font.Bold
                                color: "#171717"
                            }

                            Label {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                text: "Manage clipboard pins, restore recently closed content, and keep references available while capturing."
                                font.pixelSize: 16
                                color: "#7D7B77"
                            }

                            PinboardPanel {
                                Layout.fillWidth: true
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Row {
                            anchors.fill: parent
                            spacing: 28

                            Column {
                                width: 170
                                spacing: 14

                                Repeater {
                                    model: ["Status reports", "Release prep", "Incidents & triage", "Code quality", "Repo maintenance", "Growth & exploration"]

                                    delegate: Label {
                                        required property string modelData
                                        readonly property var sectionStyle: AutomationSectionStyles.styleForTitle(modelData)
                                        text: modelData
                                        font.pixelSize: sectionStyle.pixelSize
                                        font.weight: sectionStyle.bold ? Font.Bold : Font.Medium
                                        color: sectionStyle.color
                                    }
                                }
                            }

                            Column {
                                spacing: 18

                                Label {
                                    text: "Status reports"
                                    font.pixelSize: 28
                                    font.weight: Font.Bold
                                    color: "#171717"
                                }

                                Label {
                                    width: 760
                                    wrapMode: Text.WordWrap
                                    text: "Automate recurring desktop routines, scheduled capture flows, and future AI-assisted workflows."
                                    font.pixelSize: 15
                                    color: "#7D7B77"
                                }

                                Grid {
                                    columns: 2
                                    spacing: 18

                                    Repeater {
                                        model: [
                                            "Summarize yesterday's capture activity for standup.",
                                            "Synthesize this week's pins, colors, and saved captures into an update.",
                                            "Summarize last week's PRs by teammate and theme; highlight risks.",
                                            "Draft this week's release notes from merged changes."
                                        ]

                                        delegate: Rectangle {
                                            required property string modelData
                                            width: 308
                                            height: 108
                                            radius: 20
                                            color: "#FFFFFF"
                                            border.color: "#ECE5DA"
                                            border.width: 1

                                            Label {
                                                anchors.fill: parent
                                                anchors.margins: 18
                                                wrapMode: Text.WordWrap
                                                text: modelData
                                                font.pixelSize: 16
                                                color: "#2C2D2B"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    SettingsPanel {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        onBackRequested: root.navigateToPage("workspace")
                    }
                }
            }
        }
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 56
        z: 10

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
            onSidebarToggleRequested: root.toggleSidebar()
            onBackRequested: root.goBack()
            onForwardRequested: root.goForward()
        }
    }
}

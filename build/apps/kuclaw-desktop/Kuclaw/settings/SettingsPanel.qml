import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kuclaw

Rectangle {
    id: root

    signal backRequested()

    property int currentSection: 0
    property var navigationItems: [
        { type: "item", title: "Capture Settings", section: 0 },
        { type: "item", title: "Appearance", section: 1 },
        { type: "item", title: "Pinboard", section: 2 },
        { type: "label", title: "Today capture sprint" },
        { type: "item", title: "Color & picker", section: 3 },
        { type: "item", title: "Hotkeys", section: 4 },
        { type: "item", title: "Storage", section: 5 },
        { type: "item", title: "Integrations", section: 6 }
    ]

    radius: 24
    color: "#FFFFFF"
    border.color: "#E9E3D9"
    border.width: 1

    function sectionNavTitle() {
        switch (currentSection) {
        case 1:
            return "Appearance"
        case 2:
            return "Pinboard"
        case 3:
            return "Color & picker"
        case 4:
            return "Hotkeys"
        case 5:
            return "Storage"
        case 6:
            return "Integrations"
        default:
            return "Capture Settings"
        }
    }

    function sectionHeading() {
        switch (currentSection) {
        case 1:
            return "Appearance"
        case 2:
            return "Pinboard"
        case 3:
            return "Color & picker"
        case 4:
            return "Hotkeys"
        case 5:
            return "Storage"
        case 6:
            return "Integrations"
        default:
            return "Capture"
        }
    }

    function sectionDescription() {
        switch (currentSection) {
        case 1:
            return "Theme and visual preferences will live here."
        case 2:
            return "Pinboard behavior and window rules will be grouped here."
        case 3:
            return "Color value display, picker defaults, and history presentation live here."
        case 4:
            return "Global shortcut editing and validation will be grouped here."
        case 5:
            return "Saving destinations, naming rules, and export defaults live here."
        case 6:
            return "External services and local integrations can be surfaced here later."
        default:
            return "Screenshot behavior, overlay helpers, default naming, and how Kuclaw enters and exits frozen capture."
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            color: "#F5F3EE"
            radius: 24

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Label {
                    text: "\u2190  Back to app"
                    font.pixelSize: 16
                    color: "#77746D"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.backRequested()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 20
                    color: "#F7F4EE"
                    border.color: "#ECE5DA"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        Repeater {
                            model: root.navigationItems

                            delegate: Rectangle {
                                required property var modelData
                                property bool active: modelData.type === "item" && root.currentSection === modelData.section
                                property bool hovered: sectionMouse.containsMouse

                                Layout.fillWidth: true
                                implicitHeight: modelData.type === "label" ? 22 : 44
                                radius: 14
                                color: modelData.type === "label"
                                       ? "transparent"
                                       : active
                                         ? "#F1F2F4"
                                         : hovered
                                           ? "#FBF9F4"
                                           : "#FFFFFF"
                                border.color: modelData.type === "item" && active ? "#E2E3E6" : "transparent"
                                border.width: 1

                                MouseArea {
                                    id: sectionMouse
                                    enabled: parent.modelData.type === "item"
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.currentSection = parent.modelData.section
                                }

                                RowLayout {
                                    visible: modelData.type === "item"
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 10

                                    Rectangle {
                                        width: 4
                                        height: 24
                                        radius: 2
                                        color: active ? "#171717" : "transparent"
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.title
                                        font.pixelSize: 15
                                        font.weight: active ? Font.Bold : Font.Medium
                                        color: "#2C2D2B"
                                    }
                                }

                                Label {
                                    visible: modelData.type === "label"
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    text: modelData.title
                                    font.pixelSize: 14
                                    color: "#8B8881"
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: "#E8E2D8"
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                x: 36
                y: 28
                width: Math.max(720, root.width - 374)
                spacing: 18

                Label {
                    text: "Settings"
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: "#171717"
                }

                Rectangle {
                    width: 134
                    height: 28
                    radius: 14
                    color: "#EEF4FF"
                    border.color: "#D9E4FF"
                    border.width: 1

                    Label {
                        anchors.centerIn: parent
                        text: root.sectionNavTitle()
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: "#2B6CFF"
                    }
                }

                Label {
                    text: root.sectionHeading()
                    font.pixelSize: 32
                    font.weight: Font.Bold
                    color: "#171717"
                }

                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: root.sectionDescription()
                    font.pixelSize: 15
                    color: "#7D7B77"
                }

                Item {
                    visible: root.currentSection !== 0
                    Layout.fillWidth: true
                    implicitHeight: 220

                    Rectangle {
                        anchors.fill: parent
                        radius: 22
                        color: "#FFFFFF"
                        border.color: "#E9E3D9"
                        border.width: 1
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 28
                        spacing: 14

                        Label {
                            text: root.sectionHeading()
                            font.pixelSize: 24
                            font.weight: Font.Bold
                            color: "#171717"
                        }

                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: "This section is designed and placed, but the detailed controls will be connected after the capture page is finalized."
                            font.pixelSize: 14
                            color: "#7D7B77"
                        }
                    }
                }

                Column {
                    visible: root.currentSection === 0
                    width: parent.width
                    spacing: 0

                    Rectangle {
                        width: parent.width
                        height: 82
                        radius: 22
                        color: "#FFFFFF"
                        border.color: "#E9E3D9"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 18

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Label {
                                    text: "Keep current window in capture"
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                    color: "#262626"
                                }

                                Label {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    text: "Freeze the visible window into the screenshot, then let the live main window leave focus competition."
                                    font.pixelSize: 13
                                    color: "#7B7973"
                                }
                            }

                            Switch {
                                checked: settingsViewModel.keepCurrentWindowOnCapture
                                onToggled: settingsViewModel.setKeepCurrentWindowOnCapture(checked)
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 82
                        color: "#FFFFFF"
                        border.color: "#ECE5DA"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 18

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Label {
                                    text: "Magnifier"
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                    color: "#262626"
                                }

                                Label {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    text: "Show a real pixel magnifier while hovering, dragging, or resizing selections."
                                    font.pixelSize: 13
                                    color: "#7B7973"
                                }
                            }

                            Switch {
                                checked: settingsViewModel.magnifierEnabled
                                onToggled: settingsViewModel.setMagnifierEnabled(checked)
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 82
                        color: "#FFFFFF"
                        border.color: "#ECE5DA"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 18

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Label {
                                    text: "Default color value format"
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                    color: "#262626"
                                }

                                Label {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    text: "Choose how the color panel displays copied values before Shift toggles formats."
                                    font.pixelSize: 13
                                    color: "#7B7973"
                                }
                            }

                            ComboBox {
                                model: ["RGB", "HEX"]
                                currentIndex: settingsViewModel.defaultColorFormat === "HEX" ? 1 : 0
                                onActivated: settingsViewModel.setDefaultColorFormat(currentText)
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 82
                        color: "#FFFFFF"
                        border.color: "#ECE5DA"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 18

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Label {
                                    text: "Capture hotkey"
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                    color: "#262626"
                                }

                                Label {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    text: "The global shortcut used to launch the frozen screenshot flow. Current value: " + settingsViewModel.captureHotkey
                                    font.pixelSize: 13
                                    color: "#7B7973"
                                }
                            }

                            Button {
                                text: "Edit"
                                enabled: false
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 82
                        color: "#FFFFFF"
                        border.color: "#ECE5DA"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 18

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Label {
                                    text: "Default save naming"
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                    color: "#262626"
                                }

                                Label {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    text: "Hit-window captures can include application names, while manual regions stay generic."
                                    font.pixelSize: 13
                                    color: "#7B7973"
                                }
                            }

                            Rectangle {
                                implicitWidth: 210
                                implicitHeight: 34
                                radius: 12
                                color: "#F5F4F0"
                                border.color: "#ECE5DA"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14

                                    Label {
                                        Layout.fillWidth: true
                                        text: "App name + timestamp"
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                        color: "#313230"
                                    }

                                    Label {
                                        text: "\u2304"
                                        color: "#8B8881"
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 82
                        radius: 0
                        color: "#FFFFFF"
                        border.color: "#ECE5DA"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 18

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Label {
                                    text: "Follow-up behavior"
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                    color: "#262626"
                                }

                                Label {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    text: "Choose whether follow-up capture commands queue or steer the current interaction."
                                    font.pixelSize: 13
                                    color: "#7B7973"
                                }
                            }

                            RowLayout {
                                spacing: 8

                                Rectangle {
                                    width: 54
                                    height: 28
                                    radius: 14
                                    color: "#FFFFFF"
                                    border.color: "#DCD6CB"
                                    border.width: 1

                                    Label {
                                        anchors.centerIn: parent
                                        text: "Queue"
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        color: "#2C2D2B"
                                    }
                                }

                                Rectangle {
                                    width: 54
                                    height: 28
                                    radius: 14
                                    color: "#F4F2ED"
                                    border.color: "#DCD6CB"
                                    border.width: 1

                                    Label {
                                        anchors.centerIn: parent
                                        text: "Steer"
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        color: "#8B8881"
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        width: 1
                        height: 22
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 18

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 76
                            radius: 18
                            color: "#F8F5EF"
                            border.color: "#E9E3D9"
                            border.width: 1

                            Column {
                                anchors.fill: parent
                                anchors.margins: 18
                                spacing: 6

                                Label {
                                    text: "Settings are now a destination, not clutter on the home screen."
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                    color: "#171717"
                                }

                                Label {
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    text: "The workspace stays focused while detailed capture rules remain easy to scan and update."
                                    font.pixelSize: 13
                                    color: "#7D7B77"
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 240
                            Layout.preferredHeight: 56
                            radius: 20
                            color: "#171717"

                            Label {
                                anchors.centerIn: parent
                                text: "Confirm direction before coding"
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                color: "#F8F6F2"
                            }
                        }
                    }
                }
            }
        }
    }
}

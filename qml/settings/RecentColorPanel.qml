import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kuclaw

Rectangle {
    id: root

    function blendChannel(base, flash, emphasis) {
        return Math.round(base + (flash - base) * emphasis)
    }

    function rgbaHex(red, green, blue, alpha) {
        function toHex(value) {
            return Number(value).toString(16).padStart(2, "0")
        }

        return "#" + toHex(alpha) + toHex(red) + toHex(green) + toHex(blue)
    }

    radius: 20
    color: "#FFFDF8"
    border.color: "#D6CFBE"
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Label {
            text: "最近复制颜色"
            font.pixelSize: 20
            font.bold: true
        }

        Label {
            text: "当前记录数: " + colorHistoryViewModel.recentColorCount
            color: "#6E675C"
        }

        Label {
            visible: colorHistoryViewModel.recentColorCount === 0
            text: "还没有颜色复制记录。进入截图态后按 C 取色，这里会显示最近 20 条。"
            wrapMode: Text.WordWrap
            color: "#6E675C"
        }

        Repeater {
            model: colorHistoryViewModel.recentColors

            delegate: Rectangle {
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: rowLayout.implicitHeight + 20
                radius: 16
                color: "#F6F1E7"
                border.color: "#E0D8CA"

                RowLayout {
                    id: rowLayout
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        radius: 8
                        color: modelData.swatchHex
                        border.color: "#BFB7A8"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            id: colorValueText
                            Layout.fillWidth: true
                            property real copyFlash: 0.0
                            readonly property color baseColor: "#1F1E1A"
                            readonly property color flashColor: "#5BFF7F"
                            text: modelData.colorValue
                            wrapMode: Text.WrapAnywhere
                            font.bold: true
                            font.pixelSize: 15
                            font.weight: copyFlash > 0.15 ? Font.Bold : Font.DemiBold
                            color: root.rgbaHex(
                                       root.blendChannel(baseColor.r * 255, flashColor.r * 255, copyFlash),
                                       root.blendChannel(baseColor.g * 255, flashColor.g * 255, copyFlash),
                                       root.blendChannel(baseColor.b * 255, flashColor.b * 255, copyFlash),
                                       255)
                            scale: 1.0 + copyFlash * 0.05

                            Behavior on copyFlash {
                                NumberAnimation {
                                    duration: 220
                                    easing.type: Easing.OutCubic
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    colorHistoryViewModel.copyColorValue(modelData.colorValue)
                                    colorValueText.copyFlash = 1.0
                                    flashHoldTimer.restart()
                                }
                            }

                            Timer {
                                id: flashHoldTimer
                                interval: 200
                                repeat: false
                                onTriggered: colorValueText.copyFlash = 0.0
                            }
                        }

                        Label {
                            text: modelData.coordinatesLabel
                            color: "#6E675C"
                            wrapMode: Text.WordWrap
                        }

                        Label {
                            text: modelData.copiedAt
                            color: "#6E675C"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}

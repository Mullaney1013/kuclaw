import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kuclaw

Rectangle {
    radius: 20
    color: "#FFFDF8"
    border.color: "#D6CFBE"
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Label {
            text: "贴图面板"
            font.pixelSize: 20
            font.bold: true
        }

        Label {
            text: "当前贴图数: " + pinboardViewModel.pinCount
        }

        Label {
            text: "最近创建: " + (pinboardViewModel.lastCreatedPinId || "无")
            wrapMode: Text.WrapAnywhere
        }

        Button {
            text: "从剪贴板创建"
            onClicked: pinboardViewModel.pinFromClipboard()
        }

        Button {
            text: "隐藏全部"
            onClicked: pinboardViewModel.hideAllPins()
        }

        Button {
            text: "恢复最近关闭"
            onClicked: pinboardViewModel.restoreLastClosed()
        }
    }
}

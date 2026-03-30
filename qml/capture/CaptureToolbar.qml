import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kuclaw

Frame {
    id: root

    background: Rectangle {
        radius: 16
        color: "#FFFDF8"
        border.color: "#D6CFBE"
    }

    RowLayout {
        spacing: 12

        Button {
            text: "复制"
            onClicked: captureViewModel.copy()
        }

        Button {
            text: "保存"
            onClicked: captureViewModel.save()
        }

        Button {
            text: "贴到屏幕"
            onClicked: captureViewModel.pin()
        }

        Button {
            text: "取消"
            onClicked: captureViewModel.cancelCapture()
        }
    }
}

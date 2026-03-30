import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kuclaw

Frame {
    id: root

    property string colorHex: captureViewModel.currentColorString
    property string coordinateText: ""

    background: Rectangle {
        radius: 18
        color: "#FFFDF8"
        border.color: "#D6CFBE"
    }

    ColumnLayout {
        spacing: 8

        Label {
            text: "像素放大镜"
            font.bold: true
        }

        Item {
            Layout.preferredWidth: 144
            Layout.preferredHeight: 144

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: "#EEE7D9"
                border.color: "#D6CFBE"
            }

            Image {
                anchors.fill: parent
                anchors.margins: 8
                source: captureViewModel.magnifierImageUrl
                fillMode: Image.PreserveAspectFit
                smooth: false
                cache: false
            }

            Rectangle {
                anchors.centerIn: parent
                width: 18
                height: 18
                radius: 9
                color: "transparent"
                border.color: "#D95D39"
                border.width: 2
            }

            Rectangle {
                anchors.centerIn: parent
                width: 2
                height: parent.height - 28
                color: "#66D95D39"
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 28
                height: 2
                color: "#66D95D39"
            }
        }

        RowLayout {
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                radius: 6
                color: root.colorHex
                border.color: "#D6CFBE"
            }

            Label {
                text: root.colorHex
            }
        }

        Label {
            text: root.coordinateText
            color: "#6E675C"
        }

        Label {
            text: "中心像素 " + root.colorHex
            color: "#6E675C"
        }
    }
}

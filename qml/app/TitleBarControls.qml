import QtQuick

Item {
    id: root

    property bool backEnabled: false
    property bool forwardEnabled: false
    property bool showTrafficLights: true
    property bool routeClicksThroughNative: false
    property real sidebarToggleLeftMargin: 94
    property real backButtonX: 40
    property real forwardButtonX: 56
    property string sidebarToggleIconSource: "qrc:/qt/qml/Kuclaw/assets/icons/sidebar-toggle.svg"

    property alias sidebarToggleTarget: sidebarToggleMouseArea
    property alias sidebarToggleIconTarget: sidebarToggleIcon
    property alias backButtonTarget: backButtonMouseArea
    property alias forwardButtonTarget: forwardButtonMouseArea

    signal closeRequested()
    signal minimizeRequested()
    signal maximizeRequested()
    signal sidebarToggleRequested()
    signal backRequested()
    signal forwardRequested()
    signal controlRectsSyncRequested()

    width: 176
    height: 20

    function requestSidebarToggle() {
        root.sidebarToggleRequested()
    }

    function requestBack() {
        if (root.backEnabled) {
            root.backRequested()
        }
    }

    function requestForward() {
        if (root.forwardEnabled) {
            root.forwardRequested()
        }
    }

    onBackEnabledChanged: root.controlRectsSyncRequested()
    onForwardEnabledChanged: root.controlRectsSyncRequested()

    Row {
        visible: root.showTrafficLights
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Repeater {
            model: [
                { color: "#FF5F57", action: "close" },
                { color: "#FFBD2E", action: "minimize" },
                { color: "#28C840", action: "maximize" }
            ]

            delegate: Rectangle {
                required property var modelData
                width: 16
                height: 16
                radius: 8
                color: modelData.color
                border.width: 1
                border.color: Qt.darker(modelData.color, 1.05)

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (parent.modelData.action === "close") {
                            root.closeRequested()
                        } else if (parent.modelData.action === "minimize") {
                            root.minimizeRequested()
                        } else {
                            root.maximizeRequested()
                        }
                    }
                }
            }
        }
    }

    Item {
        anchors.left: parent.left
        anchors.leftMargin: root.sidebarToggleLeftMargin
        anchors.verticalCenter: parent.verticalCenter
        width: 82
        height: 18

        Item {
            id: sidebarToggleButton
            width: 20
            height: 16

            Image {
                id: sidebarToggleIcon
                anchors.centerIn: parent
                width: 20
                height: 16
                source: root.sidebarToggleIconSource
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 20
                sourceSize.height: 16
            }

            MouseArea {
                id: sidebarToggleMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: function(mouse) {
                    if (root.routeClicksThroughNative) {
                        mouse.accepted = false
                    }
                }
                onClicked: {
                    if (!root.routeClicksThroughNative) {
                        root.requestSidebarToggle()
                    }
                }
            }
        }

        Item {
            id: backButton
            x: root.backButtonX
            y: 0
            width: 12
            height: 14

            Canvas {
                anchors.fill: parent

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.strokeStyle = root.backEnabled ? "#81868B" : "#AEB2B7"
                    ctx.lineWidth = 1.35
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()
                    ctx.moveTo(8.5, 1.5)
                    ctx.lineTo(3.5, 7)
                    ctx.lineTo(8.5, 12.5)
                    ctx.stroke()
                }
            }

            MouseArea {
                id: backButtonMouseArea
                anchors.fill: parent
                enabled: root.backEnabled
                cursorShape: root.backEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onPressed: function(mouse) {
                    if (root.routeClicksThroughNative) {
                        mouse.accepted = false
                    }
                }
                onClicked: {
                    if (!root.routeClicksThroughNative) {
                        root.requestBack()
                    }
                }
            }
        }

        Item {
            id: forwardButton
            x: root.forwardButtonX
            y: 0
            width: 12
            height: 14
            opacity: root.forwardEnabled ? 1.0 : 0.48

            Canvas {
                anchors.fill: parent

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.strokeStyle = root.forwardEnabled ? "#81868B" : "#AEB2B7"
                    ctx.lineWidth = 1.35
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()
                    ctx.moveTo(2.5, 1.5)
                    ctx.lineTo(7.5, 7)
                    ctx.lineTo(2.5, 12.5)
                    ctx.stroke()
                }
            }

            MouseArea {
                id: forwardButtonMouseArea
                anchors.fill: parent
                enabled: root.forwardEnabled
                cursorShape: root.forwardEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onPressed: function(mouse) {
                    if (root.routeClicksThroughNative) {
                        mouse.accepted = false
                    }
                }
                onClicked: {
                    if (!root.routeClicksThroughNative) {
                        root.requestForward()
                    }
                }
            }
        }
    }
}

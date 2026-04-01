import QtQuick

Item {
    id: root

    signal dragRequested()

    property bool interactionEnabled: true
    property var systemMoveHandler: null
    property bool beginDragOnPress: false
    property bool dragTriggered: false
    property bool dragPressed: false

    function beginDragGesture() {
        if (!root.interactionEnabled) {
            return false
        }

        if (root.dragTriggered) {
            return false
        }

        root.dragTriggered = true
        if (root.systemMoveHandler) {
            root.systemMoveHandler()
        } else {
            root.dragRequested()
        }
        return true
    }

    function handlePressGesture() {
        if (!root.interactionEnabled) {
            return false
        }

        root.dragPressed = true
        if (root.beginDragOnPress) {
            return root.beginDragGesture()
        }
        return true
    }

    function handleMoveGesture() {
        if (!root.dragPressed) {
            return false
        }

        return root.beginDragGesture()
    }

    function endDragGesture() {
        root.dragTriggered = false
        root.dragPressed = false
    }

    function cancelDragGesture() {
        root.dragTriggered = false
        root.dragPressed = false
    }

    function handleDragActiveChanged(active) {
        if (active) {
            root.handlePressGesture()
            return root.handleMoveGesture()
        }

        root.endDragGesture()
        return false
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactionEnabled
        acceptedButtons: Qt.LeftButton

        onPressed: {
            root.handlePressGesture()
        }

        onPositionChanged: {
            if (pressed && !root.dragTriggered) {
                root.handleMoveGesture()
            }
        }

        onReleased: {
            root.endDragGesture()
        }

        onCanceled: {
            root.cancelDragGesture()
        }
    }
}

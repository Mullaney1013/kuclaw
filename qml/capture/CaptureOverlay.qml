import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kuclaw

Item {
    id: root

    readonly property string stateIdle: "idle"
    readonly property string stateHovering: "hovering"
    readonly property string stateDraggingNew: "dragging_new"
    readonly property string stateAdjusting: "adjusting"
    readonly property string stateMovingSelection: "moving_selection"

    readonly property int handleNone: 0
    readonly property int handleTopLeft: 1
    readonly property int handleTop: 2
    readonly property int handleTopRight: 3
    readonly property int handleRight: 4
    readonly property int handleBottomRight: 5
    readonly property int handleBottom: 6
    readonly property int handleBottomLeft: 7
    readonly property int handleLeft: 8

    readonly property int handleHitSize: 10
    readonly property int minSelectionSide: 1
    readonly property int floatingGap: 12
    readonly property int clickDragThreshold: 3
    readonly property color smartSnapAccent: "#66E6FF"
    readonly property color smartSnapAccentSoft: "#D8FBFF"
    readonly property color committedAccent: "#2DF56B"
    readonly property color committedAccentSoft: "#B7FFC8"
    readonly property string selectionBadgeText: hasSmartSnapCandidate
                                                 ? "智能吸附  单击确认"
                                                 : "已确认选区  可拖动/微调"
    readonly property rect selectionRect: Qt.rect(
                                              captureViewModel.selectionRect.x - windowOriginX,
                                              captureViewModel.selectionRect.y - windowOriginY,
                                              captureViewModel.selectionRect.width,
                                              captureViewModel.selectionRect.height
                                          )

    readonly property bool hasSelection: captureViewModel.hasSelection
    readonly property bool hasSmartSnapCandidate: hasSelection && captureViewModel.isWindowAutoSelectionEnabled()
    readonly property bool hasCommittedSelection: hasSelection && !captureViewModel.isWindowAutoSelectionEnabled()
    readonly property int hoveredHandle: hasCommittedSelection ? handleUnderPoint(cursorPos.x, cursorPos.y) : handleNone
    readonly property bool cursorInsideCommittedSelection: hasCommittedSelection
                                                        && pointInsideSelection(cursorPos.x, cursorPos.y)
    readonly property bool selectionAnchorInWindow: hasSelection
                                                 && pointWithinWindow(selectionRect.x + selectionRect.width / 2,
                                                                      selectionRect.y + selectionRect.height / 2)
    readonly property bool localInteractionActive: leftButtonDown
                                                || interactionState !== stateIdle
                                                || (!hasSelection && interactionLayer.containsMouse)
    readonly property bool showFloatingChrome: hasSelection
                                            ? (selectionAnchorInWindow || leftButtonDown || interactionState !== stateIdle)
                                            : localInteractionActive
    readonly property bool showLoupe: altPressed
                                   || interactionState === stateDraggingNew
                                   || interactionState === stateAdjusting
                                   || hoveredHandle !== handleNone
    readonly property int cursorGlobalX: Math.round(cursorPos.x + captureViewModel.desktopGeometry.x + windowOriginX)
    readonly property int cursorGlobalY: Math.round(cursorPos.y + captureViewModel.desktopGeometry.y + windowOriginY)
    readonly property int desktopImageWidth: Math.max(1, captureViewModel.desktopGeometry.width)
    readonly property int desktopImageHeight: Math.max(1, captureViewModel.desktopGeometry.height)

    property string interactionState: stateIdle
    property int activeHandle: handleNone
    property point pressPoint: Qt.point(0, 0)
    property point cursorPos: Qt.point(0, 0)
    property bool leftButtonDown: false
    property bool clickCandidate: false
    property bool dragTriggered: false
    property bool altPressed: false
    property int pressSelectionX: 0
    property int pressSelectionY: 0
    property int pressSelectionW: 0
    property int pressSelectionH: 0
    property real smartSnapBreath: 0.0
    property real commitSweepInset: 0.0
    property real commitSweepOpacity: 0.0
    property real selectionBadgePulse: 0.0
    property bool toolbarHostWindow: false
    property int windowOriginX: 0
    property int windowOriginY: 0

    focus: visible
    Keys.enabled: true
    Keys.priority: Qt.HighPriority

    onHasSmartSnapCandidateChanged: {
        if (!hasSmartSnapCandidate) {
            smartSnapBreath = 0.0
        }
    }

    onSelectionBadgeTextChanged: {
        if (hasSelection) {
            selectionBadgeTransitionAnimation.restart()
        }
    }

    function clampInt(value, low, high) {
        return Math.max(low, Math.min(high, value))
    }

    function pointInsideSelection(x, y) {
        const rect = selectionRect
        return rect.width > 0
            && rect.height > 0
            && x >= rect.x
            && x <= rect.x + rect.width
            && y >= rect.y
            && y <= rect.y + rect.height
    }

    function pointWithinWindow(x, y) {
        return x >= 0 && x <= root.width && y >= 0 && y <= root.height
    }

    function setSelectionRectLocal(x, y, width, height) {
        captureViewModel.setSelectionRect(x + windowOriginX, y + windowOriginY, width, height)
    }

    function updateCursorPointLocal(x, y, trackWindow) {
        captureViewModel.updateCursorPoint(x + windowOriginX, y + windowOriginY, trackWindow)
    }

    function moveSelectionToLocal(x, y) {
        captureViewModel.moveSelectionTo(x + windowOriginX, y + windowOriginY)
    }

    function clampSelectionRect(x, y, width, height) {
        const clampedX = clampInt(x, 0, Math.max(0, root.width - minSelectionSide))
        const clampedY = clampInt(y, 0, Math.max(0, root.height - minSelectionSide))
        return Qt.rect(
            clampedX,
            clampedY,
            clampInt(width, minSelectionSide, root.width - clampedX),
            clampInt(height, minSelectionSide, root.height - clampedY)
        )
    }

    // Normalize rectangles so reverse dragging and anchor flipping stay stable.
    function normalizeRect(x1, y1, x2, y2) {
        return clampSelectionRect(
            Math.min(x1, x2),
            Math.min(y1, y2),
            Math.abs(x2 - x1),
            Math.abs(y2 - y1)
        )
    }

    function updateCursorFeedback(mouseX, mouseY, trackWindow) {
        updateCursorPointLocal(mouseX, mouseY, trackWindow)
        if (!leftButtonDown) {
            if (hasSmartSnapCandidate) {
                interactionState = stateHovering
            } else if (!hasSelection) {
                interactionState = stateIdle
            }
        }
    }

    function handleUnderPoint(x, y) {
        const rect = selectionRect
        if (!hasCommittedSelection || rect.width <= 0 || rect.height <= 0) {
            return handleNone
        }

        const left = rect.x
        const top = rect.y
        const right = rect.x + rect.width
        const bottom = rect.y + rect.height
        const h = handleHitSize

        if (Math.abs(x - left) <= h && Math.abs(y - top) <= h) {
            return handleTopLeft
        }
        if (Math.abs(x - right) <= h && Math.abs(y - top) <= h) {
            return handleTopRight
        }
        if (Math.abs(x - right) <= h && Math.abs(y - bottom) <= h) {
            return handleBottomRight
        }
        if (Math.abs(x - left) <= h && Math.abs(y - bottom) <= h) {
            return handleBottomLeft
        }
        if (Math.abs(y - top) <= h && x > left + h && x < right - h) {
            return handleTop
        }
        if (Math.abs(y - bottom) <= h && x > left + h && x < right - h) {
            return handleBottom
        }
        if (Math.abs(x - left) <= h && y > top + h && y < bottom - h) {
            return handleLeft
        }
        if (Math.abs(x - right) <= h && y > top + h && y < bottom - h) {
            return handleRight
        }
        return handleNone
    }

    function cursorForCurrentHover() {
        if (hoveredHandle === handleTopLeft || hoveredHandle === handleBottomRight) {
            return Qt.SizeFDiagCursor
        }
        if (hoveredHandle === handleTopRight || hoveredHandle === handleBottomLeft) {
            return Qt.SizeBDiagCursor
        }
        if (hoveredHandle === handleLeft || hoveredHandle === handleRight) {
            return Qt.SizeHorCursor
        }
        if (hoveredHandle === handleTop || hoveredHandle === handleBottom) {
            return Qt.SizeVerCursor
        }
        if (cursorInsideCommittedSelection || interactionState === stateMovingSelection) {
            return Qt.SizeAllCursor
        }
        return Qt.CrossCursor
    }

    function moveSelection(dx, dy) {
        if (!hasCommittedSelection) {
            return
        }
        captureViewModel.moveSelectionBy(dx, dy)
    }

    function resizeSelection(left, top, right, bottom) {
        if (!hasCommittedSelection) {
            return
        }
        captureViewModel.resizeSelectionBy(left, top, right, bottom)
    }

    function commitCurrentHoverSelection() {
        if (!hasSelection) {
            return
        }
        const rect = selectionRect
        setSelectionRectLocal(rect.x, rect.y, rect.width, rect.height)
        playCommitAnimation()
        interactionState = stateIdle
    }

    function beginNewSelection(mouseX, mouseY) {
        interactionState = stateDraggingNew
        clickCandidate = false
        dragTriggered = true
        setSelectionRectLocal(mouseX, mouseY, minSelectionSide, minSelectionSide)
        updateCursorPointLocal(mouseX, mouseY, false)
    }

    function beginSelectionMove() {
        const rect = selectionRect
        interactionState = stateMovingSelection
        pressSelectionX = rect.x
        pressSelectionY = rect.y
        pressSelectionW = rect.width
        pressSelectionH = rect.height
    }

    function beginSelectionAdjust(handle) {
        const rect = selectionRect
        interactionState = stateAdjusting
        activeHandle = handle
        pressSelectionX = rect.x
        pressSelectionY = rect.y
        pressSelectionW = rect.width
        pressSelectionH = rect.height
    }

    function applySelectionMove(mouseX, mouseY) {
        const dx = mouseX - pressPoint.x
        const dy = mouseY - pressPoint.y
        const nextRect = clampSelectionRect(
            pressSelectionX + dx,
            pressSelectionY + dy,
            pressSelectionW,
            pressSelectionH
        )
        moveSelectionToLocal(nextRect.x, nextRect.y)
    }

    // Resize uses the opposite edge/corner as a stable anchor, so crossing over
    // the anchor still produces a valid normalized selection instead of corrupting coordinates.
    function applySelectionAdjust(mouseX, mouseY) {
        const left = pressSelectionX
        const top = pressSelectionY
        const right = pressSelectionX + pressSelectionW
        const bottom = pressSelectionY + pressSelectionH
        let nextRect = Qt.rect(left, top, pressSelectionW, pressSelectionH)

        switch (activeHandle) {
        case handleTopLeft:
            nextRect = normalizeRect(mouseX, mouseY, right, bottom)
            break
        case handleTop:
            nextRect = normalizeRect(left, mouseY, right, bottom)
            break
        case handleTopRight:
            nextRect = normalizeRect(left, mouseY, mouseX, bottom)
            break
        case handleRight:
            nextRect = normalizeRect(left, top, mouseX, bottom)
            break
        case handleBottomRight:
            nextRect = normalizeRect(left, top, mouseX, mouseY)
            break
        case handleBottom:
            nextRect = normalizeRect(left, top, right, mouseY)
            break
        case handleBottomLeft:
            nextRect = normalizeRect(mouseX, top, right, mouseY)
            break
        case handleLeft:
            nextRect = normalizeRect(mouseX, top, right, bottom)
            break
        default:
            break
        }

        setSelectionRectLocal(nextRect.x, nextRect.y, nextRect.width, nextRect.height)
    }

    function resetInteractionState() {
        interactionState = stateIdle
        activeHandle = handleNone
        clickCandidate = false
        dragTriggered = false
        leftButtonDown = false
        altPressed = false
    }

    function playCommitAnimation() {
        commitSelectionAnimation.restart()
    }

    SequentialAnimation {
        id: smartSnapBreathAnimation
        loops: Animation.Infinite
        running: hasSmartSnapCandidate

        NumberAnimation {
            target: root
            property: "smartSnapBreath"
            from: 0.0
            to: 1.0
            duration: 900
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            target: root
            property: "smartSnapBreath"
            from: 1.0
            to: 0.0
            duration: 900
            easing.type: Easing.InOutSine
        }
    }

    SequentialAnimation {
        id: commitSelectionAnimation
        running: false

        ScriptAction {
            script: {
                root.commitSweepInset = 18
                root.commitSweepOpacity = 0.92
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "commitSweepInset"
                to: 0
                duration: 180
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: root
                property: "commitSweepOpacity"
                to: 0
                duration: 220
                easing.type: Easing.OutQuad
            }
        }
    }

    SequentialAnimation {
        id: selectionBadgeTransitionAnimation
        running: false

        ScriptAction {
            script: {
                root.selectionBadgePulse = 0.0
            }
        }

        NumberAnimation {
            target: root
            property: "selectionBadgePulse"
            from: 0.0
            to: 1.0
            duration: 120
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "selectionBadgePulse"
            from: 1.0
            to: 0.0
            duration: 170
            easing.type: Easing.OutCubic
        }
    }

    Image {
        x: -windowOriginX
        y: -windowOriginY
        width: desktopImageWidth
        height: desktopImageHeight
        source: captureViewModel.desktopSnapshotUrl
        fillMode: Image.Stretch
        smooth: false
        cache: false
    }

    Rectangle {
        visible: !hasSelection
        anchors.fill: parent
        color: "#7A101214"
    }

    Rectangle {
        visible: hasSelection
        x: 0
        y: 0
        width: root.width
        height: Math.max(0, selectionRect.y)
        color: "#7A101214"
    }

    Rectangle {
        visible: hasSelection
        x: 0
        y: selectionRect.y
        width: Math.max(0, selectionRect.x)
        height: selectionRect.height
        color: "#7A101214"
    }

    Rectangle {
        visible: hasSelection
        x: selectionRect.x + selectionRect.width
        y: selectionRect.y
        width: Math.max(0, root.width - x)
        height: selectionRect.height
        color: "#7A101214"
    }

    Rectangle {
        visible: hasSelection
        x: 0
        y: selectionRect.y + selectionRect.height
        width: root.width
        height: Math.max(0, root.height - y)
        color: "#7A101214"
    }

    Rectangle {
        visible: hasSmartSnapCandidate
        x: selectionRect.x - (6 + smartSnapBreath * 5)
        y: selectionRect.y - (6 + smartSnapBreath * 5)
        width: selectionRect.width + 12 + smartSnapBreath * 10
        height: selectionRect.height + 12 + smartSnapBreath * 10
        color: "transparent"
        border.color: Qt.rgba(0.4, 0.9, 1.0, 0.24 + smartSnapBreath * 0.30)
        border.width: 2
        opacity: 0.72 + smartSnapBreath * 0.28
    }

    Rectangle {
        visible: hasSmartSnapCandidate
        x: selectionRect.x - 2
        y: selectionRect.y - 2
        width: selectionRect.width + 4
        height: selectionRect.height + 4
        color: Qt.rgba(0.4, 0.9, 1.0, 0.03 + smartSnapBreath * 0.04)
        border.color: "transparent"
        opacity: 0.55 + smartSnapBreath * 0.18
    }

    Rectangle {
        visible: hasSelection
        x: selectionRect.x
        y: selectionRect.y
        width: selectionRect.width
        height: selectionRect.height
        color: "transparent"
        border.color: hasSmartSnapCandidate ? smartSnapAccent : committedAccent
        border.width: hasSmartSnapCandidate ? 3 : 2
    }

    Rectangle {
        visible: hasSelection
        x: selectionRect.x + 1
        y: selectionRect.y + 1
        width: Math.max(0, selectionRect.width - 2)
        height: Math.max(0, selectionRect.height - 2)
        color: "transparent"
        border.color: hasSmartSnapCandidate ? smartSnapAccentSoft : committedAccentSoft
        border.width: 1
        opacity: hasSmartSnapCandidate ? 0.85 : 0.75
    }

    Rectangle {
        visible: hasCommittedSelection
        x: selectionRect.x
        y: selectionRect.y - 1
        width: selectionRect.width
        height: 1
        color: committedAccentSoft
    }

    Rectangle {
        visible: hasCommittedSelection
        x: selectionRect.x
        y: selectionRect.y + selectionRect.height
        width: selectionRect.width
        height: 1
        color: committedAccentSoft
    }

    Rectangle {
        visible: hasCommittedSelection
        x: selectionRect.x - 1
        y: selectionRect.y
        width: 1
        height: selectionRect.height
        color: committedAccentSoft
    }

    Rectangle {
        visible: hasCommittedSelection
        x: selectionRect.x + selectionRect.width
        y: selectionRect.y
        width: 1
        height: selectionRect.height
        color: committedAccentSoft
    }

    Repeater {
        model: hasSmartSnapCandidate ? 4 : 0
        delegate: Item {
            readonly property int cornerSize: 28
            readonly property int stroke: 4
            x: {
                if (index === 0 || index === 3) {
                    return selectionRect.x - 2
                }
                return selectionRect.x + selectionRect.width - cornerSize + 2
            }
            y: {
                if (index === 0 || index === 1) {
                    return selectionRect.y - 2
                }
                return selectionRect.y + selectionRect.height - cornerSize + 2
            }
            width: cornerSize
            height: cornerSize

            Rectangle {
                x: 0
                y: 0
                width: parent.width
                height: stroke
                visible: index === 0 || index === 1
                color: smartSnapAccent
                opacity: 0.68 + smartSnapBreath * 0.32
            }

            Rectangle {
                x: 0
                y: parent.height - stroke
                width: parent.width
                height: stroke
                visible: index === 2 || index === 3
                color: smartSnapAccent
                opacity: 0.68 + smartSnapBreath * 0.32
            }

            Rectangle {
                x: 0
                y: 0
                width: stroke
                height: parent.height
                visible: index === 0 || index === 3
                color: smartSnapAccent
                opacity: 0.68 + smartSnapBreath * 0.32
            }

            Rectangle {
                x: parent.width - stroke
                y: 0
                width: stroke
                height: parent.height
                visible: index === 1 || index === 2
                color: smartSnapAccent
                opacity: 0.68 + smartSnapBreath * 0.32
            }
        }
    }

    Rectangle {
        visible: hasCommittedSelection && commitSweepOpacity > 0.01
        x: selectionRect.x - commitSweepInset
        y: selectionRect.y - commitSweepInset
        width: selectionRect.width + commitSweepInset * 2
        height: selectionRect.height + commitSweepInset * 2
        color: "transparent"
        border.color: committedAccentSoft
        border.width: 2
        opacity: commitSweepOpacity
    }

    Rectangle {
        visible: hasCommittedSelection && commitSweepOpacity > 0.01
        x: selectionRect.x - commitSweepInset * 0.45
        y: selectionRect.y - commitSweepInset * 0.45
        width: selectionRect.width + commitSweepInset * 0.9
        height: selectionRect.height + commitSweepInset * 0.9
        color: "transparent"
        border.color: committedAccent
        border.width: 1
        opacity: commitSweepOpacity * 0.8
    }

    Rectangle {
        id: selectionBadge
        visible: opacity > 0.01
        opacity: showFloatingChrome ? 1.0 : 0.0
        scale: (showFloatingChrome ? 1.0 : 0.96) + selectionBadgePulse * 0.04
        x: clampInt(
               selectionRect.x + 12,
               floatingGap,
               root.width - width - floatingGap
           )
        y: clampInt(
               selectionRect.y - height - 12,
               floatingGap,
               root.height - height - floatingGap
           ) - selectionBadgePulse * 4
        width: badgeLabel.implicitWidth + 22
        height: 34
        radius: 10
        color: hasSmartSnapCandidate ? "#D0162A38" : "#D0122B1A"
        border.color: hasSmartSnapCandidate ? smartSnapAccent : committedAccent
        border.width: 1

        Behavior on x {
            NumberAnimation {
                duration: 130
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: 130
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 170
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 170
                easing.type: Easing.OutCubic
            }
        }

        Label {
            id: badgeLabel
            anchors.centerIn: parent
            text: selectionBadgeText
            color: hasSmartSnapCandidate ? smartSnapAccentSoft : committedAccentSoft
            font.bold: true
            font.pixelSize: 13
        }
    }

    Repeater {
        model: hasCommittedSelection ? 8 : 0
        delegate: Rectangle {
            readonly property int handleType: index + 1
            readonly property rect handleRect: {
                const rect = selectionRect
                const left = rect.x
                const top = rect.y
                const right = rect.x + rect.width
                const bottom = rect.y + rect.height
                const h = root.handleHitSize

                if (handleType === root.handleTopLeft) {
                    return Qt.rect(left - h, top - h, h * 2, h * 2)
                }
                if (handleType === root.handleTop) {
                    return Qt.rect(left + h, top - h, Math.max(14, rect.width - h * 2), h * 2)
                }
                if (handleType === root.handleTopRight) {
                    return Qt.rect(right - h, top - h, h * 2, h * 2)
                }
                if (handleType === root.handleRight) {
                    return Qt.rect(right - h, top + h, h * 2, Math.max(14, rect.height - h * 2))
                }
                if (handleType === root.handleBottomRight) {
                    return Qt.rect(right - h, bottom - h, h * 2, h * 2)
                }
                if (handleType === root.handleBottom) {
                    return Qt.rect(left + h, bottom - h, Math.max(14, rect.width - h * 2), h * 2)
                }
                if (handleType === root.handleBottomLeft) {
                    return Qt.rect(left - h, bottom - h, h * 2, h * 2)
                }
                return Qt.rect(left - h, top + h, h * 2, Math.max(14, rect.height - h * 2))
            }

            x: handleRect.x
            y: handleRect.y
            width: handleRect.width
            height: handleRect.height
            radius: 6
            color: committedAccentSoft
            opacity: hoveredHandle === handleType ? 1.0 : 0.88
        }
    }

    Rectangle {
        id: sizeHint
        visible: opacity > 0.01
        opacity: showFloatingChrome ? 1.0 : 0.0
        scale: showFloatingChrome ? 1.0 : 0.96
        x: {
            const targetX = cursorPos.x + floatingGap
            return clampInt(targetX, floatingGap, root.width - width - floatingGap)
        }
        y: {
            const targetY = cursorPos.y + floatingGap
            return clampInt(targetY, floatingGap, root.height - height - floatingGap)
        }
        width: sizeText.implicitWidth + 18
        height: 34
        radius: 9
        color: hasSmartSnapCandidate ? "#D0152730" : "#D0122417"
        border.color: hasSmartSnapCandidate ? smartSnapAccent : committedAccent
        border.width: 1

        Behavior on x {
            NumberAnimation {
                duration: 110
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: 110
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Label {
            id: sizeText
            anchors.centerIn: parent
            text: selectionRect.width + " x " + selectionRect.height
            color: hasSmartSnapCandidate ? smartSnapAccentSoft : committedAccentSoft
            font.bold: true
        }
    }

    // A single MouseArea owns press/move/release/hover, which avoids
    // overlapping handler conflicts and keeps the state machine predictable.
    MouseArea {
        id: interactionLayer
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        preventStealing: true
        propagateComposedEvents: false
        cursorShape: root.cursorForCurrentHover()

        onPressed: mouse => {
            leftButtonDown = true
            clickCandidate = true
            dragTriggered = false
            pressPoint = Qt.point(mouse.x, mouse.y)
            cursorPos = pressPoint

            if (hasCommittedSelection && hoveredHandle !== handleNone) {
                beginSelectionAdjust(hoveredHandle)
            } else if (hasCommittedSelection && pointInsideSelection(mouse.x, mouse.y)) {
                beginSelectionMove()
            } else if (hasSmartSnapCandidate && pointInsideSelection(mouse.x, mouse.y)) {
                interactionState = stateHovering
            } else {
                beginNewSelection(mouse.x, mouse.y)
            }
        }

        onPositionChanged: mouse => {
            cursorPos = Qt.point(mouse.x, mouse.y)

            if (!leftButtonDown) {
                updateCursorFeedback(mouse.x, mouse.y, !hasCommittedSelection)
                return
            }

            const moved = Math.abs(mouse.x - pressPoint.x) > clickDragThreshold
                       || Math.abs(mouse.y - pressPoint.y) > clickDragThreshold

            if (interactionState === stateHovering && clickCandidate && moved) {
                beginNewSelection(pressPoint.x, pressPoint.y)
            }

            switch (interactionState) {
            case stateDraggingNew: {
                const rect = normalizeRect(pressPoint.x, pressPoint.y, mouse.x, mouse.y)
                setSelectionRectLocal(rect.x, rect.y, rect.width, rect.height)
                updateCursorPointLocal(mouse.x, mouse.y, false)
                dragTriggered = true
                break
            }
            case stateAdjusting:
                applySelectionAdjust(mouse.x, mouse.y)
                updateCursorPointLocal(mouse.x, mouse.y, false)
                dragTriggered = true
                break
            case stateMovingSelection:
                applySelectionMove(mouse.x, mouse.y)
                updateCursorPointLocal(mouse.x, mouse.y, false)
                dragTriggered = true
                break
            default:
                updateCursorPointLocal(mouse.x, mouse.y, false)
                break
            }
        }

        onReleased: mouse => {
            cursorPos = Qt.point(mouse.x, mouse.y)

            if (interactionState === stateHovering
                    && clickCandidate
                    && !dragTriggered
                    && hasSmartSnapCandidate
                    && pointInsideSelection(mouse.x, mouse.y)) {
                commitCurrentHoverSelection()
            } else if (interactionState === stateDraggingNew) {
                if (hasCommittedSelection) {
                    playCommitAnimation()
                }
                interactionState = stateIdle
            } else if (interactionState === stateAdjusting
                       || interactionState === stateMovingSelection) {
                interactionState = stateIdle
            }

            activeHandle = handleNone
            leftButtonDown = false
            clickCandidate = false
            dragTriggered = false
            updateCursorFeedback(mouse.x, mouse.y, !hasCommittedSelection)
        }

        onDoubleClicked: mouse => {
            if (mouse.button !== Qt.LeftButton) {
                return
            }
            captureViewModel.copyFullScreen()
            resetInteractionState()
        }

        onCanceled: resetInteractionState()
    }

    Magnifier {
        id: magnifierPanel
        visible: opacity > 0.01
        enabled: opacity > 0.9
        opacity: showLoupe && localInteractionActive ? 1.0 : 0.0
        scale: showLoupe && localInteractionActive ? 1.0 : 0.94
        transformOrigin: Item.BottomLeft
        colorHex: captureViewModel.currentColorString
        coordinateText: "(" + cursorGlobalX + ", " + cursorGlobalY + ")"
        x: clampInt(cursorPos.x + 18, floatingGap, root.width - width - floatingGap)
        y: clampInt(cursorPos.y - height - 18, floatingGap, root.height - height - floatingGap)
           - (showLoupe ? 0 : 4)
        z: 10

        Behavior on x {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 170
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 170
                easing.type: Easing.OutCubic
            }
        }
    }

    CaptureToolbar {
        id: captureToolbar
        z: 10
        visible: opacity > 0.01
        enabled: opacity > 0.9
        opacity: (captureViewModel.overlayVisible
                  && (hasSelection ? showFloatingChrome : toolbarHostWindow)) ? 1.0 : 0.0
        scale: (captureViewModel.overlayVisible
                && (hasSelection ? showFloatingChrome : toolbarHostWindow)) ? 1.0 : 0.96
        transformOrigin: Item.Top
        x: {
            const toolbarWidth = Math.max(implicitWidth, width)
            if (!hasSelection) {
                return (root.width - toolbarWidth) / 2
            }
            const centeredX = selectionRect.x
                            + selectionRect.width / 2
                            - toolbarWidth / 2
            return clampInt(centeredX, 12, root.width - toolbarWidth - 12)
        }
        y: {
            const toolbarHeight = Math.max(implicitHeight, height)
            if (!hasSelection) {
                return root.height - toolbarHeight - 24
            }
            const belowSelection = selectionRect.y
                                 + selectionRect.height
                                 + 12
            if (belowSelection + toolbarHeight + 12 <= root.height) {
                return belowSelection
            }
            return Math.max(12, selectionRect.y - toolbarHeight - 12)
        }

        Behavior on x {
            NumberAnimation {
                duration: 130
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: 130
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 170
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 170
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        visible: windowOriginX === 0 && windowOriginY === 0
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 24
        anchors.bottomMargin: 24
        width: 380
        height: 176
        radius: 16
        color: "#CC1A1A1A"
        z: 10

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            Label {
                text: "智能吸附: 鼠标悬浮时使用 macOS CGWindow API 识别真实窗口边界。"
                color: "#F5F2EC"
                wrapMode: Text.WordWrap
            }

            Label {
                text: "自由框选: 非高亮区域按下左键开始拖拽，可反向生成选区。"
                color: "#E0D8CA"
                wrapMode: Text.WordWrap
            }

            Label {
                text: "二次调整: 8 个锚点缩放，内部拖拽移动；Esc 取消，Enter/Ctrl+C 复制。"
                color: "#E0D8CA"
                wrapMode: Text.WordWrap
            }

            Label {
                text: "放大镜: 拖拽/调节/边缘 hover 自动显示，Alt 可强制保持显示。"
                color: "#E0D8CA"
                wrapMode: Text.WordWrap
            }

            Label {
                text: "当前状态: " + interactionState + " | 颜色: " + captureViewModel.currentColorString
                color: "#F5F2EC"
                wrapMode: Text.WordWrap
            }
        }
    }

    Keys.onEscapePressed: event => {
        captureViewModel.cancelCapture()
        resetInteractionState()
        event.accepted = true
    }

    Keys.onEnterPressed: event => {
        if (hasSelection) {
            captureViewModel.copy()
        }
        event.accepted = true
    }

    Keys.onReturnPressed: event => {
        if (hasSelection) {
            captureViewModel.copy()
        }
        event.accepted = true
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Alt) {
            altPressed = true
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Escape) {
            captureViewModel.cancelCapture()
            resetInteractionState()
            event.accepted = true
            return
        }

        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_C && hasSelection) {
            captureViewModel.copy()
            event.accepted = true
            return
        }

        switch (event.key) {
        case Qt.Key_W:
            if (leftButtonDown) {
                resizeSelection(0, -1, 0, 0)
            } else {
                moveSelection(0, -1)
            }
            event.accepted = true
            return
        case Qt.Key_A:
            if (leftButtonDown) {
                resizeSelection(-1, 0, 0, 0)
            } else {
                moveSelection(-1, 0)
            }
            event.accepted = true
            return
        case Qt.Key_S:
            if (leftButtonDown) {
                resizeSelection(0, 0, 0, 1)
            } else {
                moveSelection(0, 1)
            }
            event.accepted = true
            return
        case Qt.Key_D:
            if (leftButtonDown) {
                resizeSelection(0, 0, 1, 0)
            } else {
                moveSelection(1, 0)
            }
            event.accepted = true
            return
        case Qt.Key_Up:
            if (event.modifiers & Qt.ControlModifier) {
                resizeSelection(0, -1, 0, 0)
            } else if (event.modifiers & Qt.ShiftModifier) {
                resizeSelection(0, 1, 0, 0)
            } else {
                moveSelection(0, -1)
            }
            event.accepted = true
            return
        case Qt.Key_Down:
            if (event.modifiers & Qt.ControlModifier) {
                resizeSelection(0, 0, 0, 1)
            } else if (event.modifiers & Qt.ShiftModifier) {
                resizeSelection(0, 0, 0, -1)
            } else {
                moveSelection(0, 1)
            }
            event.accepted = true
            return
        case Qt.Key_Left:
            if (event.modifiers & Qt.ControlModifier) {
                resizeSelection(-1, 0, 0, 0)
            } else if (event.modifiers & Qt.ShiftModifier) {
                resizeSelection(1, 0, 0, 0)
            } else {
                moveSelection(-1, 0)
            }
            event.accepted = true
            return
        case Qt.Key_Right:
            if (event.modifiers & Qt.ControlModifier) {
                resizeSelection(0, 0, 1, 0)
            } else if (event.modifiers & Qt.ShiftModifier) {
                resizeSelection(0, 0, -1, 0)
            } else {
                moveSelection(1, 0)
            }
            event.accepted = true
            return
        default:
            return
        }
    }

    Keys.onReleased: event => {
        if (event.key === Qt.Key_Alt) {
            altPressed = false
            event.accepted = true
        }
    }
}

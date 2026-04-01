import QtQuick
import QtTest
import "../../qml/app"

TestCase {
    id: testCase
    name: "TitleBarDragRegion"
    when: windowShown

    Item {
        id: container
        width: 280
        height: 120
    }

    Component {
        id: subjectComponent

        TitleBarDragRegion {
            width: 200
            height: 36
        }
    }

    function createSubject(properties) {
        return createTemporaryObject(subjectComponent, container, properties || { x: 20, y: 20 })
    }

    function test_begin_drag_gesture_requests_drag_once() {
        const subject = createSubject()
        let count = 0
        subject.dragRequested.connect(function() { count += 1 })

        verify(subject.beginDragGesture())
        verify(!subject.beginDragGesture())

        compare(count, 1)
    }

    function test_release_resets_drag_gesture() {
        const subject = createSubject()
        let count = 0
        subject.dragRequested.connect(function() { count += 1 })

        verify(subject.beginDragGesture())
        subject.endDragGesture()
        verify(subject.beginDragGesture())

        compare(count, 2)
    }

    function test_cancel_resets_drag_gesture() {
        const subject = createSubject()
        let count = 0
        subject.dragRequested.connect(function() { count += 1 })

        verify(subject.beginDragGesture())
        subject.cancelDragGesture()
        verify(subject.beginDragGesture())

        compare(count, 2)
    }

    function test_active_change_cycles_can_request_drag_repeatedly() {
        const subject = createSubject()
        let count = 0
        subject.dragRequested.connect(function() { count += 1 })

        verify(subject.handleDragActiveChanged(true))
        verify(!subject.handleDragActiveChanged(true))

        subject.handleDragActiveChanged(false)

        verify(subject.handleDragActiveChanged(true))

        compare(count, 2)
    }

    function test_move_after_press_requests_drag_once_per_press_cycle() {
        const subject = createSubject()
        let count = 0
        subject.dragRequested.connect(function() { count += 1 })

        subject.handlePressGesture()
        verify(subject.handleMoveGesture())
        verify(!subject.handleMoveGesture())

        subject.endDragGesture()

        subject.handlePressGesture()
        verify(subject.handleMoveGesture())

        compare(count, 2)
    }

    function test_move_after_press_prefers_direct_system_move_handler() {
        const subject = createSubject()
        let signalCount = 0
        let directCount = 0
        subject.dragRequested.connect(function() { signalCount += 1 })
        subject.systemMoveHandler = function() {
            directCount += 1
            return true
        }

        subject.handlePressGesture()
        verify(subject.handleMoveGesture())

        compare(directCount, 1)
        compare(signalCount, 0)
    }

    function test_press_can_begin_drag_immediately_when_enabled() {
        const subject = createSubject()
        let directCount = 0
        subject.beginDragOnPress = true
        subject.systemMoveHandler = function() {
            directCount += 1
            return true
        }

        verify(subject.handlePressGesture())
        compare(directCount, 1)
    }

    function test_disabled_interaction_ignores_drag_gesture_requests() {
        const subject = createSubject()
        let signalCount = 0
        subject.interactionEnabled = false
        subject.dragRequested.connect(function() { signalCount += 1 })

        verify(!subject.handlePressGesture())
        verify(!subject.handleMoveGesture())
        compare(signalCount, 0)
    }
}

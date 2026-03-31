import QtQuick
import QtTest
import "../../qml/app"

TestCase {
    id: testCase
    name: "TitleBarControls"
    when: windowShown

    Item {
        id: container
        width: 240
        height: 80
    }

    Component {
        id: subjectComponent

        TitleBarControls {
            width: 180
            height: 24
            sidebarToggleIconSource: Qt.resolvedUrl("../../assets/icons/sidebar-toggle.svg")
        }
    }

    function createSubject(properties) {
        return createTemporaryObject(subjectComponent, container, properties || { x: 20, y: 20 })
    }

    function test_sidebar_toggle_emits_signal() {
        const subject = createSubject()
        let count = 0
        subject.sidebarToggleRequested.connect(function() { count += 1 })

        subject.requestSidebarToggle()

        compare(count, 1)
    }

    function test_sidebar_toggle_uses_exported_svg_asset() {
        const subject = createSubject()

        compare(subject.sidebarToggleIconTarget.source.toString(),
                subject.sidebarToggleIconSource.toString())
    }

    function test_can_hide_custom_traffic_lights() {
        const subject = createSubject({ showTrafficLights: false })

        compare(subject.showTrafficLights, false)
    }

    function test_can_shift_sidebar_toggle_left_margin() {
        const subject = createSubject({ sidebarToggleLeftMargin: 110 })

        compare(subject.sidebarToggleLeftMargin, 110)
    }

    function test_back_button_emits_signal_when_enabled() {
        const subject = createSubject({ backEnabled: true })
        let count = 0
        subject.backRequested.connect(function() { count += 1 })

        subject.requestBack()

        compare(count, 1)
    }

    function test_forward_button_emits_signal_when_enabled() {
        const subject = createSubject({ forwardEnabled: true })
        let count = 0
        subject.forwardRequested.connect(function() { count += 1 })

        subject.requestForward()

        compare(count, 1)
    }

    function test_forward_button_does_not_emit_signal_when_disabled() {
        const subject = createSubject({ forwardEnabled: false })
        let count = 0
        subject.forwardRequested.connect(function() { count += 1 })

        subject.requestForward()

        compare(count, 0)
    }
}

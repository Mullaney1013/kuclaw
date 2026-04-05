import QtQuick
import QtTest
import "../../qml/app"

TestCase {
    id: testCase
    name: "SettingsPopover"
    when: windowShown

    Item {
        id: host
        width: 640
        height: 900
    }

    Component {
        id: subjectComponent

        SettingsPopover {
            email: "sinobec1013@gmail.com"
            accountLabel: "Personal account"
        }
    }

    function createSubject() {
        return createTemporaryObject(subjectComponent, host)
    }

    function test_component_loads_and_exposes_copy() {
        const subject = createSubject()

        verify(subject !== null)
        compare(subject.email, "sinobec1013@gmail.com")
        compare(subject.accountLabel, "Personal account")
    }
}

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

    function findByObjectName(node, name) {
        if (!node) {
            return null
        }

        if (node.objectName === name) {
            return node
        }

        const candidates = []

        if (node.contentItem) {
            candidates.push(node.contentItem)
        }

        if (node.background) {
            candidates.push(node.background)
        }

        if (node.children) {
            for (let i = 0; i < node.children.length; ++i) {
                candidates.push(node.children[i])
            }
        }

        for (let i = 0; i < candidates.length; ++i) {
            const match = findByObjectName(candidates[i], name)
            if (match) {
                return match
            }
        }

        return null
    }

    function test_component_loads_and_exposes_copy() {
        const subject = createSubject()

        verify(subject !== null)
        compare(subject.email, "sinobec1013@gmail.com")
        compare(subject.accountLabel, "Personal account")
    }

    function test_figma_labels_and_slots_exist() {
        const subject = createSubject()
        const accountSection = findByObjectName(subject, "settingsPopoverAccountSection")
        const menuSection = findByObjectName(subject, "settingsPopoverMenuSection")
        const logOutRow = findByObjectName(subject, "logOutRow")
        const settingsRow = findByObjectName(subject, "settingsRow")
        const languageRow = findByObjectName(subject, "languageRow")
        const rateLimitsRow = findByObjectName(subject, "rateLimitsRow")
        const emailLabel = findByObjectName(subject, "settingsPopoverEmailText")
        const accountLabel = findByObjectName(subject, "settingsPopoverAccountLabelText")
        const settingsLabel = findByObjectName(subject, "settingsLabel")
        const languageLabel = findByObjectName(subject, "languageLabel")
        const rateLimitsLabel = findByObjectName(subject, "rateLimitsLabel")
        const logOutLabel = findByObjectName(subject, "logOutLabel")
        const languageChevronSlot = findByObjectName(subject, "languageChevronSlot")
        const rateLimitsChevronSlot = findByObjectName(subject, "rateLimitsChevronSlot")

        verify(subject !== null)
        verify(accountSection !== null)
        verify(menuSection !== null)
        verify(logOutRow !== null)
        verify(settingsRow !== null)
        verify(languageRow !== null)
        verify(rateLimitsRow !== null)
        verify(emailLabel !== null)
        verify(accountLabel !== null)
        verify(settingsLabel !== null)
        verify(languageLabel !== null)
        verify(rateLimitsLabel !== null)
        verify(logOutLabel !== null)
        verify(languageChevronSlot !== null)
        verify(rateLimitsChevronSlot !== null)

        compare(subject.width, 420)
        compare(subject.height, 444)
        compare(accountSection.height, 104)
        compare(menuSection.height, 252)
        compare(logOutRow.height, 86)
        compare(settingsRow.y, 8)
        compare(languageRow.y, 80)
        compare(rateLimitsRow.y, 152)

        compare(emailLabel.text, "sinobec1013@gmail.com")
        compare(accountLabel.text, "Personal account")
        compare(settingsLabel.text, "Settings")
        compare(languageLabel.text, "Language")
        compare(rateLimitsLabel.text, "Rate limits remaining")
        compare(logOutLabel.text, "Log out")

        compare(languageChevronSlot.width, 18)
        compare(rateLimitsChevronSlot.width, 18)
        compare(languageChevronSlot.x, 378)
        compare(rateLimitsChevronSlot.x, 378)
    }

    function test_phase_one_rows_are_visual_only() {
        const subject = createSubject()
        const settingsHitArea = findByObjectName(subject, "settingsHitArea")
        const languageHitArea = findByObjectName(subject, "languageHitArea")
        const rateLimitsHitArea = findByObjectName(subject, "rateLimitsHitArea")
        const logOutHitArea = findByObjectName(subject, "logOutHitArea")
        let settingsCount = 0
        let languageCount = 0
        let rateLimitsCount = 0
        let logOutCount = 0

        verify(settingsHitArea !== null)
        verify(languageHitArea !== null)
        verify(rateLimitsHitArea !== null)
        verify(logOutHitArea !== null)

        subject.settingsClicked.connect(function() { settingsCount += 1 })
        subject.languageClicked.connect(function() { languageCount += 1 })
        subject.rateLimitsClicked.connect(function() { rateLimitsCount += 1 })
        subject.logOutClicked.connect(function() { logOutCount += 1 })

        subject.open()
        tryCompare(subject, "opened", true)

        mouseClick(settingsHitArea, 24, 24, Qt.LeftButton)
        mouseClick(languageHitArea, 24, 24, Qt.LeftButton)
        mouseClick(rateLimitsHitArea, 24, 24, Qt.LeftButton)
        mouseClick(logOutHitArea, 24, 24, Qt.LeftButton)

        compare(settingsCount, 0)
        compare(languageCount, 0)
        compare(rateLimitsCount, 0)
        compare(logOutCount, 0)
        verify(subject.opened)
    }
}

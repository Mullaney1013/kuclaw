import QtQuick
import QtQuick.Window
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

    Window {
        id: popupWindow
        width: 640
        height: 900
        visible: true

        Item {
            id: popupHost
            anchors.fill: parent
        }
    }

    Component {
        id: subjectComponent

        SettingsPopover {
            email: "sinobec1013@gmail.com"
            accountLabel: "Personal account"
        }
    }

    Component {
        id: sidebarSettingsPopoverComponent

        ExpandedSidebarSettingsPopover {
            width: 264
            email: "sinobec1013@gmail.com"
            accountLabel: "Personal account"
        }
    }

    Component {
        id: phaseTwoHarnessComponent

        Item {
            id: shellHarness
            width: 640
            height: 900

            property string currentPage: "none"
            property int settingsRequests: 0
            property alias controller: controllerItem
            property alias expandedAnchor: expandedAnchorItem
            property alias railAnchor: railAnchorItem

            Rectangle {
                id: expandedAnchorItem
                x: 24
                y: 820
                width: 264
                height: 52
            }

            Rectangle {
                id: railAnchorItem
                x: 20
                y: 820
                width: 44
                height: 44
            }

            SidebarSettingsPopoverController {
                id: controllerItem
                email: "sinobec1013@gmail.com"
                accountLabel: "Personal account"
                expandedTriggerItem: expandedAnchorItem
                railTriggerItem: railAnchorItem
                onSettingsRequested: {
                    shellHarness.settingsRequests += 1
                    shellHarness.currentPage = "settings"
                }
            }
        }
    }

    function createSubject() {
        return createTemporaryObject(subjectComponent, host)
    }

    function createWindowSubject() {
        return createTemporaryObject(subjectComponent, popupHost)
    }

    function createSidebarSettingsPopover() {
        return createTemporaryObject(sidebarSettingsPopoverComponent, host)
    }

    function createPhaseTwoHarness() {
        return createTemporaryObject(phaseTwoHarnessComponent, host)
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

    function test_settings_row_triggers_action_and_other_rows_remain_inert() {
        const subject = createWindowSubject()
        const settingsRow = findByObjectName(subject, "settingsRow")
        const languageRow = findByObjectName(subject, "languageRow")
        const rateLimitsRow = findByObjectName(subject, "rateLimitsRow")
        const logOutRow = findByObjectName(subject, "logOutRow")
        let currentActionCount = 0

        verify(settingsRow !== null)
        verify(languageRow !== null)
        verify(rateLimitsRow !== null)
        verify(logOutRow !== null)

        subject.settingsClicked.connect(function() { currentActionCount += 1 })

        subject.open()
        tryCompare(subject, "opened", true)

        tryCompare(settingsRow, "visible", true)

        mouseClick(settingsRow, 24, 24, Qt.LeftButton)
        compare(currentActionCount, 1)

        mouseClick(languageRow, 24, 24, Qt.LeftButton)
        compare(currentActionCount, 1)

        mouseClick(rateLimitsRow, 24, 24, Qt.LeftButton)
        compare(currentActionCount, 1)

        mouseClick(logOutRow, 24, 24, Qt.LeftButton)

        compare(currentActionCount, 1)
        verify(subject.opened)
    }

    function test_expanded_sidebar_settings_trigger_toggles_popover() {
        const subject = createSidebarSettingsPopover()

        verify(subject !== null)
        verify(subject.settingsTrigger !== null)
        verify(subject.settingsPopover === null)

        subject.toggleSettingsPopover()
        verify(subject.settingsPopover !== null)
        tryCompare(subject.settingsPopover, "opened", true)
        verify(subject.settingsTrigger.popoverActive)

        subject.toggleSettingsPopover()
        tryCompare(subject.settingsPopover, "opened", false)
        verify(!subject.settingsTrigger.popoverActive)
    }

    function test_settings_popover_opens_above_trigger_and_closes_on_escape() {
        const subject = createSidebarSettingsPopover()

        verify(subject !== null)
        subject.toggleSettingsPopover()

        verify(subject.settingsPopover !== null)
        tryCompare(subject.settingsPopover, "opened", true)
        verify(subject.settingsPopover.y + subject.settingsPopover.height <= 0)

        keyClick(Qt.Key_Escape)
        tryCompare(subject.settingsPopover, "opened", false)
        verify(!subject.settingsTrigger.popoverActive)
    }

    function test_settings_popover_closes_on_outside_click() {
        const subject = createSidebarSettingsPopover()

        verify(subject !== null)
        subject.toggleSettingsPopover()

        verify(subject.settingsPopover !== null)
        tryCompare(subject.settingsPopover, "opened", true)

        verify(subject.outsideClickCatcher !== null)
        mouseClick(subject.outsideClickCatcher, 8, 8, Qt.LeftButton)
        tryCompare(subject.settingsPopover, "opened", false)
        verify(!subject.settingsTrigger.popoverActive)
    }

    function test_settings_popover_reanchors_when_trigger_moves() {
        const subject = createSidebarSettingsPopover()

        verify(subject !== null)
        subject.x = 40
        subject.y = 300
        subject.toggleSettingsPopover()

        verify(subject.settingsPopover !== null)
        tryCompare(subject.settingsPopover, "opened", true)

        const originalX = subject.settingsPopover.x
        const originalY = subject.settingsPopover.y

        subject.x += 24
        subject.y -= 36

        tryCompare(subject.settingsPopover, "x", originalX + 24)
        tryCompare(subject.settingsPopover, "y", originalY - 36)
    }

    function test_controller_opens_from_both_anchor_types() {
        const harness = createPhaseTwoHarness()

        verify(harness !== null)
        verify(harness.controller !== null)

        harness.controller.toggleExpandedPopover()
        tryCompare(harness.controller, "popoverOpen", true)
        compare(harness.controller.activeTriggerKind, "expanded")
        verify(harness.controller.settingsPopover.y + harness.controller.settingsPopover.height <= harness.expandedAnchor.y)

        harness.controller.toggleRailPopover()
        tryCompare(harness.controller, "popoverOpen", true)
        compare(harness.controller.activeTriggerKind, "rail")
        verify(harness.controller.settingsPopover.y + harness.controller.settingsPopover.height <= harness.railAnchor.y)
    }

    function test_controller_reanchors_when_active_trigger_moves() {
        const harness = createPhaseTwoHarness()

        verify(harness !== null)
        verify(harness.controller !== null)

        harness.controller.toggleExpandedPopover()
        tryCompare(harness.controller, "popoverOpen", true)

        const originalX = harness.controller.settingsPopover.x
        const originalY = harness.controller.settingsPopover.y

        harness.expandedAnchor.x += 18
        harness.expandedAnchor.y -= 26

        tryCompare(harness.controller.settingsPopover, "x", originalX + 18)
        tryCompare(harness.controller.settingsPopover, "y", originalY - 26)
    }

    function test_controller_closes_when_active_trigger_hides() {
        const harness = createPhaseTwoHarness()

        verify(harness !== null)
        verify(harness.controller !== null)

        harness.controller.toggleExpandedPopover()
        tryCompare(harness.controller, "popoverOpen", true)

        harness.expandedAnchor.visible = false

        tryCompare(harness.controller, "popoverOpen", false)
    }

    function test_controller_closes_then_requests_settings_navigation() {
        const harness = createPhaseTwoHarness()

        verify(harness !== null)
        verify(harness.controller !== null)

        harness.controller.toggleExpandedPopover()
        tryCompare(harness.controller, "popoverOpen", true)

        const settingsHitArea = findByObjectName(harness.controller.settingsPopover, "settingsHitArea")
        verify(settingsHitArea !== null)

        mouseClick(settingsHitArea, 24, 24, Qt.LeftButton)

        tryCompare(harness.controller, "popoverOpen", false)
        compare(harness.settingsRequests, 1)
        compare(harness.currentPage, "settings")

        harness.controller.closePopover()
        compare(harness.controller.popoverOpen, false)
    }
}

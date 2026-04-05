import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string email: ""
    property string accountLabel: ""
    property var expandedTriggerItem: null
    property var railTriggerItem: null
    property var settingsPopover: null
    property var activeTriggerItem: null
    property string activeTriggerKind: ""
    readonly property bool popoverOpen: settingsPopover ? settingsPopover.opened : false
    readonly property var referenceItem: Overlay.overlay ? Overlay.overlay : root
    readonly property var activeTriggerParent: activeTriggerItem ? activeTriggerItem.parent : null
    readonly property real activeTriggerX: activeTriggerItem ? activeTriggerItem.x : 0
    readonly property real activeTriggerY: activeTriggerItem ? activeTriggerItem.y : 0
    readonly property bool activeTriggerVisible: activeTriggerItem ? activeTriggerItem.visible : false
    signal settingsRequested()

    function updatePopoverPosition() {
        if (!settingsPopover || !activeTriggerItem) {
            return
        }

        const anchor = activeTriggerParent
                     ? activeTriggerParent.mapToItem(referenceItem, activeTriggerX, activeTriggerY)
                     : Qt.point(0, 0)

        settingsPopover.x = Math.round(anchor.x + 20)
        settingsPopover.y = Math.round(anchor.y - settingsPopover.implicitHeight - 12)
    }

    function ensureSettingsPopover() {
        if (settingsPopover) {
            settingsPopover.email = root.email
            settingsPopover.accountLabel = root.accountLabel
            return
        }

        const popupParent = Overlay.overlay ? Overlay.overlay : root
        settingsPopover = settingsPopoverComponent.createObject(popupParent, {
            email: root.email,
            accountLabel: root.accountLabel
        })
    }

    function closePopover() {
        openTimer.stop()

        if (settingsPopover && settingsPopover.opened) {
            settingsPopover.close()
        }
    }

    function destroyPopover() {
        openTimer.stop()
        if (settingsPopover) {
            if (settingsPopover.opened) {
                settingsPopover.close()
            }
            settingsPopover.destroy()
            settingsPopover = null
        }
    }

    function handleSettingsClicked() {
        closePopover()
        settingsRequested()
    }

    function togglePopover(triggerItem, triggerKind) {
        if (!triggerItem) {
            return
        }

        if (popoverOpen && activeTriggerKind === triggerKind) {
            closePopover()
            return
        }

        activeTriggerItem = triggerItem
        activeTriggerKind = triggerKind
        ensureSettingsPopover()

        if (popoverOpen) {
            updatePopoverPosition()
            settingsPopover.forceActiveFocus()
            return
        }

        openTimer.restart()
    }

    function toggleExpandedPopover() {
        togglePopover(expandedTriggerItem, "expanded")
    }

    function toggleRailPopover() {
        togglePopover(railTriggerItem, "rail")
    }

    onEmailChanged: {
        if (settingsPopover) {
            settingsPopover.email = root.email
        }
    }

    onAccountLabelChanged: {
        if (settingsPopover) {
            settingsPopover.accountLabel = root.accountLabel
        }
    }

    onExpandedTriggerItemChanged: {
        if (popoverOpen && activeTriggerKind === "expanded") {
            updatePopoverPosition()
        }
    }

    onRailTriggerItemChanged: {
        if (popoverOpen && activeTriggerKind === "rail") {
            updatePopoverPosition()
        }
    }

    Component.onDestruction: destroyPopover()

    Timer {
        id: openTimer
        interval: 0
        repeat: false
        running: false
        onTriggered: {
            root.updatePopoverPosition()
            settingsPopover.open()
            settingsPopover.forceActiveFocus()
        }
    }

    Component {
        id: settingsPopoverComponent

        SettingsPopover {
            z: 30

            onSettingsClicked: root.handleSettingsClicked()

            onOpenedChanged: {
                if (opened) {
                    root.updatePopoverPosition()
                }
            }
        }
    }

    Timer {
        id: syncTimer
        interval: 16
        repeat: true
        running: root.popoverOpen
        onTriggered: {
            if (!root.activeTriggerItem || !root.activeTriggerVisible) {
                root.closePopover()
                return
            }

            root.updatePopoverPosition()
        }
    }

    onActiveTriggerXChanged: {
        if (popoverOpen) {
            updatePopoverPosition()
        }
    }

    onActiveTriggerYChanged: {
        if (popoverOpen) {
            updatePopoverPosition()
        }
    }

    onActiveTriggerVisibleChanged: {
        if (popoverOpen && !activeTriggerVisible) {
            closePopover()
        }
    }
}

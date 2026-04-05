import QtQuick
import QtQuick.Controls

Popup {
    id: root

    readonly property var metrics: ({
        width: 420,
        radius: 12,
        outerTopPadding: 26,
        rowLeft: 24,
        textLeft: 68,
        chevronSlotX: 378,
        chevronSlotWidth: 18,
        accountHeight: 78,
        menuHeight: 252,
        logoutHeight: 86,
        standardRowHeight: 70,
        tallRowHeight: 92
    })
    readonly property int totalHeight: metrics.outerTopPadding
                                       + metrics.accountHeight
                                       + metrics.menuHeight
                                       + metrics.logoutHeight
                                       + 2

    property string email: ""
    property string accountLabel: ""

    signal settingsClicked()
    signal languageClicked()
    signal rateLimitsClicked()
    signal logOutClicked()

    modal: false
    focus: true
    padding: 0
    width: metrics.width
    height: totalHeight
    implicitWidth: metrics.width
    implicitHeight: totalHeight
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Item {
        implicitWidth: root.metrics.width
        implicitHeight: root.totalHeight

        Rectangle {
            x: -4
            y: 10
            width: parent.width + 8
            height: parent.height + 10
            radius: root.metrics.radius + 4
            color: "#0E0F1722"
        }

        Rectangle {
            x: -1
            y: 3
            width: parent.width + 2
            height: parent.height + 4
            radius: root.metrics.radius + 1
            color: "#120F1720"
        }

        Rectangle {
            anchors.fill: parent
            radius: root.metrics.radius
            color: "#FFFFFF"
            border.width: 1
            border.color: "#E8ECF2"
        }
    }

    contentItem: Item {
        width: root.width
        height: root.totalHeight

        Item {
            id: accountSection
            objectName: "settingsPopoverAccountSection"
            width: parent.width
            height: root.metrics.outerTopPadding + root.metrics.accountHeight

            Item {
                x: root.metrics.rowLeft
                y: root.metrics.outerTopPadding
                width: root.width - root.metrics.rowLeft * 2
                height: root.metrics.accountHeight

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        id: emailText
                        objectName: "settingsPopoverEmailText"
                        text: root.email
                        color: "#324766"
                        font.pixelSize: 24
                        font.weight: Font.Medium
                    }

                    Text {
                        id: accountLabelText
                        objectName: "settingsPopoverAccountLabelText"
                        text: root.accountLabel
                        color: "#8A97AA"
                        font.pixelSize: 16
                    }
                }
            }
        }

        Rectangle {
            y: accountSection.height
            width: parent.width
            height: 1
            color: "#E8ECF2"
        }

        Item {
            id: menuSection
            objectName: "settingsPopoverMenuSection"
            y: accountSection.height + 1
            width: parent.width
            height: root.metrics.menuHeight

            SettingsPopoverRow {
                id: settingsRow
                y: 8
                width: parent.width
                semanticId: "settings"
                clickAction: function() { root.settingsClicked() }
                rowHeight: root.metrics.standardRowHeight
                iconSource: Qt.resolvedUrl("../../assets/icons/settings.svg")
                label: "Settings"
            }

            SettingsPopoverRow {
                id: languageRow
                y: 80
                width: parent.width
                semanticId: "language"
                rowHeight: root.metrics.standardRowHeight
                iconSource: Qt.resolvedUrl("../../assets/icons/language.svg")
                label: "Language"
                showChevron: true
            }

            SettingsPopoverRow {
                id: rateLimitsRow
                y: 152
                width: parent.width
                semanticId: "rateLimits"
                rowHeight: root.metrics.tallRowHeight
                iconSource: Qt.resolvedUrl("../../assets/icons/rate-limits-remaining.svg")
                label: "Rate limits remaining"
                showChevron: true
            }
        }

        Rectangle {
            y: accountSection.height + root.metrics.menuHeight + 1
            width: parent.width
            height: 1
            color: "#E8ECF2"
        }

        SettingsPopoverRow {
            id: logOutRow
            y: accountSection.height + root.metrics.menuHeight + 2
            width: parent.width
            semanticId: "logOut"
            rowHeight: 64
            topPadding: 10
            bottomPadding: 12
            iconSource: Qt.resolvedUrl("../../assets/icons/log-out.svg")
            label: "Log out"
        }
    }

    component SettingsPopoverRow: Item {
        id: row

        objectName: row.semanticId + "Row"
        property string semanticId: ""
        property string iconSource: ""
        property string label: ""
        property bool showChevron: false
        property var clickAction: null
        property real rowHeight: root.metrics.standardRowHeight
        property real topPadding: 0
        property real bottomPadding: 0

        width: root.width
        height: topPadding + rowHeight + bottomPadding

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: hitArea.containsMouse ? "#F4F6FA" : "transparent"
        }

        Image {
            x: root.metrics.rowLeft
            y: topPadding + Math.round((rowHeight - 28) / 2)
            width: 28
            height: 28
            source: row.iconSource
            fillMode: Image.PreserveAspectFit
            sourceSize.width: 28
            sourceSize.height: 28
        }

        Text {
            id: labelText
            objectName: row.semanticId + "Label"
            x: root.metrics.textLeft
            y: topPadding
            width: row.showChevron ? 294 : 328
            height: rowHeight
            text: row.label
            color: "#344A68"
            font.pixelSize: row.showChevron ? 18 : 20
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignVCenter
        }

        Item {
            id: chevronSlot
            objectName: row.semanticId + "ChevronSlot"
            visible: row.showChevron
            x: root.metrics.chevronSlotX
            y: topPadding + Math.round((rowHeight - 24) / 2)
            width: root.metrics.chevronSlotWidth
            height: 24

            Text {
                anchors.centerIn: parent
                text: "›"
                color: "#7B889A"
                font.pixelSize: 20
            }
        }

        MouseArea {
            id: hitArea
            objectName: row.semanticId + "HitArea"
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton
            onClicked: function(mouse) {
                mouse.accepted = true
                if (row.clickAction) {
                    row.clickAction(mouse)
                }
            }
        }
    }
}

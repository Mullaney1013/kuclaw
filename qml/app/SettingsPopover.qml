import QtQuick
import QtQuick.Controls

Popup {
    id: root

    property string email: ""
    property string accountLabel: ""

    signal settingsClicked()
    signal languageClicked()
    signal rateLimitsClicked()
    signal logOutClicked()

    modal: false
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        radius: 12
        color: "#FFFFFF"
    }
}

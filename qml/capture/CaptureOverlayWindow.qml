import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Kuclaw

Window {
    id: overlayWindow

    property bool toolbarHostWindow: false
    property rect screenGeometry: Qt.rect(
                                      captureViewModel.desktopGeometry.x,
                                      captureViewModel.desktopGeometry.y,
                                      Math.max(1, captureViewModel.desktopGeometry.width),
                                      Math.max(1, captureViewModel.desktopGeometry.height)
                                  )
    property rect virtualGeometry: captureViewModel.desktopGeometry

    x: screenGeometry.x
    y: screenGeometry.y
    width: Math.max(1, screenGeometry.width)
    height: Math.max(1, screenGeometry.height)
    visible: captureViewModel.overlayVisible
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    modality: Qt.NonModal
    title: "Kuclaw Capture Overlay"

    onVisibleChanged: {
        if (visible) {
            requestActivate()
            captureOverlay.forceActiveFocus()
        }
    }

    CaptureOverlay {
        id: captureOverlay
        anchors.fill: parent
        focus: true
        toolbarHostWindow: overlayWindow.toolbarHostWindow
        windowOriginX: screenGeometry.x - virtualGeometry.x
        windowOriginY: screenGeometry.y - virtualGeometry.y
    }
}

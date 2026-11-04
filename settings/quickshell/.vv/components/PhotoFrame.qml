import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: photoWindow
    visible: root.photoEnabled && !root.wallVisible
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "photo-widget"
    WlrLayershell.exclusiveZone: -1
    color: "transparent"

    readonly property bool hasPhoto: root.photoPath !== ""
    readonly property real frameSize: Math.round(Math.min(photoWindow.width, photoWindow.height) * 0.20 * root.photoScale)

    readonly property int margin: 24

    Item {
        id: photoGroup
        // photoX/photoY ayarlandiysa (Settings > Layout) onu kullan; yoksa sag alt.
        x: root.photoX >= 0 ? root.photoX * photoWindow.width
                            : photoWindow.width - width - photoWindow.margin - (root.barRight ? root.barThickness : 0)
        y: root.photoY >= 0 ? root.photoY * photoWindow.height
                            : photoWindow.height - height - photoWindow.margin - (root.barPosition === "bottom" ? root.barThickness : 0)
        width: photoWindow.frameSize + 28
        height: photoWindow.frameSize + 34

        Rectangle {
            id: shadowLayer
            anchors.fill: parent
            anchors.margins: -3
            radius: paperFrame.radius + 3
            color: Qt.rgba(0, 0, 0, 0.16)
        }

        Rectangle {
            id: paperFrame
            anchors.fill: parent
            radius: root.photoShape === "circle" ? width / 2 : 16
            color: zyuTheme.widget_bg
            border.width: 1
            border.color: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.28)
        }

        Image {
            id: photoImg
            anchors.centerIn: paperFrame
            width: photoWindow.frameSize
            height: photoWindow.frameSize
            source: photoWindow.hasPhoto ? "file://" + root.photoPath : ""
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            cache: false
            visible: false
        }

        Rectangle {
            id: squareMask
            anchors.centerIn: paperFrame
            width: photoWindow.frameSize
            height: photoWindow.frameSize
            radius: 10
            visible: false
        }
        Rectangle {
            id: circleMask
            anchors.centerIn: paperFrame
            width: photoWindow.frameSize
            height: photoWindow.frameSize
            radius: width / 2
            visible: false
        }

        OpacityMask {
            anchors.centerIn: paperFrame
            width: photoWindow.frameSize
            height: photoWindow.frameSize
            source: photoImg
            maskSource: root.photoShape === "circle" ? circleMask : squareMask
            visible: photoWindow.hasPhoto && photoImg.status === Image.Ready
        }
    }
}

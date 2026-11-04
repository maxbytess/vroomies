import QtQuick
import QtQuick.Layouts

Item {
    id: card

    required property var th
    property string title: ""
    property int icon: 0
    property string figure: ""
    property bool live: false
    property bool accent: false
    property int tintIndex: 0
    property real bodyPad: 0
    property string corner: ""

    default property alias content: body.data
    readonly property bool hovered: hover.hovered
    readonly property real headerHeight: (title.length > 0 || icon > 0) ? 40 : 0
    readonly property real radiusOut: corner === "hero" ? 26 : (corner !== "" ? 20 : 16)

    HoverHandler { id: hover }

    Rectangle {
        id: glass
        anchors.fill: parent
        radius: card.radiusOut
        color: card.hovered
            ? Qt.rgba(card.th.surface.r, card.th.surface.g, card.th.surface.b, 0.92)
            : Qt.rgba(card.th.surface.r, card.th.surface.g, card.th.surface.b, 0.72)
        border.width: 1
        border.color: card.accent
            ? Qt.rgba(card.th.accent.r, card.th.accent.g, card.th.accent.b, 0.65)
            : (card.hovered
                ? Qt.rgba(card.th.accent.r, card.th.accent.g, card.th.accent.b, 0.42)
                : Qt.rgba(card.th.fg.r, card.th.fg.g, card.th.fg.b, 0.10))
        Behavior on color        { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }

        Rectangle {
            x: glass.radius; y: 1
            width: parent.width - glass.radius * 2; height: 1
            color: Qt.rgba(card.th.fg.r, card.th.fg.g, card.th.fg.b, 0.08)
        }

        Rectangle {
            visible: card.corner === "hero"
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.leftMargin: glass.radius; anchors.rightMargin: glass.radius
            height: 2; radius: 1
            color: Qt.rgba(card.th.accent.r, card.th.accent.g, card.th.accent.b, 0.55)
        }
    }

    RowLayout {
        id: header
        visible: card.headerHeight > 0
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        anchors.topMargin: 12
        spacing: 8

        Text {
            visible: card.icon > 0
            text: card.icon > 0 ? String.fromCodePoint(card.icon) : ""
            color: (card.live || card.accent) ? card.th.accent : card.th.muted
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        Text {
            text: card.title.toUpperCase()
            color: card.th.muted
            font.family: card.th.fontFam
            font.pixelSize: 10; font.bold: true
            font.letterSpacing: 1.2
        }
        Rectangle {
            visible: card.live
            Layout.preferredWidth: 6; Layout.preferredHeight: 6; radius: 3
            color: card.th.accent
            SequentialAnimation on opacity {
                running: card.live && card.visible
                loops: Animation.Infinite
                alwaysRunToEnd: true
                NumberAnimation { to: 0.25; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1;    duration: 900; easing.type: Easing.InOutSine }
            }
        }
        Item { Layout.fillWidth: true }
        Text {
            visible: card.figure !== ""
            text: card.figure
            color: card.th.fg
            font.family: card.th.fontFam; font.pixelSize: 11
        }
    }

    Item {
        id: body
        anchors {
            left: parent.left; right: parent.right; bottom: parent.bottom
            top: card.headerHeight > 0 ? header.bottom : parent.top
            leftMargin: card.bodyPad; rightMargin: card.bodyPad; bottomMargin: card.bodyPad
        }
        anchors.topMargin: card.headerHeight > 0 ? 2 : 0
    }
}

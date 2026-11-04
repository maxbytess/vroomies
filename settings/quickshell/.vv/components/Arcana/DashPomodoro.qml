import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property var th
    property int focusMinutes: 25
    property int breakMinutes: 5
    property bool isBreak: false
    property bool running: false
    property int remaining: focusMinutes * 60
    readonly property string nf: "JetBrainsMono Nerd Font"

    function fmt(s) {
        var m = Math.floor(s / 60), r = s % 60
        return (m < 10 ? "0" : "") + m + ":" + (r < 10 ? "0" : "") + r
    }
    function reset() { running = false; remaining = (isBreak ? breakMinutes : focusMinutes) * 60 }
    function skip()  { isBreak = !isBreak; reset() }

    Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: {
            if (root.remaining > 0) root.remaining -= 1
            else { root.isBreak = !root.isBreak; root.remaining = (root.isBreak ? root.breakMinutes : root.focusMinutes) * 60 }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Text {
            text: root.fmt(root.remaining)
            color: root.running ? root.th.accent : root.th.fg
            font.family: root.th.fontFam
            font.pixelSize: 24; font.bold: true
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        Text {
            text: root.isBreak ? "break" : "focus"
            color: root.th.muted
            font.family: root.th.fontFam; font.pixelSize: 11
        }
        Item { Layout.fillWidth: true }

        Repeater {
            model: [
                { cp: 0xF0709, act: "reset" },
                { cp: 0,       act: "toggle" },
                { cp: 0xF04AD, act: "skip" }
            ]
            Rectangle {
                required property var modelData
                Layout.preferredWidth: 30; Layout.preferredHeight: 30; radius: 15
                color: bma.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.04)
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    anchors.centerIn: parent
                    text: modelData.act === "toggle"
                        ? String.fromCodePoint(root.running ? 0xF03E4 : 0xF040A)
                        : String.fromCodePoint(modelData.cp)
                    color: modelData.act === "toggle" ? root.th.accent : root.th.fg
                    font.family: root.nf; font.pixelSize: 14
                }
                MouseArea {
                    id: bma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.act === "reset") root.reset()
                        else if (modelData.act === "skip") root.skip()
                        else root.running = !root.running
                    }
                }
            }
        }
    }
}

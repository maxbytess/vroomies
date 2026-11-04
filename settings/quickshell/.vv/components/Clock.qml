import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: clockWindow
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    visible: !root.wallVisible
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "clock-widget"
    WlrLayershell.exclusiveZone: -1
    color: "transparent"

    SystemClock { id: clock; precision: SystemClock.Seconds }

    readonly property bool use24: false

    function hourOf(d) {
        if (clockWindow.use24) return String(d.getHours()).padStart(2, "0")
        var x = d.getHours() % 12
        return String(x === 0 ? 12 : x)
    }
    function twoOf(n) { return String(n).padStart(2, "0") }

    readonly property int margin: 24

    readonly property real cardW: Math.round(clockWindow.width * 0.15 * root.clockScale)
    readonly property real cardH: Math.round(cardW * 0.46)

    Item {
        id: clockGroup
        x: root.clockX >= 0 ? root.clockX * clockWindow.width
                            : clockWindow.margin + (root.barLeft ? root.barThickness : 0)
        y: root.clockY >= 0 ? root.clockY * clockWindow.height
                            : clockWindow.margin + (root.barPosition === "top"  ? root.barThickness : 0)
        width: clockWindow.cardW
        height: clockWindow.cardH

        Rectangle {
            anchors.fill: parent
            radius: zyuTheme.rounding + 6
            color: zyuTheme.widget_bg
            border.width: 1
            border.color: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.25)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: clockGroup.width * 0.10
            anchors.rightMargin: clockGroup.width * 0.08
            anchors.topMargin: clockGroup.height * 0.14
            anchors.bottomMargin: clockGroup.height * 0.12
            spacing: clockGroup.height * 0.05

            RowLayout {
                Layout.fillWidth: true
                spacing: clockGroup.width * 0.03

                Text {
                    id: bigTime
                    text: clockWindow.hourOf(clock.date) + ":" + clockWindow.twoOf(clock.date.getMinutes())
                    color: zyuTheme.bar_fg
                    font.family: "Monocraft Nerd Font"
                    font.pixelSize: clockGroup.height * 0.42
                    font.bold: true
                    font.letterSpacing: -1.5
                }

                ColumnLayout {
                    spacing: 0
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: clockGroup.height * 0.06

                    Text {
                        text: clock.date.getHours() < 12 ? "AM" : "PM"
                        visible: !clockWindow.use24
                        color: zyuTheme.accent
                        font.family: "Monocraft Nerd Font"
                        font.pixelSize: clockGroup.height * 0.12
                        font.bold: true
                    }
                    Text {
                        text: clockWindow.twoOf(clock.date.getSeconds())
                        visible: clockWindow.use24
                        color: zyuTheme.accent
                        font.family: "Monocraft Nerd Font"
                        font.pixelSize: clockGroup.height * 0.12
                        font.bold: true
                    }
                }

                Item { Layout.fillWidth: true }
            }

            Text {
                Layout.fillWidth: true
                text: clock.date.toLocaleDateString(Qt.locale(), "dddd, d MMMM")
                color: Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.68)
                font.family: "Monocraft Nerd Font"
                font.pixelSize: clockGroup.height * 0.13
                elide: Text.ElideRight
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import "."

Item {
    id: root
    required property var th
    readonly property bool tabActive: th.showDashboard && th.currentTab === "home"

    readonly property real gap: 12
    readonly property real cellW: (width  - gap * 11) / 12
    readonly property real cellH: (height - gap * 5)  / 6
    function gx(c) { return c * (cellW + gap) }
    function gy(r) { return r * (cellH + gap) }
    function gw(n) { return n * cellW + (n - 1) * gap }
    function gh(n) { return n * cellH + (n - 1) * gap }

    function gib(kib) { return (kib / 1048576).toFixed(1) }
    function rate(b) {
        var u = ["B/s","KB/s","MB/s","GB/s"], i = 0, v = b
        while (v >= 1024 && i < u.length - 1) { v /= 1024; i++ }
        return (v < 10 ? v.toFixed(1) : Math.round(v)) + " " + u[i]
    }

    property var displayDate: new Date()
    property var calDays: []
    function daysIn(y, m) { return new Date(y, m + 1, 0).getDate() }
    function buildDays() {
        var out = [], now = th.now
        var y = displayDate.getFullYear(), m = displayDate.getMonth()
        var offset = (new Date(y, m, 1).getDay() + 6) % 7
        var dim = daysIn(y, m), dipm = daysIn(y, m - 1)
        for (var i = offset - 1; i >= 0; i--) out.push({ day: dipm - i, cur: false, today: false })
        for (var d = 1; d <= dim; d++)
            out.push({ day: d, cur: true, today: d === now.getDate() && m === now.getMonth() && y === now.getFullYear() })
        var rem = 42 - out.length
        for (var n = 1; n <= rem; n++) out.push({ day: n, cur: false, today: false })
        calDays = out
    }
    function shift(dm, dy) {
        displayDate = new Date(displayDate.getFullYear() + dy, displayDate.getMonth() + dm, 1)
        buildDays()
    }
    Component.onCompleted: buildDays()
    Connections {
        target: root.th
        function onCalNav(dm, dy) { if (root.tabActive) root.shift(dm, dy) }
    }

    DashCard {
        th: root.th
        x: root.gx(0); y: root.gy(0); width: root.gw(3); height: root.gh(2)
        title: root.th.now.toLocaleDateString(Qt.locale(), "dddd")
        icon: 0xF0150; accent: true; bodyPad: 16; corner: "TL"
        ColumnLayout {
            anchors.fill: parent; spacing: 0
            Item { Layout.fillHeight: true }
            Text {
                text: Qt.formatTime(root.th.now, "HH:mm")
                color: root.th.fg; font.family: root.th.fontFam
                font.pixelSize: Math.max(28, Math.min(parent.height * 0.58, parent.width * 0.30))
                font.bold: true; font.letterSpacing: -2
            }
            RowLayout {
                spacing: 8
                Rectangle { Layout.preferredWidth: 24; Layout.preferredHeight: 3; radius: 1.5; color: root.th.accent }
                Text {
                    text: root.th.now.toLocaleDateString(Qt.locale(), "MMM d, yyyy")
                    color: root.th.muted; font.family: root.th.fontFam; font.pixelSize: 11
                }
            }
            Item { Layout.fillHeight: true }
        }
    }

    DashCard {
        th: root.th
        x: root.gx(3); y: root.gy(0); width: root.gw(6); height: root.gh(2)
        title: "Now playing"; icon: 0xF075A; bodyPad: 18; accent: true; corner: "hero"
        CynaCard { anchors.fill: parent; th: root.th; active: root.tabActive }
    }

    DashCard {
        th: root.th
        x: root.gx(9); y: root.gy(0); width: root.gw(3); height: root.gh(2)
        title: "Focus"; icon: 0xF13AB; bodyPad: 16; corner: "TR"
        DashPomodoro { anchors.fill: parent; th: root.th }
    }

    DashCard {
        th: root.th
        x: root.gx(0); y: root.gy(2); width: root.gw(2); height: root.gh(1)
        title: "CPU"; icon: 0xF061A; bodyPad: 12
        figure: root.th.tempVal > 0 ? root.th.tempVal + "°" : ""
        live: root.th.cpuPerc > 0.05
        Text {
            id: cpuFig
            text: Math.round(root.th.cpuPerc * 100) + "%"
            color: root.th.fg; font.family: root.th.fontFam
            font.pixelSize: Math.max(20, parent.height * 0.42); font.bold: true
        }
        Spline {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: Math.max(16, parent.height - cpuFig.height - 4)
            values: root.th.cpuTrail; peak: 1; color: root.th.accent
        }
    }

    DashCard {
        th: root.th
        x: root.gx(2); y: root.gy(2); width: root.gw(1); height: root.gh(1)
        title: "RAM"; icon: 0xF035B; bodyPad: 10
        figure: root.gib(root.th.memUsedKib)
        Ring {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) * 0.86; height: width
            lineWidth: 7; value: root.th.ramVal / 100; color: root.th.col3
            Text {
                anchors.centerIn: parent; text: root.th.ramVal + "%"
                color: root.th.fg; font.family: root.th.fontFam
                font.pixelSize: Math.max(12, parent.width * 0.24); font.bold: true
            }
        }
    }

    DashCard {
        th: root.th
        x: root.gx(3); y: root.gy(2); width: root.gw(3); height: root.gh(1)
        title: "Network"; icon: 0xF06F3; bodyPad: 12
        live: root.th.netDown > 1024 || root.th.netUp > 1024
        ColumnLayout {
            anchors.fill: parent; spacing: 6
            Repeater {
                model: [
                    { arrow: "↓", val: root.th.netDown, trail: root.th.downTrail, color: root.th.col2 },
                    { arrow: "↑", val: root.th.netUp,   trail: root.th.upTrail,   color: root.th.col1 }
                ]
                Item {
                    required property var modelData
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Spline { anchors.fill: parent; values: modelData.trail; color: modelData.color; lineWidth: 1.5 }
                    Row {
                        spacing: 8
                        Text { text: modelData.arrow; color: modelData.color; font.pixelSize: 14; font.bold: true; font.family: root.th.fontFam }
                        Text { text: root.rate(modelData.val); color: root.th.fg; font.pixelSize: 14; font.family: root.th.fontFam }
                    }
                }
            }
        }
    }

    DashCard {
        th: root.th
        x: root.gx(6); y: root.gy(2); width: root.gw(3); height: root.gh(2)
        title: root.displayDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
        icon: 0xF00ED; bodyPad: 14; corner: "TR"
        Row {
            anchors { right: parent.right; top: parent.top; topMargin: -34 }
            spacing: 4
            Repeater {
                model: [{ t: "‹", dm: -1 }, { t: "›", dm: 1 }]
                Rectangle {
                    required property var modelData
                    width: 24; height: 24; radius: 12
                    color: nav.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                    Text { anchors.centerIn: parent; text: modelData.t; color: root.th.accent; font.pixelSize: 16; font.family: root.th.fontFam }
                    MouseArea { id: nav; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.shift(modelData.dm, 0) }
                }
            }
        }
        ColumnLayout {
            anchors.fill: parent; spacing: 2
            RowLayout {
                Layout.fillWidth: true
                Repeater {
                    model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                    Text {
                        required property string modelData
                        Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                        text: modelData; color: root.th.muted
                        font.family: root.th.fontFam; font.pixelSize: 9
                    }
                }
            }
            GridLayout {
                columns: 7; Layout.fillWidth: true; Layout.fillHeight: true
                rowSpacing: 1; columnSpacing: 0
                Repeater {
                    model: root.calDays
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; Layout.fillHeight: true
                        radius: 6
                        color: modelData.today ? root.th.accent : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: modelData.day
                            color: modelData.today ? root.th.bg : root.th.fg
                            font.family: root.th.fontFam; font.pixelSize: 10
                            font.bold: modelData.today
                            opacity: modelData.cur ? 1.0 : 0.3
                        }
                    }
                }
            }
        }
    }

    DashCard {
        th: root.th
        x: root.gx(9); y: root.gy(2); width: root.gw(3); height: root.gh(1)
        title: "Battery"; icon: root.th.batIconCp; bodyPad: 12
        figure: root.th.batVal + "%"
        RowLayout {
            anchors.fill: parent; spacing: 10
            Text { text: root.th.batVal + "%"; color: root.th.fg
                   font.family: root.th.fontFam; font.pixelSize: 20; font.bold: true }
            Text { text: root.th.batStatusText; color: root.th.muted
                   font.family: root.th.fontFam; font.pixelSize: 10; Layout.fillWidth: true }
        }
    }

    DashCard {
        th: root.th
        x: root.gx(9); y: root.gy(3); width: root.gw(1); height: root.gh(1)
        title: "Disk"; icon: 0xF02CA; bodyPad: 10
        figure: root.th.diskVal + "%"
        Ring {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) * 0.86; height: width
            lineWidth: 7; value: root.th.diskVal / 100; color: root.th.col2
            Text { anchors.centerIn: parent; text: root.th.diskVal + "%"
                   color: root.th.fg; font.family: root.th.fontFam
                   font.pixelSize: Math.max(12, parent.width * 0.24); font.bold: true }
        }
    }

    DashCard {
        th: root.th
        x: root.gx(10); y: root.gy(3); width: root.gw(2); height: root.gh(1)
        title: "Temperature"; icon: 0xF050F; bodyPad: 12
        figure: root.th.tempVal > 0 ? root.th.tempVal + "°C" : "N/A"
        RowLayout {
            anchors.fill: parent; spacing: 10
            Text {
                text: root.th.tempVal > 0 ? root.th.tempVal + "°" : "—"
                color: root.th.tempVal > 70 ? root.th.col1 : root.th.fg
                font.family: root.th.fontFam; font.pixelSize: 24; font.bold: true
            }
            ColumnLayout { spacing: 2
                Text { text: "sensor"; color: root.th.muted; font.family: root.th.fontFam; font.pixelSize: 10 }
                Text { text: root.th.tempVal > 70 ? "warm" : "ok"
                       color: root.th.tempVal > 70 ? root.th.col1 : root.th.col2
                       font.family: root.th.fontFam; font.pixelSize: 10 }
            }
        }
    }

    DashCard {
        th: root.th
        x: root.gx(0); y: root.gy(4); width: root.gw(6); height: root.gh(2)
        title: "Weather"; icon: 0xF0599; bodyPad: 16; corner: "BL"
        DashWeather { anchors.fill: parent; th: root.th; active: root.tabActive }
    }

    DashCard {
        th: root.th
        x: root.gx(6); y: root.gy(4); width: root.gw(3); height: root.gh(2)
        title: "Connect"; icon: 0xF0928; bodyPad: 12
        ColumnLayout {
            anchors.fill: parent; spacing: 6
            Repeater {
                model: [
                    { key: "wifi", label: "Wi-Fi", cp: 0xF0928, on: root.th.wifiOn,
                      status: root.th.wifiOn ? (root.th.wifiSsid !== "" ? root.th.wifiSsid : "On") : "Off" },
                    { key: "bt", label: "Bluetooth", cp: 0xF00AF, on: root.th.btOn,
                      status: root.th.btOn ? (root.th.btDevice !== "" ? root.th.btDevice : "On") : "Off" },
                    { key: "ai", label: "AI", cp: 0xF09D1, on: true, status: "Open assistant" }
                ]
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true; Layout.fillHeight: true
                    radius: 10
                    color: cma.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12; anchors.rightMargin: 12
                        spacing: 10
                        Text { text: String.fromCodePoint(modelData.cp)
                               color: modelData.on ? root.th.accent : root.th.muted
                               font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                        Text { text: modelData.label; color: root.th.fg
                               font.family: root.th.fontFam; font.pixelSize: 12; font.bold: true }
                        Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignRight
                               text: modelData.status; color: root.th.muted
                               font.family: root.th.fontFam; font.pixelSize: 11; elide: Text.ElideRight }
                        Text { text: "›"; color: root.th.muted; font.pixelSize: 16; font.family: root.th.fontFam }
                    }
                    MouseArea {
                        id: cma; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.th.openTab(modelData.key)
                    }
                }
            }
        }
    }

    DashCard {
        th: root.th
        x: root.gx(9); y: root.gy(4); width: root.gw(3); height: root.gh(1)
        title: "Controls"; icon: 0xF0493; bodyPad: 10; corner: "BR"
        RowLayout {
            anchors.fill: parent; spacing: 6
            Repeater {
                model: [
                    { key: "wifi", label: "Wi-Fi", cp: 0xF0928, on: root.th.wifiOn },
                    { key: "bt",   label: "BT",    cp: 0xF00AF, on: root.th.btOn },
                    { key: "dnd",  label: "DND",   cp: 0xF009B, on: root.th.doNotDisturb }
                ]
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true; Layout.fillHeight: true
                    radius: 9
                    color: modelData.on
                        ? Qt.rgba(root.th.accent.r, root.th.accent.g, root.th.accent.b, 0.20)
                        : (tma.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04))
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Row {
                        anchors.centerIn: parent; spacing: 8
                        Text { text: String.fromCodePoint(modelData.cp)
                               color: modelData.on ? root.th.accent : root.th.muted
                               font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15 }
                        Text { anchors.verticalCenter: parent.verticalCenter
                               text: modelData.label
                               color: modelData.on ? root.th.fg : root.th.muted
                               font.family: root.th.fontFam; font.pixelSize: 11 }
                    }
                    MouseArea {
                        id: tma; anchors.fill: parent; hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) { if (modelData.key !== "dnd") root.th.openTab(modelData.key) }
                            else if (modelData.key === "wifi") root.th.toggleWifi()
                            else if (modelData.key === "bt")   root.th.toggleBt()
                            else root.th.doNotDisturb = !root.th.doNotDisturb
                        }
                    }
                }
            }
        }
    }

    DashCard {
        th: root.th
        x: root.gx(9); y: root.gy(5); width: root.gw(3); height: root.gh(1)
        title: "Uptime"; icon: 0xF0175; bodyPad: 12; corner: "BR"
        figure: root.th.uptimeStr
        Text {
            anchors.fill: parent; text: root.th.uptimeStr
            color: root.th.fg; font.family: root.th.fontFam
            font.pixelSize: Math.max(12, parent.height * 0.28); elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
    }
}

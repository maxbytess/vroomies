
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

Scope {
    id: root

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: root.popup !== ""
        onActivated: root.popup = ""
    }

    property color bg0: adapter.bg0
    property color bg1: adapter.bg1
    property color bg2: adapter.bg2
    property color bg3: adapter.bg3
    property color text: adapter.text
    property color blue: adapter.blue
    property color grey1: adapter.grey1

    readonly property color green: "#afbea2"
    readonly property color orange: "#e0b089"
    readonly property color peach: "#e4c9af"
    readonly property color pink: "#d7beda"
    readonly property color soft: "#bbc5d7"
    readonly property color red: "#f09a9a"

    readonly property string ff: "DaddyTimeMono NF"
    readonly property string musicFF: "DaddyTimeMono NF"
    property string brightnessDevice: "intel_backlight"

    function ico(cp) {
        return String.fromCodePoint(cp)
    }

    FileView {
        path: Qt.resolvedUrl("colors.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property string bg0: "#0f1511"
            property string bg1: "#1b211d"
            property string bg2: "#262b27"
            property string bg3: "#303632"
            property string text: "#dee4de"
            property string blue: "#90d5ae"
            property string grey1: "#8a938c"
        }
    }

    component HSlider: Item {
        id: sliderSelf

        property real value: 0
        property color trackColor: "#22242b"
        property color fillColor: "#a1bdce"
        readonly property bool dragging: sliderArea.pressed

        signal moved(real v)

        implicitWidth: 70
        implicitHeight: 10

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: sliderSelf.trackColor
        }

        Rectangle {
            width: parent.width * Math.max(0, Math.min(100, sliderSelf.value)) / 100
            height: parent.height
            radius: height / 2
            color: sliderSelf.fillColor
        }

        MouseArea {
            id: sliderArea
            anchors.fill: parent
            anchors.topMargin: -6
            anchors.bottomMargin: -6
            cursorShape: Qt.PointingHandCursor

            function setFrom(x) {
                sliderSelf.moved(Math.max(0, Math.min(100, 100 * x / width)))
            }

            onPressed: mouse => setFrom(mouse.x)
            onPositionChanged: mouse => {
                if (pressed)
                    setFrom(mouse.x)
            }
        }
    }

    component Ring: Item {
        id: ringSelf

        property real value: 0
        property color color: "#afbea2"
        property color trackColor: "#38384d"
        property real thickness: 4

        default property alias content: ringHolder.data
        signal clicked()

        implicitWidth: 28
        implicitHeight: 28

        onValueChanged: ringCanvas.requestPaint()
        onColorChanged: ringCanvas.requestPaint()
        onTrackColorChanged: ringCanvas.requestPaint()
        onThicknessChanged: ringCanvas.requestPaint()
        onWidthChanged: ringCanvas.requestPaint()
        onHeightChanged: ringCanvas.requestPaint()

        Canvas {
            id: ringCanvas
            anchors.fill: parent
            antialiasing: true

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()

                const r = (Math.min(width, height) - ringSelf.thickness) / 2
                const cx = width / 2
                const cy = height / 2

                ctx.lineWidth = ringSelf.thickness
                ctx.lineCap = "round"

                ctx.strokeStyle = ringSelf.trackColor
                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, Math.PI * 2)
                ctx.stroke()

                const frac = Math.max(0, Math.min(1, ringSelf.value / 100))

                if (frac > 0) {
                    ctx.strokeStyle = ringSelf.color
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * frac)
                    ctx.stroke()
                }
            }
        }

        Item {
            id: ringHolder
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ringSelf.clicked()
        }
    }

    // Dikey reveal: yükseklik animasyonla açılır, genişlik ASLA değişmez.
    // fromBottom: true  -> içerik aşağıdan yukarıya doğru görünür
    // fromBottom: false -> içerik yukarıdan aşağıya doğru görünür
    component RevealV: Item {
        id: rvSelf
        property bool shown: false
        property bool fromBottom: false
        property int gap: 6
        property int duration: 300
        default property alias content: rvHolder.data

        clip: true
        implicitWidth: rvHolder.childrenRect.width
        implicitHeight: shown ? rvHolder.childrenRect.height + gap : 0

        Behavior on implicitHeight {
            NumberAnimation {
                duration: rvSelf.duration
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: rvHolder
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: rvSelf.fromBottom ? undefined : parent.top
            anchors.topMargin: rvSelf.gap
            anchors.bottom: rvSelf.fromBottom ? parent.bottom : undefined
            anchors.bottomMargin: rvSelf.gap
            width: childrenRect.width
            height: childrenRect.height
        }
    }

    // Dikey yazı: aşağıdan yukarıya okunur, düzen boyutu döndürülmüş boyuta göre hesaplanır.
    component VText: Item {
        id: vtSelf
        property string text: ""
        property color color: "white"
        property string family: ""
        property int pixelSize: 12
        property bool bold: true
        property real maxLength: 160

        implicitWidth: vtLabel.implicitHeight
        implicitHeight: Math.min(vtLabel.implicitWidth, maxLength)

        Text {
            id: vtLabel
            anchors.centerIn: parent
            rotation: -90
            width: vtSelf.implicitHeight
            text: vtSelf.text
            color: vtSelf.color
            font.family: vtSelf.family
            font.pixelSize: vtSelf.pixelSize
            font.bold: vtSelf.bold
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }
    }

    // Dikey kaydırıcı: alttan yukarıya dolar.
    component VSlider: Item {
        id: vsSelf
        property real value: 0
        property color trackColor: "#22242b"
        property color fillColor: "#a1bdce"
        readonly property bool dragging: vsArea.pressed
        signal moved(real v)

        implicitWidth: 8
        implicitHeight: 70

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: vsSelf.trackColor
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.height * Math.max(0, Math.min(100, vsSelf.value)) / 100
            radius: width / 2
            color: vsSelf.fillColor
        }
        MouseArea {
            id: vsArea
            anchors.fill: parent
            anchors.leftMargin: -8
            anchors.rightMargin: -8
            cursorShape: Qt.PointingHandCursor

            function setFrom(y) {
                vsSelf.moved(Math.max(0, Math.min(100, 100 * (1 - y / height))))
            }
            onPressed: mouse => setFrom(mouse.y)
            onPositionChanged: mouse => { if (pressed) setFrom(mouse.y) }
        }
    }

    component Reveal: Item {
        id: revealSelf

        property bool shown: false
        property int duration: 250
        default property alias content: revealHolder.data

        clip: true
        implicitWidth: shown ? revealHolder.childrenRect.width : 0
        implicitHeight: revealHolder.childrenRect.height

        Behavior on implicitWidth {
            NumberAnimation {
                duration: revealSelf.duration
                easing.type: Easing.OutQuart
            }
        }

        Item {
            id: revealHolder
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
        }
    }

    property string popup: ""

    function toggle(name) {
        popup = popup === name ? "" : name
    }

    property var workspaces: []
    property date now: new Date()

    property real cpu: 0
    property real temp: 0
    property real ram: 0
    property real disk: 0

    property int memTotalMb: 0
    property int memUsedMb: 0
    property int diskTotalGb: 0
    property int diskUsedGb: 0

    property int battery: -1
    property string batteryState: ""

    property string ssid: ""
    property real brightness: -1
    property bool brDragging: false

    property real prevTotal: 0
    property real prevIdle: 0

    property bool btOn: false
    property var btDevices: []
    readonly property string btName: !btOn
        ? "Off"
        : (btDevices.length > 0 ? btDevices.join(", ") : "No device")

    property bool hoverLauncher: false
    property bool hoverMusic: false
    property bool hoverWifi: false
    property bool hoverVolume: false
    property bool hoverBrightness: false
    property bool hoverBattery: false
    property bool hoverMemory: false
    property bool hoverClock: false
    property bool hoverBluetooth: false

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio ? sink.audio.volume : 0
    readonly property bool muted: sink?.audio ? sink.audio.muted : false

    function setVolume(v) {
        if (sink?.audio)
            sink.audio.volume = v / 100
    }

    readonly property var player: {
        const ps = Mpris.players.values
        return ps.find(p => p.isPlaying) ?? ps[0] ?? null
    }

    Timer {
        running: root.player !== null && root.player.isPlaying
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    function pad(n) {
        return n < 10 ? "0" + n : "" + n
    }

    readonly property string hour24: pad(now.getHours())
    readonly property string minute: pad(now.getMinutes())

    Process {
        id: wsProc
        command: ["niri", "msg", "-j", "workspaces"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.workspaces = JSON.parse(text).sort((a, b) => a.idx - b.idx)
                } catch (e) {}
            }
        }
    }

    Timer {
        id: niriDebounce
        interval: 60
        onTriggered: wsProc.running = true
    }

    Process {
        running: true
        command: ["niri", "msg", "-j", "event-stream"]

        stdout: SplitParser {
            onRead: line => {
                if (/Window|Workspace/.test(line))
                    niriDebounce.restart()
            }
        }
    }

    Component.onCompleted: wsProc.running = true

    function parseStats(out) {
        const m = {}
        for (const line of out.trim().split("\n")) {
            const i = line.indexOf(" ")
            if (i > 0)
                m[line.slice(0, i)] = line.slice(i + 1).trim()
        }

        if (m.cpu) {
            const c = m.cpu.split(/\s+/).map(Number)
            const total = c.slice(0, 8).reduce((a, b) => a + b, 0)
            const idle = c[3] + (c[4] || 0)
            if (prevTotal > 0 && total > prevTotal)
                cpu = 100 * (1 - (idle - prevIdle) / (total - prevTotal))
            prevTotal = total
            prevIdle = idle
        }

        const t = Number(m.temp)
        if (t > 0)
            temp = Math.round(t / 1000)

        const totalKb = Number(m.memtotal)
        const availKb = Number(m.memavail)
        if (totalKb > 0) {
            ram = 100 * (1 - availKb / totalKb)
            memTotalMb = Math.round(totalKb / 1024)
            memUsedMb = memTotalMb - Math.round(availKb / 1024)
        }

        const dTotKb = Number(m.disktotal)
        const dUseKb = Number(m.diskused)
        if (dTotKb > 0) {
            disk = 100 * (dUseKb / dTotKb)
            diskTotalGb = Math.round(dTotKb / (1024 * 1024))
            diskUsedGb = Math.round(dUseKb / (1024 * 1024))
        }

        battery = m.bat !== undefined ? Number(m.bat) : -1
        batteryState = m.batstate !== undefined ? m.batstate : ""
    }

    Process {
        id: statsProc
        command: [
            "sh",
            "-c",
            [
                "head -n1 /proc/stat | sed 's/^cpu  */cpu /'",
                "t=; for z in /sys/class/thermal/thermal_zone*; do case \"$(cat \"$z/type\" 2>/dev/null)\" in x86_pkg_temp|k10temp|coretemp|cpu*|soc*) t=$(cat \"$z/temp\"); break;; esac; done",
                "[ -z \"$t\" ] && t=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)",
                "echo \"temp ${t:-0}\"",
                "awk '/^MemTotal/ {print \"memtotal\", $2} /^MemAvailable/ {print \"memavail\", $2}' /proc/meminfo",
                "df / | awk 'NR==2 {print \"disktotal\", $2; print \"diskused\", $3}'",
                "if [ -r /sys/class/power_supply/BAT0/capacity ]; then echo \"bat $(cat /sys/class/power_supply/BAT0/capacity)\"; echo \"batstate $(cat /sys/class/power_supply/BAT0/status)\"; fi"
            ].join("\n")
        ]
        stdout: StdioCollector {
            onStreamFinished: root.parseStats(text)
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statsProc.running = true
    }

    Process {
        id: netProc

        command: [
            "sh",
            "-c",
            "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2- | head -n1"
        ]

        stdout: StdioCollector {
            onStreamFinished: root.ssid = text.trim()
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    Process {
        id: btProc
        command: [
            "sh",
            "-c",
            [
                "p=$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2}')",
                "echo \"${p:-no}\"",
                "[ \"$p\" = yes ] && bluetoothctl devices 2>/dev/null | while read -r _ mac name; do bluetoothctl info \"$mac\" 2>/dev/null | grep -q 'Connected: yes' && echo \"$name\"; done",
                "exit 0"
            ].join("\n")
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n").map(s => s.trim()).filter(s => s.length > 0)
                root.btOn = l.length > 0 && l[0] === "yes"
                root.btDevices = l.slice(1)
            }
        }
    }

    Timer {
        interval: 8000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: btProc.running = true
    }

    Timer {
        id: btRefresh
        interval: 1200
        onTriggered: btProc.running = true
    }

    function bluetoothClick(button) {
        if (button === Qt.RightButton) {
            Quickshell.execDetached(["bluetoothctl", "power", btOn ? "off" : "on"])
            btRefresh.restart()
        } else {
            Quickshell.execDetached(["bash", "-c", "~/.config/quickshell/nn/scripts/bluetooth.sh menu"])
        }
    }

    Process {
        id: brProc

        command: [
            "sh",
            "-c",
            "brightnessctl -m -d " + root.brightnessDevice + " 2>/dev/null | cut -d, -f4 | tr -d %"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseFloat(text)
                if (!isNaN(v) && !root.brDragging)
                    root.brightness = v
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: brProc.running = true
    }

    property real brPending: -1
    property bool brDirty: false

    function applyBrightness() {
        brDirty = false
        brSetProc.command = [
            "brightnessctl",
            "-q",
            "-d",
            brightnessDevice,
            "set",
            Math.max(1, Math.round(brPending)) + "%"
        ]
        brSetProc.running = true
    }

    function setBrightness(v) {
        brightness = v
        brPending = v

        if (brSetProc.running)
            brDirty = true
        else
            applyBrightness()
    }

    Process {
        id: brSetProc
        onExited: if (root.brDirty) root.applyBrightness()
    }

    // Vertical bar (left): sabit genişlik, yatayda hiçbir şey genişlemez
    PanelWindow {
        id: bar

        anchors {
            top: true
            bottom: true
            left: true
        }
        margins {
            top: 10
            bottom: 10
            left: 9
        }

        implicitWidth: 44
        color: "transparent"

        Rectangle {
            id: pill
            anchors.fill: parent
            radius: 16
            color: root.bg0
            opacity: 0
            Component.onCompleted: opacity = 1
            Behavior on opacity {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.OutCubic
                }
            }
        }

        // ---------- top: launcher (power menu opens downward) and workspaces ----------
        ColumnLayout {
            id: topCol
            anchors.top: parent.top
            anchors.topMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            MouseArea {
                Layout.preferredWidth: 24
                Layout.preferredHeight: launcherCol.implicitHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hoverLauncher = true
                onExited: root.hoverLauncher = false
                onClicked: root.toggle("dashboard")

                ColumnLayout {
                    id: launcherCol
                    width: 24
                    spacing: 0

                    Item {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        Text {
                            anchors.centerIn: parent
                            text: root.ico(0xE22E)
                            color: root.hoverLauncher ? root.peach : root.blue
                            font.family: root.ff
                            font.pixelSize: 18
                        }
                    }

                    RevealV {
                        Layout.alignment: Qt.AlignHCenter
                        shown: root.hoverLauncher
                        Column {
                            spacing: 10

                            Text {
                                text: root.ico(0xF011)
                                color: root.text
                                font.family: root.ff
                                font.pixelSize: 15
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -3
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                                }
                            }
                            Text {
                                text: root.ico(0xF023)
                                color: root.text
                                font.family: root.ff
                                font.pixelSize: 15
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -3
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["hyprlock"])
                                }
                            }
                            Text {
                                text: root.ico(0xF2F9)
                                color: root.text
                                font.family: root.ff
                                font.pixelSize: 15
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -3
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 1
                Layout.alignment: Qt.AlignHCenter
                color: root.grey1
                opacity: 0.6
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                Repeater {
                    model: root.workspaces
                    delegate: Item {
                        required property var modelData
                        readonly property bool active: modelData.is_active === true
                        readonly property bool hasWindow: modelData.active_window_id !== null

                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 20

                        Text {
                            anchors.centerIn: parent
                            text: root.ico(parent.active ? 0xF4BF : 0xF4C3)
                            color: parent.active ? root.blue : (parent.hasWindow ? root.text : root.grey1)
                            font.family: root.ff
                            font.pixelSize: 15
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached([
                                "niri",
                                "msg",
                                "action",
                                "focus-workspace",
                                String(modelData.idx)
                            ])
                        }
                    }
                }
            }
        }

        // ---------- middle: music (title always visible, controls open upward) ----------
        Item {
            id: musicBox
            visible: root.player !== null && root.player.trackTitle !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            width: 24
            height: musicCol.implicitHeight

            // Kontroller kapalıyken grubun ortası çubuğun ortasında; açılınca sadece yukarı büyür.
            readonly property real baseHeight: musicTitle.implicitHeight + 8 + 24
            y: Math.round(parent.height / 2 + baseHeight / 2 - height)

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root.hoverMusic = true
                onExited: root.hoverMusic = false
            }

            ColumnLayout {
                id: musicCol
                width: 24
                spacing: 0

                RevealV {
                    Layout.alignment: Qt.AlignHCenter
                    fromBottom: true
                    shown: root.hoverMusic
                    Column {
                        spacing: 10

                        Text {
                            text: root.ico(0xF04A)
                            color: root.text
                            font.family: root.ff
                            font.pixelSize: 15
                            font.bold: true
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -3
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.player?.previous()
                            }
                        }
                        Text {
                            text: root.ico(root.player?.isPlaying ? 0xF04C : 0xF04B)
                            color: root.blue
                            font.family: root.ff
                            font.pixelSize: 15
                            font.bold: true
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -3
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.player?.togglePlaying()
                            }
                        }
                        Text {
                            text: root.ico(0xF04E)
                            color: root.text
                            font.family: root.ff
                            font.pixelSize: 15
                            font.bold: true
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -3
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.player?.next()
                            }
                        }
                    }
                }

                VText {
                    id: musicTitle
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 0
                    text: root.player?.trackTitle ?? ""
                    color: root.blue
                    family: root.musicFF
                    pixelSize: 14
                    bold: false
                    maxLength: 180
                }

                Item {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.topMargin: 8

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: root.bg2
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: root.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }
                }
            }
        }

        // ---------- bottom: system indicators (reveals open upward) ----------
        ColumnLayout {
            id: botCol
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            // RAM
            MouseArea {
                Layout.preferredWidth: 24
                Layout.preferredHeight: memCol.implicitHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hoverMemory = true
                onExited: root.hoverMemory = false

                ColumnLayout {
                    id: memCol
                    width: 24
                    spacing: 0

                    RevealV {
                        Layout.alignment: Qt.AlignHCenter
                        fromBottom: true
                        shown: root.hoverMemory
                        Text {
                            text: Math.round(root.ram) + "%"
                            color: root.orange
                            font.family: root.ff
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                    Ring {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        value: root.ram
                        color: root.orange
                        trackColor: root.bg2
                        thickness: 4
                        Text {
                            anchors.centerIn: parent
                            text: root.ico(0xF035B)
                            color: root.orange
                            font.family: root.ff
                            font.pixelSize: 11
                        }
                    }
                }
            }

            // Battery
            MouseArea {
                visible: root.battery >= 0
                Layout.preferredWidth: 24
                Layout.preferredHeight: batCol.implicitHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hoverBattery = true
                onExited: root.hoverBattery = false

                ColumnLayout {
                    id: batCol
                    width: 24
                    spacing: 0

                    RevealV {
                        Layout.alignment: Qt.AlignHCenter
                        fromBottom: true
                        shown: root.hoverBattery
                        Text {
                            text: root.battery + "%"
                            color: root.green
                            font.family: root.ff
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                    Ring {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        value: Math.max(0, root.battery)
                        color: root.battery <= 15 && root.batteryState !== "Charging"
                            ? root.red
                            : root.green
                        trackColor: root.bg2
                        thickness: 4
                        Text {
                            anchors.centerIn: parent
                            text: root.ico(root.batteryState === "Charging" ? 0xF0084 : 0xF0079)
                            color: root.green
                            font.family: root.ff
                            font.pixelSize: 11
                        }
                    }
                }
            }

            // Brightness
            MouseArea {
                visible: root.brightness >= 0
                Layout.preferredWidth: 24
                Layout.preferredHeight: brCol.implicitHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hoverBrightness = true
                onExited: root.hoverBrightness = false

                ColumnLayout {
                    id: brCol
                    width: 24
                    spacing: 0

                    RevealV {
                        Layout.alignment: Qt.AlignHCenter
                        fromBottom: true
                        shown: root.hoverBrightness
                        VSlider {
                            value: root.brightness
                            trackColor: root.bg2
                            fillColor: root.peach
                            onMoved: v => root.setBrightness(v)
                            onDraggingChanged: root.brDragging = dragging
                        }
                    }
                    Item {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        Text {
                            anchors.centerIn: parent
                            text: root.ico(0xF00DF)
                            color: root.peach
                            font.family: root.ff
                            font.pixelSize: 16
                        }
                    }
                }
            }

            // Volume
            MouseArea {
                Layout.preferredWidth: 24
                Layout.preferredHeight: volCol.implicitHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onEntered: root.hoverVolume = true
                onExited: root.hoverVolume = false
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton && root.sink?.audio)
                        root.sink.audio.muted = !root.muted
                }
                onWheel: wheel => {
                    root.setVolume(Math.max(
                        0,
                        Math.min(100, root.volume * 100 + (wheel.angleDelta.y > 0 ? 5 : -5))
                    ))
                }

                ColumnLayout {
                    id: volCol
                    width: 24
                    spacing: 0

                    RevealV {
                        Layout.alignment: Qt.AlignHCenter
                        fromBottom: true
                        shown: root.hoverVolume
                        Column {
                            spacing: 6
                            VSlider {
                                anchors.horizontalCenter: parent.horizontalCenter
                                value: root.volume * 100
                                trackColor: root.bg2
                                fillColor: root.blue
                                onMoved: v => root.setVolume(v)
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Math.round(root.volume * 100)
                                color: root.blue
                                font.family: root.ff
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                    }
                    Item {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        Text {
                            anchors.centerIn: parent
                            text: root.ico(root.muted ? 0xF075F : 0xF057E)
                            color: root.muted ? root.grey1 : root.blue
                            font.family: root.ff
                            font.pixelSize: 16
                        }
                    }
                }
            }

            // Wi-Fi
            MouseArea {
                Layout.preferredWidth: 24
                Layout.preferredHeight: wifiCol.implicitHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hoverWifi = true
                onExited: root.hoverWifi = false
                onClicked: Quickshell.execDetached([
                    "bash",
                    "-c",
                    "~/.config/quickshell/nn/scripts/wifi.sh menu"
                ])

                ColumnLayout {
                    id: wifiCol
                    width: 24
                    spacing: 0

                    RevealV {
                        Layout.alignment: Qt.AlignHCenter
                        fromBottom: true
                        shown: root.hoverWifi
                        VText {
                            text: root.ssid !== "" ? root.ssid : "Not connected"
                            color: root.blue
                            family: root.ff
                            pixelSize: 12
                            maxLength: 120
                        }
                    }
                    Item {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        Text {
                            anchors.centerIn: parent
                            text: root.ico(root.ssid !== "" ? 0xF0928 : 0xF092F)
                            color: root.ssid !== "" ? root.blue : root.grey1
                            font.family: root.ff
                            font.pixelSize: 16
                        }
                    }
                }
            }

            // Bluetooth
            MouseArea {
                Layout.preferredWidth: 24
                Layout.preferredHeight: btCol.implicitHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onEntered: root.hoverBluetooth = true
                onExited: root.hoverBluetooth = false
                onClicked: mouse => root.bluetoothClick(mouse.button)

                ColumnLayout {
                    id: btCol
                    width: 24
                    spacing: 0

                    RevealV {
                        Layout.alignment: Qt.AlignHCenter
                        fromBottom: true
                        shown: root.hoverBluetooth
                        VText {
                            text: root.btName
                            color: root.btDevices.length > 0 ? root.blue : root.grey1
                            family: root.ff
                            pixelSize: 12
                            maxLength: 120
                        }
                    }
                    Item {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        Text {
                            anchors.centerIn: parent
                            text: root.ico(root.btOn ? 0xF00AF : 0xF00B2)
                            color: root.btDevices.length > 0 ? root.blue : (root.btOn ? root.text : root.grey1)
                            font.family: root.ff
                            font.pixelSize: 16
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 1
                Layout.alignment: Qt.AlignHCenter
                color: root.grey1
                opacity: 0.6
            }

            // Clock
            MouseArea {
                Layout.preferredWidth: 24
                Layout.preferredHeight: clockCol.implicitHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hoverClock = true
                onExited: root.hoverClock = false
                onClicked: root.toggle("calendar")

                ColumnLayout {
                    id: clockCol
                    width: 24
                    spacing: 0

                    RevealV {
                        Layout.alignment: Qt.AlignHCenter
                        fromBottom: true
                        shown: root.hoverClock
                        VText {
                            text: root.pad(root.now.getDate()) + "/" + root.pad(root.now.getMonth() + 1)
                            color: root.pink
                            family: root.ff
                            pixelSize: 12
                            maxLength: 60
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.hour24
                        color: root.text
                        font.family: root.ff
                        font.pixelSize: 16
                        font.bold: true
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.minute
                        color: root.text
                        font.family: root.ff
                        font.pixelSize: 16
                        font.bold: true
                    }
                }
            }
        }
    }

    // Calendar popup

    PanelWindow {
        id: calWin

        property date viewDate: new Date()
        readonly property int year: viewDate.getFullYear()
        readonly property int month: viewDate.getMonth()
        readonly property int firstOffset: (new Date(year, month, 1).getDay() + 6) % 7
        readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()

        function shift(d) {
            viewDate = new Date(year, month + d, 1)
        }

        visible: root.popup === "calendar"
        focusable: visible

        onVisibleChanged: {
            if (visible)
                viewDate = new Date()
        }

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        anchors {
            bottom: true
            left: true
        }
        margins {
            bottom: 10
            left: 62
        }

        implicitWidth: 320
        implicitHeight: calCol.implicitHeight + 30

        MouseArea {
            id: calendarEscapeArea
            anchors.fill: parent
            focus: true
            enabled: calWin.visible
            propagateComposedEvents: true

            Keys.onEscapePressed: event => {
                root.popup = ""
                event.accepted = true
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: root.bg0
            opacity: calWin.visible ? 1 : 0
            scale: calWin.visible ? 1 : 0.95

            transform: Translate {
                y: calWin.visible ? 0 : 10
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutBack
                }
            }

            Behavior on transform {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
        }

        ColumnLayout {
            id: calCol
            anchors.fill: parent
            anchors.margins: 15
            spacing: 0

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: root.ico(0xF053)
                    color: root.blue
                    font.family: root.ff
                    font.pixelSize: 15

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calWin.shift(-1)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().monthName(calWin.month) + " " + calWin.year
                    color: root.blue
                    font.family: root.ff
                    font.pixelSize: 17
                    font.bold: true
                }

                Text {
                    text: root.ico(0xF054)
                    color: root.blue
                    font.family: root.ff
                    font.pixelSize: 15

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calWin.shift(1)
                    }
                }
            }

            Item {
                Layout.preferredHeight: 12
            }

            Grid {
                Layout.alignment: Qt.AlignHCenter
                columns: 7
                spacing: 0

                Repeater {
                    model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

                    delegate: Text {
                        required property string modelData
                        width: 38
                        height: 24
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: modelData
                        color: root.grey1
                        font.family: root.ff
                        font.pixelSize: 13
                    }
                }

                Repeater {
                    model: 42

                    delegate: Item {
                        required property int index

                        readonly property int dayNum: index - calWin.firstOffset + 1
                        readonly property bool valid: dayNum > 0 && dayNum <= calWin.daysInMonth
                        readonly property bool isToday:
                            valid &&
                            calWin.year === root.now.getFullYear() &&
                            calWin.month === root.now.getMonth() &&
                            dayNum === root.now.getDate()

                        width: 38
                        height: 28

                        Rectangle {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            radius: 12
                            color: isToday ? root.green : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: valid ? dayNum : ""
                                color: isToday ? root.bg0 : (valid ? root.text : "transparent")
                                font.family: root.ff
                                font.pixelSize: 13
                                font.bold: isToday
                            }
                        }
                    }
                }
            }
        }
    }

    // Dashboard popup

    PanelWindow {
        id: dashWin

        visible: root.popup === "dashboard"
        focusable: visible
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            left: true
        }

        margins {
            top: 10
            left: 62
        }

        implicitWidth: 370
        implicitHeight: dashCol.implicitHeight + 30

        MouseArea {
            id: dashboardEscapeArea
            anchors.fill: parent
            focus: true
            enabled: dashWin.visible
            propagateComposedEvents: true

            Keys.onEscapePressed: event => {
                root.popup = ""
                event.accepted = true
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: root.bg0
            opacity: dashWin.visible ? 1 : 0
            scale: dashWin.visible ? 1 : 0.95

            transform: Translate {
                y: dashWin.visible ? 0 : 10
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutBack
                }
            }

            Behavior on transform {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
        }

        ColumnLayout {
            id: dashCol
            anchors.fill: parent
            anchors.margins: 15
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 24

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 16

                    ColumnLayout {
                        spacing: 4

                        Text {
                            text: "CPU"
                            color: root.blue
                            font.family: root.ff
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Text {
                            text: Math.round(root.cpu) + "%"
                            color: root.text
                            font.family: root.ff
                            font.pixelSize: 11
                        }

                        Rectangle {
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 70
                            radius: 6
                            color: root.bg2

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: parent.height * Math.max(0, Math.min(100, root.cpu)) / 100
                                radius: 6
                                color: root.blue

                                Behavior on height {
                                    NumberAnimation {
                                        duration: 500
                                        easing.type: Easing.OutQuad
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 4

                        Text {
                            text: "TMP"
                            color: root.red
                            font.family: root.ff
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Text {
                            text: Math.round(root.temp) + "°"
                            color: root.text
                            font.family: root.ff
                            font.pixelSize: 11
                        }

                        Rectangle {
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 70
                            radius: 6
                            color: root.bg2

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: parent.height * Math.max(0, Math.min(100, root.temp)) / 100
                                radius: 6
                                color: root.red

                                Behavior on height {
                                    NumberAnimation {
                                        duration: 500
                                        easing.type: Easing.OutQuad
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 20

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Memory"
                                color: root.text
                                font.family: root.ff
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: root.memUsedMb + " MB / " + root.memTotalMb + " MB"
                                color: root.grey1
                                font.family: root.ff
                                font.pixelSize: 11
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            radius: 3
                            color: root.bg2

                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(100, root.ram)) / 100
                                height: parent.height
                                radius: 3
                                color: root.orange

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 500
                                        easing.type: Easing.OutQuad
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Disk"
                                color: root.text
                                font.family: root.ff
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: root.diskUsedGb + " GB / " + root.diskTotalGb + " GB"
                                color: root.grey1
                                font.family: root.ff
                                font.pixelSize: 11
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            radius: 3
                            color: root.bg2

                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(100, root.disk)) / 100
                                height: parent.height
                                radius: 3
                                color: root.blue

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 500
                                        easing.type: Easing.OutQuad
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: root.bg2
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 16

                Text {
                    text: root.ico(0xF0239)
                    color: root.text
                    font.family: root.ff
                    font.pixelSize: 24
                    verticalAlignment: Text.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            Quickshell.execDetached(["firefox"])
                            root.popup = ""
                        }
                    }
                }

                Text {
                    text: root.ico(0xF024B)
                    color: root.blue
                    font.family: root.ff
                    font.pixelSize: 24
                    verticalAlignment: Text.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            Quickshell.execDetached(["dolphin"])
                            root.popup = ""
                        }
                    }
                }

                Text {
                    text: root.ico(0xE795)
                    color: root.blue
                    font.family: root.ff
                    font.pixelSize: 24
                    verticalAlignment: Text.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            Quickshell.execDetached(["kitty"])
                            root.popup = ""
                        }
                    }
                }

                Text {
                    text: root.ico(0xF0A1E)
                    color: root.soft
                    font.family: root.ff
                    font.pixelSize: 24
                    verticalAlignment: Text.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            Quickshell.execDetached(["code"])
                            root.popup = ""
                        }
                    }
                }

                Text {
                    text: root.ico(0xF1BC)
                    color: root.green
                    font.family: root.ff
                    font.pixelSize: 24
                    verticalAlignment: Text.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            Quickshell.execDetached(["flatpak", "run", "com.spotify.Client"])
                            root.popup = ""
                        }
                    }
                }

                Text {
                    text: root.ico(0xF281)
                    color: root.orange
                    font.family: root.ff
                    font.pixelSize: 24
                    verticalAlignment: Text.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            Quickshell.execDetached(["firefox", "https://reddit.com"])
                            root.popup = ""
                        }
                    }
                }

                Text {
                    text: root.ico(0xF16A)
                    color: root.red
                    font.family: root.ff
                    font.pixelSize: 24
                    verticalAlignment: Text.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            Quickshell.execDetached(["firefox", "https://youtube.com"])
                            root.popup = ""
                        }
                    }
                }
            }
        }
    }
}


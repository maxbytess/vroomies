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
    readonly property string musicFF: "Google Sans Flex"
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

    property bool hoverLauncher: false
    property bool hoverMusic: false
    property bool hoverWifi: false
    property bool hoverVolume: false
    property bool hoverBrightness: false
    property bool hoverBattery: false
    property bool hoverMemory: false
    property bool hoverClock: false
    property bool hoverBluetooth: false

    property bool btAvailable: false
    property bool btPowered: false
    property string btDevice: ""

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
        const l = out.trim().split("\n")

        if (l.length < 8)
            return

        const cpuVal = Number(l[0])
        if (!isNaN(cpuVal))
            cpu = cpuVal

        const tempVal = Number(l[1])
        if (!isNaN(tempVal))
            temp = tempVal

        const totalKb = Number(l[2])
        const availKb = Number(l[3])

        if (totalKb > 0) {
            ram = 100 * (1 - availKb / totalKb)
            memTotalMb = Math.round(totalKb / 1024)
            memUsedMb = memTotalMb - Math.round(availKb / 1024)
        }

        const dTotKb = Number(l[4])
        const dUseKb = Number(l[5])

        if (dTotKb > 0) {
            disk = 100 * (dUseKb / dTotKb)
            diskTotalGb = Math.round(dTotKb / (1024 * 1024))
            diskUsedGb = Math.round(dUseKb / (1024 * 1024))
        }

        battery = Number(l[6])
        batteryState = l[7].trim()
    }

    Process {
        id: statsProc

        command: [
            "sh",
            "-c",
            "awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else {print int((u-u1)*100/(t-t1)); exit;}}' /proc/stat /proc/stat; cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -n1 | awk '{print int($1/1000)}'; awk '/^(MemTotal|MemAvailable)/ {print $2}' /proc/meminfo; df / | awk 'NR==2 {print $2; print $3}'; cat /sys/class/power_supply/BAT0/capacity /sys/class/power_supply/BAT0/status 2>/dev/null"
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

    Process {
        id: btProc

        command: [
            "sh",
            "-c",
            "bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2}'; bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d' ' -f3-"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n")
                const p = (l[0] ?? "").trim()
                root.btAvailable = p !== ""
                root.btPowered = p === "yes"
                root.btDevice = root.btPowered ? (l[1] ?? "").trim() : ""
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: btProc.running = true
    }

    Process {
        id: btToggleProc
        onExited: btProc.running = true
    }

    function toggleBluetooth() {
        btToggleProc.command = ["bluetoothctl", "power", btPowered ? "off" : "on"]
        btToggleProc.running = true
    }

    PanelWindow {
        id: bar

        anchors {
            top: true
            left: true
            right: true
        }

        margins {
            top: 9
            left: 10
            right: 10
        }

        implicitHeight: 40
        color: "transparent"

        Rectangle {
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

        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            RowLayout {
                spacing: 6

                MouseArea {
                    id: launcherArea

                    Layout.preferredWidth: launcherLayout.implicitWidth
                    Layout.preferredHeight: 24

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.hoverLauncher = true
                    onExited: root.hoverLauncher = false
                    onClicked: root.toggle("dashboard")

                    RowLayout {
                        id: launcherLayout
                        spacing: 6

                        Text {
                            text: root.ico(0xE22E)
                            color: root.hoverLauncher ? root.peach : root.blue
                            font.family: root.ff
                            font.pixelSize: 18
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Reveal {
                            shown: root.hoverLauncher

                            Row {
                                spacing: 6

                                Text {
                                    text: ""
                                    color: root.text
                                    font.family: root.ff
                                    font.pixelSize: 15

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                                    }
                                }

                                Text {
                                    text: ""
                                    color: root.text
                                    font.family: root.ff
                                    font.pixelSize: 15

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Quickshell.execDetached(["hyprlock"])
                                    }
                                }

                                Text {
                                    text: ""
                                    color: root.text
                                    font.family: root.ff
                                    font.pixelSize: 15

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                text: "|"
                color: root.grey1
                font.family: root.ff
                font.pixelSize: 16
                font.bold: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
            }

            RowLayout {
                spacing: 8

                Repeater {
                    model: root.workspaces

                    delegate: Text {
                        required property var modelData

                        readonly property bool active: modelData.is_active === true
                        readonly property bool hasWindow: modelData.active_window_id !== null

                        text: root.ico(active ? 0xF4BF : 0xF4C3)
                        color: active ? root.blue : (hasWindow ? root.text : root.grey1)
                        font.family: root.ff
                        font.pixelSize: 15

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
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

        RowLayout {
            id: musicSection

            visible: root.player !== null && root.player.trackTitle !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            spacing: 8

            MouseArea {
                id: musicArea

                Layout.preferredWidth: musicLayout.implicitWidth
                Layout.preferredHeight: 28

                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onEntered: root.hoverMusic = true
                onExited: root.hoverMusic = false

                RowLayout {
                    id: musicLayout
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20

                        radius: 10
                        color: root.bg2
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: root.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    Item {
                        id: musicTitleArea
                        Layout.preferredWidth: Math.min(musicTitle.implicitWidth, bar.width - 560)
                        Layout.preferredHeight: 26

                        clip: true

                        Text {
                            id: musicTitle

                            anchors.verticalCenter: parent.verticalCenter

                            text: root.player?.trackTitle ?? ""
                            color: root.blue
                            font.family: root.musicFF
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            wrapMode: Text.NoWrap
                            elide: Text.ElideNone

                            x: musicTitleArea.width >= implicitWidth
                                ? 0
                                : (musicTitleArea.width - implicitWidth) * musicTitleOffset.progress
                        }

                        property real scrollPosition: 0

                        NumberAnimation {
                            id: musicTitleOffset

                            target: musicTitleArea
                            property: "scrollPosition"
                            from: 0
                            to: 1
                            duration: Math.max(5000, musicTitle.implicitWidth * 45)
                            loops: Animation.Infinite
                            running: musicTitle.implicitWidth > musicTitleArea.width && root.hoverMusic
                        }

                        property real progress: scrollPosition
                    }

                    Reveal {
                        shown: root.hoverMusic

                        Row {
                            spacing: 10

                            Text {
                                text: root.ico(0xF04A)
                                color: root.text
                                font.family: root.ff
                                font.pixelSize: 15
                                font.bold: true

                                MouseArea {
                                    anchors.fill: parent
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
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.player?.next()
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            MouseArea {
                Layout.preferredWidth: memLayout.implicitWidth
                Layout.preferredHeight: 24
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hoverMemory = true
                onExited: root.hoverMemory = false

                RowLayout {
                    id: memLayout
                    spacing: 6

                    Ring {
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

                    Reveal {
                        shown: root.hoverMemory

                        Text {
                            text: Math.round(root.ram) + "%"
                            color: root.orange
                            font.family: root.ff
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                }
            }

            MouseArea {
                visible: root.battery >= 0
                Layout.preferredWidth: batLayout.implicitWidth
                Layout.preferredHeight: 24
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hoverBattery = true
                onExited: root.hoverBattery = false

                RowLayout {
                    id: batLayout
                    spacing: 6

                    Ring {
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

                    Reveal {
                        shown: root.hoverBattery

                        Text {
                            text: root.battery + "%"
                            color: root.green
                            font.family: root.ff
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                }
            }

            RowLayout {
                visible: root.brightness >= 0
                spacing: 6

                MouseArea {
                    Layout.preferredWidth: brLayout.implicitWidth
                    Layout.preferredHeight: 24
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.hoverBrightness = true
                    onExited: root.hoverBrightness = false

                    RowLayout {
                        id: brLayout
                        spacing: 6

                        Text {
                            text: root.ico(0xF00DF)
                            color: root.peach
                            font.family: root.ff
                            font.pixelSize: 16
                        }

                        Reveal {
                            shown: root.hoverBrightness

                            HSlider {
                                value: root.brightness
                                trackColor: root.bg2
                                fillColor: root.peach
                                onMoved: v => root.setBrightness(v)
                                onDraggingChanged: root.brDragging = dragging
                            }
                        }
                    }
                }
            }

            MouseArea {
                Layout.preferredWidth: volLayout.implicitWidth
                Layout.preferredHeight: 24
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hoverVolume = true
                onExited: root.hoverVolume = false

                acceptedButtons: Qt.LeftButton | Qt.RightButton

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

                RowLayout {
                    id: volLayout
                    spacing: 6

                    Text {
                        text: root.ico(root.muted ? 0xF075F : 0xF057E)
                        color: root.muted ? root.grey1 : root.blue
                        font.family: root.ff
                        font.pixelSize: 16
                    }

                    Reveal {
                        shown: root.hoverVolume

                        RowLayout {
                            spacing: 6

                            HSlider {
                                value: root.volume * 100
                                trackColor: root.bg2
                                fillColor: root.blue
                                onMoved: v => root.setVolume(v)
                            }
                        }
                    }
                }
            }

            MouseArea {
                Layout.preferredWidth: wifiLayout.implicitWidth
                Layout.preferredHeight: 24
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hoverWifi = true
                onExited: root.hoverWifi = false

                onClicked: Quickshell.execDetached([
                    "bash",
                    "-c",
                    "~/.config/quickshell/nn/scripts/wifi.sh menu"
                ])

                RowLayout {
                    id: wifiLayout
                    spacing: 6

                    Text {
                        text: root.ico(root.ssid !== "" ? 0xF0928 : 0xF092F)
                        color: root.ssid !== "" ? root.blue : root.grey1
                        font.family: root.ff
                        font.pixelSize: 16
                    }

                    Reveal {
                        shown: root.hoverWifi

                        Text {
                            id: wifiText
                            text: root.ssid !== "" ? root.ssid : "Not connected"
                            color: root.blue
                            font.family: root.ff
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, 150)
                        }
                    }
                }
            }

            MouseArea {
                visible: root.btAvailable
                Layout.preferredWidth: btLayout.implicitWidth
                Layout.preferredHeight: 24
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onEntered: root.hoverBluetooth = true
                onExited: root.hoverBluetooth = false

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        root.toggleBluetooth()
                    else
                        Quickshell.execDetached([
                            "bash",
                            "-c",
                            "~/.config/quickshell/nn/scripts/bluetooth.sh menu"
                        ])
                }

                RowLayout {
                    id: btLayout
                    spacing: 6

                    Text {
                        text: root.ico(!root.btPowered ? 0xF00B2 : (root.btDevice !== "" ? 0xF00B1 : 0xF00AF))
                        color: !root.btPowered ? root.grey1 : (root.btDevice !== "" ? root.blue : root.text)
                        font.family: root.ff
                        font.pixelSize: 16
                    }

                    Reveal {
                        shown: root.hoverBluetooth

                        Text {
                            text: !root.btPowered
                                ? "Bluetooth off"
                                : (root.btDevice !== "" ? root.btDevice : "No device")
                            color: !root.btPowered ? root.grey1 : (root.btDevice !== "" ? root.blue : root.text)
                            font.family: root.ff
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, 150)
                        }
                    }
                }
            }

            Text {
                text: "|"
                color: root.grey1
                font.family: root.ff
                font.pixelSize: 18
                font.bold: true
            }

            MouseArea {
                id: clockArea
                Layout.preferredWidth: clockRow.implicitWidth
                Layout.preferredHeight: 24
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggle("calendar")

                RowLayout {
                    id: clockRow
                    spacing: 3

                    Text {
                        text: root.hour24
                        color: root.text
                        font.family: root.ff
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Text {
                        text: ":"
                        color: root.text
                        font.family: root.ff
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Text {
                        text: root.minute
                        color: root.text
                        font.family: root.ff
                        font.pixelSize: 18
                        font.bold: true
                    }
                }
            }
        }
    }

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
            top: true
            right: true
        }

        margins {
            top: 56
            right: 12
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
            top: 56
            left: 12
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

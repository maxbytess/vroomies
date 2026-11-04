import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: dashboard

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "vroomies-dashboard"
    readonly property real screenW: screen ? screen.width  : 1366
    readonly property real screenH: screen ? screen.height : 768
    implicitWidth:  Math.min(1360, screenW - 140)
    implicitHeight: Math.min(830,  screenH - 110)
    WlrLayershell.keyboardFocus: showDashboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool showDashboard: false
    property real reveal: showDashboard ? 1 : 0
    Behavior on reveal { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    visible: showDashboard || reveal > 0.01

    property color bg:      "#151218"
    property color fg:      "#e7e0e8"
    property color accent:  "#d5bbfc"
    property color col1:    "#cc8f6f"
    property color col2:    "#7aab8a"
    property color col3:    "#7f9fbd"
    property color muted:   "#6b6760"
    property color surface: "#211e24"

    readonly property string fontFam:    "Monocraft Nerd Font"
    readonly property string configPath: Quickshell.env("HOME") + "/.config/quickshell/vv"
    readonly property string ppDir:      configPath + "/components/assets/pp/"
    readonly property var shellTheme: zyuTheme
    readonly property var panelTheme: ({
        bar_bg: bg, bar_fg: fg, accent: accent,
        widget_bg: surface, muted: muted
    })

    Process {
        id: colorProc
        command: ["bash", "-c", "cat " + dashboard.configPath + "/Colors/colors.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var c = JSON.parse(data)
                    if (c.background)         dashboard.bg      = c.background
                    if (c.on_surface)         dashboard.fg      = c.on_surface
                    if (c.primary)            dashboard.accent  = c.primary
                    if (c.tertiary)           dashboard.col1    = c.tertiary
                    if (c.secondary)          dashboard.col2    = c.secondary
                    if (c.primary_fixed_dim)  dashboard.col3    = c.primary_fixed_dim
                    if (c.on_surface_variant) dashboard.muted   = c.on_surface_variant
                    if (c.surface_container)  dashboard.surface = c.surface_container
                } catch(e) {}
            }
        }
        Component.onCompleted: running = true
    }

    property string currentTab: "home"
    property var openedTabs: ["home"]

    readonly property var tabs: [
        { id: "home", icon: 0xF056E, label: "Dashboard" },
        { id: "wifi", icon: 0xF0928, label: "Wi-Fi" },
        { id: "bt",   icon: 0xF00AF, label: "Bluetooth" },
        { id: "ai",   icon: 0xF09D1, label: "AI" },
        { id: "me",   icon: 0x2665,  label: "( Me )" }
    ]

    function openTab(id) {
        if (openedTabs.indexOf(id) < 0) openedTabs = openedTabs.concat([id])
        currentTab = id
        if (typeof dashboardState !== "undefined" && dashboardState.tab !== id) dashboardState.tab = id
    }
    function stepTab(delta) {
        var i = 0
        for (var k = 0; k < tabs.length; k++) if (tabs[k].id === currentTab) i = k
        var n = Math.max(0, Math.min(tabs.length - 1, i + delta))
        openTab(tabs[n].id)
    }
    onCurrentTabChanged: focusItem.forceActiveFocus()

    function closeDashboard() {
        if (typeof dashboardState !== "undefined") dashboardState.show = false
        dashboard.showDashboard = false
    }

    signal calNav(int dm, int dy)

    IpcHandler {
        target: "dashboard"
        function toggle(): void {
            if (typeof dashboardState !== "undefined") dashboardState.show = !dashboardState.show
            else dashboard.showDashboard = !dashboard.showDashboard
        }
        function open(tab: string): void {
            var ok = false
            for (var i = 0; i < dashboard.tabs.length; i++) if (dashboard.tabs[i].id === tab) ok = true
            dashboard.openTab(ok ? tab : "home")
            if (typeof dashboardState !== "undefined") dashboardState.show = true
            else dashboard.showDashboard = true
        }
        function close(): void { dashboard.closeDashboard() }
    }

    IpcHandler {
        target: "ai"
        function toggle(): void {
            if (dashboard.showDashboard && dashboard.currentTab === "ai") dashboard.closeDashboard()
            else { dashboard.openTab("ai"); dashboardState.show = true }
        }
        function open(): void  { dashboard.openTab("ai"); dashboardState.show = true }
        function close(): void { dashboard.closeDashboard() }
    }

    Connections {
        target: typeof dashboardState !== "undefined" ? dashboardState : null
        function onShowChanged() {
            dashboard.showDashboard = dashboardState.show
            if (dashboardState.show) { dashboard.openTab(dashboardState.tab); focusTimer.start() }
        }
        function onTabChanged() {
            if (dashboard.currentTab !== dashboardState.tab) dashboard.openTab(dashboardState.tab)
        }
    }

    Timer {
        id: focusTimer
        interval: 50; repeat: false
        onTriggered: {
            dashboard.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive
            focusItem.forceActiveFocus()
            releaseTimer.start()
        }
    }
    Timer {
        id: releaseTimer
        interval: 100; repeat: false
        onTriggered: dashboard.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand
    }

    property date now: new Date()
    Timer {
        interval: 1000; running: dashboard.showDashboard; repeat: true; triggeredOnStart: true
        onTriggered: dashboard.now = new Date()
    }

    property bool doNotDisturb: false

    property int batVal:    100
    property bool batCharging: false
    property string batStatusText: "Checking..."
    readonly property int batIconCp: batCharging ? 0xF0084
        : (batVal >= 90 ? 0xF0079 : batVal >= 70 ? 0xF0081 : batVal >= 50 ? 0xF007F : batVal >= 30 ? 0xF007D : 0xF007A)
    property int volVal:    50
    property int brightVal: 100
    property real cpuPerc:  0
    property int cpuVal:    Math.round(cpuPerc * 100)
    property int ramVal:    0
    property real memUsedKib:  0
    property real memTotalKib: 0
    property int diskVal:   0
    property int tempVal:   0
    property real netDown:  0
    property real netUp:    0
    property var cpuTrail:  []
    property var downTrail: []
    property var upTrail:   []
    property string wifiSsid: ""
    property string btDevice: ""
    property string uptimeStr: "..."
    property bool idleOn:   true
    property bool wifiOn:   false
    property bool btOn:     false

    Component.onCompleted: {
        ppFindProc.running = true
        batProc.running = true
        batStatusProc.running = true
        volProc.running = true
        brightProc.running = true
        statsProc.running = true
        idleStatusProc.running = true
        wifiStateProc.running = true
        btStateProc.running = true
    }

    Timer {
        interval: 2000; running: dashboard.showDashboard; repeat: true
        onTriggered: {
            if (!batProc.running)        batProc.running = true
            if (!batStatusProc.running)  batStatusProc.running = true
            if (!volProc.running)        volProc.running = true
            if (!brightProc.running)     brightProc.running = true
            if (!uptimeProc.running)     uptimeProc.running = true
            if (!statsProc.running)      statsProc.running = true
            if (!ssidProc.running)       ssidProc.running = true
            if (!btDevProc.running)      btDevProc.running = true
            if (!idleStatusProc.running) idleStatusProc.running = true
            if (!wifiStateProc.running)  wifiStateProc.running = true
            if (!btStateProc.running)    btStateProc.running = true
        }
    }

    function toggleWifi() {
        wifiOn = !wifiOn
        wifiToggleProc.running = true
    }
    function toggleBt() {
        btOn = !btOn
        btToggleProc.running = true
    }
    function toggleIdle()      { idleToggleProc.running = true }
    function takeScreenshot()  { closeDashboard(); screenshotProc.running = true }
    function lockScreen() {
        closeDashboard()
        Quickshell.execDetached(["quickshell", "-p", Quickshell.env("HOME") + "/.config/quickshell/vv/components/Lock/shell.qml"])
    }
    function powerMenu()       { wlogoutProc.running = true }
    function toggleMute()      { volMuteProc.running = true }

    property int _pendingVol: -1
    function setVolume(p) {
        p = Math.max(0, Math.min(100, p))
        volVal = p
        _pendingVol = p
        if (!volSetProc.running) _runVol()
    }
    function _runVol() {
        var p = _pendingVol
        volSetProc.command = ["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (p / 100).toFixed(2)]
        volSetProc.running = true
    }
    property int _pendingBright: -1
    function setBrightness(p) {
        p = Math.max(1, Math.min(100, p))
        brightVal = p
        _pendingBright = p
        if (!brightSetProc.running) _runBright()
    }
    function _runBright() {
        brightSetProc.command = ["bash", "-c", "brightnessctl set " + _pendingBright + "%"]
        brightSetProc.running = true
    }

    Process { id: wifiToggleProc; command: ["bash", "-c", "nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on"] }
    Process { id: btToggleProc;   command: ["bash", "-c", "bluetoothctl show | grep -q 'Powered: yes' && bluetoothctl power off || bluetoothctl power on"] }
    Process { id: wlogoutProc;    command: ["bash", "-c", "wlogout"] }
    Process {
        id: volMuteProc
        command: ["bash", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"]
        onExited: volProc.running = true
    }
    Process {
        id: volSetProc
        onExited: if (dashboard._pendingVol !== dashboard.volVal && dashboard._pendingVol >= 0) dashboard._runVol()
    }
    Process {
        id: brightSetProc
        onExited: if (dashboard._pendingBright !== dashboard.brightVal && dashboard._pendingBright >= 0) dashboard._runBright()
    }

    Process {
        id: wifiStateProc
        command: ["bash", "-c", "nmcli radio wifi 2>/dev/null"]
        stdout: SplitParser { onRead: data => dashboard.wifiOn = data.trim() === "enabled" }
    }
    Process {
        id: btStateProc
        command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off"]
        stdout: SplitParser { onRead: data => dashboard.btOn = data.trim() === "on" }
    }
    property double _lastTot: 0
    property double _lastIdle: 0
    property double _lastRx: -1
    property double _lastTx: 0
    property double _lastT: 0
    function _push(list, v) {
        var n = list.concat([v])
        return n.length > 40 ? n.slice(n.length - 40) : n
    }
    Process {
        id: statsProc
        command: ["bash", "-c", [
            "read -r _ u n s i io irq sirq st _ < /proc/stat",
            "tot=$((u+n+s+i+io+irq+sirq+st)); idle=$((i+io))",
            "mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{print t-a, t}' /proc/meminfo)",
            "disk=$(df / | awk 'NR==2{gsub(/%/,\"\");print $5}')",
            "temp=0",
            "for z in /sys/class/thermal/thermal_zone*; do",
            "  ty=$(cat $z/type 2>/dev/null)",
            "  case \"$ty\" in x86_pkg_temp|k10temp|coretemp|cpu*|acpitz) v=$(cat $z/temp 2>/dev/null); if [ -n \"$v\" ]; then temp=$((v/1000)); break; fi;; esac",
            "done",
            "net=$(awk 'NR>2 && $1 !~ /^lo:/ {r+=$2; t+=$10} END{print r+0, t+0}' /proc/net/dev)",
            "echo \"$tot $idle $mem $disk $temp $net\""
        ].join("\n")]
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim().split(/\s+/).map(Number)
                if (p.length < 8 || p.some(isNaN)) return
                var now = Date.now()

                var dTot = p[0] - dashboard._lastTot, dIdle = p[1] - dashboard._lastIdle
                if (dashboard._lastTot > 0 && dTot > 0) {
                    dashboard.cpuPerc = Math.max(0, Math.min(1, 1 - dIdle / dTot))
                    dashboard.cpuTrail = dashboard._push(dashboard.cpuTrail, dashboard.cpuPerc)
                }
                dashboard._lastTot = p[0]; dashboard._lastIdle = p[1]

                dashboard.memUsedKib = p[2]; dashboard.memTotalKib = p[3]
                dashboard.ramVal  = p[3] > 0 ? Math.round(p[2] / p[3] * 100) : 0
                dashboard.diskVal = p[4]
                dashboard.tempVal = p[5]

                if (dashboard._lastRx >= 0 && now > dashboard._lastT) {
                    var dt = (now - dashboard._lastT) / 1000
                    dashboard.netDown = Math.max(0, (p[6] - dashboard._lastRx) / dt)
                    dashboard.netUp   = Math.max(0, (p[7] - dashboard._lastTx) / dt)
                    dashboard.downTrail = dashboard._push(dashboard.downTrail, dashboard.netDown)
                    dashboard.upTrail   = dashboard._push(dashboard.upTrail,   dashboard.netUp)
                }
                dashboard._lastRx = p[6]; dashboard._lastTx = p[7]; dashboard._lastT = now
            }
        }
    }
    Process {
        id: ssidProc
        command: ["bash", "-c", "nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1==\"yes\"{print $2; exit}'"]
        stdout: SplitParser { onRead: data => dashboard.wifiSsid = data.trim() }
        onExited: if (!dashboard.wifiOn) dashboard.wifiSsid = ""
    }
    Process {
        id: btDevProc
        command: ["bash", "-c", "bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-"]
        stdout: SplitParser { onRead: data => dashboard.btDevice = data.trim() }
    }
    Process {
        id: idleStatusProc
        command: ["bash", "-c", "pgrep -x hypridle >/dev/null && echo true || echo false"]
        stdout: SplitParser { onRead: data => dashboard.idleOn = data.trim() === "true" }
    }
    Process {
        id: idleToggleProc
        command: ["bash", "-c", "pgrep -x hypridle >/dev/null && pkill -x hypridle || (hypridle & disown)"]
        onExited: idleStatusProc.running = true
    }
    Process {
        id: screenshotProc
        command: ["bash", "-c",
            "mkdir -p " + Quickshell.env("HOME") + "/Pictures/Screenshots && " +
            "grim -g \"$(slurp)\" " + Quickshell.env("HOME") + "/Pictures/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png"]
    }
    Process {
        id: batProc
        command: ["bash", "-c", "if [ -f /sys/class/power_supply/BAT0/capacity ]; then cat /sys/class/power_supply/BAT0/capacity; elif [ -f /sys/class/power_supply/BAT1/capacity ]; then cat /sys/class/power_supply/BAT1/capacity; else echo 100; fi"]
        stdout: SplitParser { onRead: data => dashboard.batVal = parseInt(data) || 100 }
    }
    Process {
        id: batStatusProc
        command: ["bash", "-c", "if [ -f /sys/class/power_supply/BAT0/status ]; then cat /sys/class/power_supply/BAT0/status; elif [ -f /sys/class/power_supply/BAT1/status ]; then cat /sys/class/power_supply/BAT1/status; else echo Unknown; fi"]
        stdout: SplitParser {
            onRead: data => {
                var s = data.trim()
                dashboard.batCharging = (s === "Charging")
                if      (s === "Charging")    dashboard.batStatusText = "Charging..."
                else if (s === "Full")        dashboard.batStatusText = "Fully charged"
                else if (s === "Discharging") dashboard.batStatusText = "On battery"
                else                          dashboard.batStatusText = "Unknown"
            }
        }
    }
    Process {
        id: volProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf \"%.0f\", $2*100}'"]
        stdout: SplitParser { onRead: data => { if (!volSetProc.running) dashboard.volVal = parseInt(data) || 0 } }
    }
    Process {
        id: brightProc
        command: ["bash", "-c", "brightnessctl -m | awk -F, '{gsub(/%/,\"\"); print $4}'"]
        stdout: SplitParser { onRead: data => { if (!brightSetProc.running) dashboard.brightVal = parseInt(data) || 100 } }
    }
    Process {
        id: uptimeProc
        command: ["bash", "-c", "uptime -p | sed 's/up //'"]
        stdout: SplitParser { onRead: data => dashboard.uptimeStr = data.trim() }
    }

    property var ppFiles: []
    property bool ppPickerOpen: false
    property string ppActualPath: ""
    readonly property string ppStatePath: configPath + "/state/profile-picture"

    function togglePpPicker() {
        ppPickerOpen = !ppPickerOpen
        if (ppPickerOpen) { ppFiles = []; ppListProc.running = true }
    }
    function pickPp(path) {
        ppActualPath = path
        ppPickerOpen = false
        savePp(path)
    }
    function savePp(path) {
        ppSaveProc.command = ["bash", "-c",
            "mkdir -p \"$(dirname \"$2\")\" && printf '%s' \"$1\" > \"$2\"",
            "_", path, dashboard.ppStatePath]
        ppSaveProc.running = true
    }
    Process { id: ppSaveProc }
    Process {
        id: ppFindProc
        command: ["bash", "-c",
            "f=$(cat \"$1\" 2>/dev/null); if [ -f \"$f\" ]; then echo \"$f\"; " +
            "else ls -t \"$2\"*.jpg \"$2\"*.png \"$2\"*.gif 2>/dev/null | head -1; fi",
            "_", dashboard.ppStatePath, dashboard.ppDir]
        stdout: SplitParser {
            onRead: data => {
                var f = data.trim()
                if (f.length > 0) dashboard.ppActualPath = f
            }
        }
    }
    Process {
        id: ppListProc
        command: ["bash", "-c", "find " + dashboard.ppDir + " -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' \\) | sort"]
        stdout: SplitParser {
            onRead: data => {
                var f = data.trim()
                if (f.length > 0) {
                    var arr = dashboard.ppFiles.slice()
                    arr.push(f)
                    dashboard.ppFiles = arr
                }
            }
        }
    }

    property int nextPopupId: 0
    readonly property var notifs: notifServer

    NotificationServer {
        id: notifServer
        keepOnReload: true
        onNotification: (notif) => {
            notif.tracked = true
            if (dashboard.doNotDisturb) return
            var pid = dashboard.nextPopupId++
            popupModel.append({
                nid:      pid,
                nSummary: notif.appName + (notif.summary ? ": " + notif.summary : ""),
                nBody:    notif.body || "",
                nIcon:    notif.image || notif.appIcon || ""
            })
            popupExpire.createObject(dashboard, { targetId: pid })
            while (popupModel.count > 3) popupModel.remove(0)
        }
    }

    ListModel { id: popupModel }
    Component {
        id: popupExpire
        Timer {
            property int targetId: 0
            interval: 5000; running: true; repeat: false
            onTriggered: {
                for (var i = 0; i < popupModel.count; i++) {
                    if (popupModel.get(i).nid === targetId) { popupModel.remove(i); break }
                }
                destroy()
            }
        }
    }

    PanelWindow {
        id: popupWindow
        visible: popupModel.count > 0
        exclusionMode: ExclusionMode.Ignore
        focusable: false
        color: "transparent"
        anchors { bottom: true; right: true }
        margins { bottom: 20; right: 20 }
        implicitWidth: 320
        implicitHeight: popupCol.implicitHeight + 20
        WlrLayershell.layer: WlrLayer.Overlay

        Column {
            id: popupCol
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            spacing: 8
            width: parent.width

            Repeater {
                model: popupModel
                Rectangle {
                    width: 320
                    height: popRow.implicitHeight + 20
                    radius: 14
                    color: Qt.rgba(dashboard.bg.r, dashboard.bg.g, dashboard.bg.b, 0.95)
                    border.color: Qt.rgba(dashboard.accent.r, dashboard.accent.g, dashboard.accent.b, 0.25)
                    border.width: 1

                    RowLayout {
                        id: popRow
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                        anchors.leftMargin: 14; anchors.rightMargin: 10
                        spacing: 10

                        Rectangle {
                            width: 28; height: 28; radius: 8
                            color: Qt.rgba(dashboard.accent.r, dashboard.accent.g, dashboard.accent.b, 0.15)
                            Image {
                                anchors.fill: parent
                                anchors.margins: 4
                                visible: model.nIcon !== ""
                                source: model.nIcon !== "" ? model.nIcon : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: model.nIcon === ""
                                text: String.fromCodePoint(0xF009A)
                                color: dashboard.accent
                                font.pixelSize: 13; font.family: dashboard.fontFam
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: model.nSummary
                                color: dashboard.fg
                                font.pixelSize: 11; font.bold: true
                                font.family: dashboard.fontFam
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                visible: model.nBody !== ""
                                text: model.nBody
                                color: dashboard.muted
                                font.pixelSize: 10
                                font.family: dashboard.fontFam
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        Rectangle {
                            width: 18; height: 18; radius: 4
                            color: popCloseMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                            Text { anchors.centerIn: parent; text: "✕"; color: dashboard.muted; font.pixelSize: 9; font.family: dashboard.fontFam }
                            MouseArea {
                                id: popCloseMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: popupModel.remove(index)
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: focusItem
        anchors.fill: parent
        focus: dashboard.showDashboard

        Keys.onPressed: function(event) {
            var ctrl = (event.modifiers & Qt.ControlModifier)
            if (event.key === Qt.Key_Escape) {
                if (dashboard.ppPickerOpen) dashboard.ppPickerOpen = false
                else dashboard.closeDashboard()
                event.accepted = true
            } else if (ctrl && event.key === Qt.Key_Left)  { dashboard.stepTab(-1); event.accepted = true }
            else if (ctrl && event.key === Qt.Key_Right)   { dashboard.stepTab(1);  event.accepted = true }
            else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_5) {
                dashboard.openTab(dashboard.tabs[event.key - Qt.Key_1].id)
                event.accepted = true
            } else if (event.key === Qt.Key_M && dashboard.currentTab === "me") {
                dashboard.togglePpPicker()
                event.accepted = true
            } else if (dashboard.currentTab === "home") {
                if      (event.key === Qt.Key_Left)  { dashboard.calNav(-1, 0); event.accepted = true }
                else if (event.key === Qt.Key_Right) { dashboard.calNav(1, 0);  event.accepted = true }
                else if (event.key === Qt.Key_Up)    { dashboard.calNav(0, -1); event.accepted = true }
                else if (event.key === Qt.Key_Down)  { dashboard.calNav(0, 1);  event.accepted = true }
            }
        }

        Item {
            id: stage
            anchors.fill: parent
            opacity: dashboard.reveal
            scale: 0.96 + 0.04 * dashboard.reveal
            transformOrigin: Item.Center

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                property real wheelAccum: 0
                onWheel: wheel => {
                    wheelAccum += wheel.angleDelta.y
                    while (Math.abs(wheelAccum) >= 120) {
                        dashboard.stepTab(wheelAccum > 0 ? -1 : 1)
                        wheelAccum -= wheelAccum > 0 ? 120 : -120
                    }
                }
            }

            Rectangle {
                id: capsule
                anchors.horizontalCenter: parent.horizontalCenter
                y: 14
                z: 3
                width: Math.min(parent.width - 100, tabRow.implicitWidth + 28)
                height: 54
                radius: height / 2
                color: Qt.rgba(dashboard.surface.r, dashboard.surface.g, dashboard.surface.b, 0.98)
                border.width: 1
                border.color: Qt.rgba(dashboard.fg.r, dashboard.fg.g, dashboard.fg.b, 0.12)
                Behavior on color { ColorAnimation { duration: 300 } }

                Row {
                    id: tabRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        id: tabRepeater
                        model: dashboard.tabs

                        Item {
                            id: tabBtn
                            required property var modelData
                            readonly property bool active: modelData.id === dashboard.currentTab
                            width: tabContent.implicitWidth + 30
                            height: 40

                            Rectangle {
                                anchors.fill: parent
                                radius: 14
                                color: tabBtn.active
                                    ? Qt.rgba(dashboard.accent.r, dashboard.accent.g, dashboard.accent.b, 0.16)
                                    : tabMa.containsMouse ? Qt.rgba(1, 1, 1, 0.045) : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                            Row {
                                id: tabContent
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: String.fromCodePoint(tabBtn.modelData.icon)
                                    color: tabBtn.active ? dashboard.accent : dashboard.muted
                                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: tabBtn.modelData.label
                                    color: tabBtn.active ? dashboard.fg : dashboard.muted
                                    font.family: dashboard.fontFam; font.pixelSize: 12
                                    font.bold: tabBtn.active
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }
                            MouseArea {
                                id: tabMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: dashboard.openTab(tabBtn.modelData.id)
                            }
                        }
                    }
                }

                Rectangle {
                    readonly property Item act: {
                        var n = tabRepeater.count
                        for (var i = 0; i < n; i++)
                            if (dashboard.tabs[i].id === dashboard.currentTab) return tabRepeater.itemAt(i)
                        return null
                    }
                    visible: act !== null
                    x: tabRow.x + (act ? act.x : 0) + 20
                    y: capsule.height - height - 5
                    width: act ? Math.max(0, act.width - 40) : 0
                    height: 2; radius: 1
                    color: dashboard.accent
                    Behavior on x     { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                }
            }

            Rectangle {
                anchors.verticalCenter: capsule.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 12
                z: 4
                width: 40; height: 40; radius: 20
                color: Qt.rgba(dashboard.surface.r, dashboard.surface.g, dashboard.surface.b, 0.98)
                border.width: 1
                border.color: closeMa.containsMouse
                    ? Qt.rgba(dashboard.col1.r, dashboard.col1.g, dashboard.col1.b, 0.6)
                    : Qt.rgba(dashboard.fg.r, dashboard.fg.g, dashboard.fg.b, 0.12)
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: closeMa.containsMouse ? dashboard.col1 : dashboard.muted
                    font.pixelSize: 13; font.family: dashboard.fontFam
                }
                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: dashboard.closeDashboard()
                }
            }

            Rectangle {
                id: frame
                anchors.horizontalCenter: parent.horizontalCenter
                y: 0
                z: 0
                width: parent.width
                height: parent.height
                radius: 28
                color: Qt.rgba(dashboard.bg.r, dashboard.bg.g, dashboard.bg.b, 0.97)
                border.width: 1
                border.color: Qt.rgba(dashboard.accent.r, dashboard.accent.g, dashboard.accent.b, 0.28)
                Behavior on color { ColorAnimation { duration: 300 } }

                Loader {
                    anchors.fill: parent
                    anchors.leftMargin: 22
                    anchors.rightMargin: 22
                    anchors.topMargin: 84
                    anchors.bottomMargin: 22
                    active: dashboard.openedTabs.indexOf("home") >= 0
                    opacity: dashboard.currentTab === "home" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    sourceComponent: Component {
                        Item {
                            anchors.fill: parent
                            HomeTab { anchors.fill: parent; th: dashboard }
                        }
                    }
                }
                Loader {
                    anchors.fill: parent
                    anchors.leftMargin: 22
                    anchors.rightMargin: 22
                    anchors.topMargin: 84
                    anchors.bottomMargin: 22
                    active: dashboard.openedTabs.indexOf("wifi") >= 0
                    opacity: dashboard.currentTab === "wifi" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    sourceComponent: Component {
                        Item {
                            anchors.fill: parent
                            WifiTab {
                                anchors.fill: parent
                                tabActive: dashboard.currentTab === "wifi"
                                zyuTheme: dashboard.panelTheme
                                onCloseRequested: dashboard.closeDashboard()
                            }
                        }
                    }
                }
                Loader {
                    anchors.fill: parent
                    anchors.leftMargin: 22
                    anchors.rightMargin: 22
                    anchors.topMargin: 84
                    anchors.bottomMargin: 22
                    active: dashboard.openedTabs.indexOf("bt") >= 0
                    opacity: dashboard.currentTab === "bt" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    sourceComponent: Component {
                        Item {
                            anchors.fill: parent
                            BluetoothTab {
                                anchors.fill: parent
                                tabActive: dashboard.currentTab === "bt"
                                zyuTheme: dashboard.panelTheme
                                onCloseRequested: dashboard.closeDashboard()
                            }
                        }
                    }
                }
                Loader {
                    anchors.fill: parent
                    anchors.leftMargin: 22
                    anchors.rightMargin: 22
                    anchors.topMargin: 84
                    anchors.bottomMargin: 22
                    active: dashboard.openedTabs.indexOf("ai") >= 0
                    opacity: dashboard.currentTab === "ai" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    sourceComponent: Component {
                        Item {
                            anchors.fill: parent
                            AITab {
                                anchors.fill: parent
                                tabActive: dashboard.currentTab === "ai"
                                zyuTheme: dashboard.panelTheme
                                onCloseRequested: dashboard.closeDashboard()
                            }
                        }
                    }
                }
                Loader {
                    anchors.fill: parent
                    anchors.leftMargin: 22
                    anchors.rightMargin: 22
                    anchors.topMargin: 84
                    anchors.bottomMargin: 22
                    active: dashboard.openedTabs.indexOf("me") >= 0
                    opacity: dashboard.currentTab === "me" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    sourceComponent: Component {
                        Item {
                            anchors.fill: parent
                            MeTab { anchors.fill: parent; th: dashboard }
                        }
                    }
                }
            }
        }
    }
}

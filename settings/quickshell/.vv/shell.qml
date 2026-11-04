import QtQuick
import Quickshell
import Quickshell.Io
import "components"

ShellRoot {
    id: root
    property alias zyuTheme: zyuTheme
    property alias dashboardState: dashboardState
    property alias logoutState: logoutState
    property alias settingsState: settingsState
    property bool musicVisible: false
    property bool wifiVisible:  false
    property bool btVisible:    false
    property bool aiVisible:    false
    property bool wallVisible:  false

    // Bar sadece yanlarda: "left" | "right" | "both" (iki yanda ayri bar)
    property string barPosition:  "left"
    readonly property bool barLeft:  barPosition === "left"  || barPosition === "both"
    readonly property bool barRight: barPosition === "right" || barPosition === "both"
    readonly property int barThickness: 56
    property real   musicAnchorY: 0
    property real   dockPillHeight: 0

    property string selectedMusic: "MusicPanel"                             // "MusicPanel" | "Cyna"
    property string photoPath:     ""                                       // resim widget'inin gosterdigi dosya
    property string photoShape:    "circle"                                 // "square" | "circle"
    property bool   photoEnabled:  true
    property bool   dockEnabled:   true
    property var    dockFavorites: []                                       // desktop entry id'leri, orn. ["kitty","firefox"]
    readonly property int dockHeight: 64
    property real   clockX: -1
    property real   clockY: -1
    property real   clockScale: 1.0
    property real   photoX: -1
    property real   photoY: -1
    property real   photoScale: 1.0

    readonly property string settingsPath: Quickshell.env("HOME") + "/.config/quickshell/vv/settings.json"

    function saveSettings() {
        var payload = JSON.stringify({
            barPosition: root.barPosition,
            musicStyle:  root.selectedMusic,
            photoPath:    root.photoPath,
            photoShape:   root.photoShape,
            photoEnabled: root.photoEnabled,
            dockEnabled:   root.dockEnabled,
            dockFavorites: root.dockFavorites,
            clockX: root.clockX, clockY: root.clockY, clockScale: root.clockScale,
            photoX: root.photoX, photoY: root.photoY, photoScale: root.photoScale
        })
        settingsWriter.command = ["bash", "-c",
            "mkdir -p " + Quickshell.env("HOME") + "/.config/quickshell/vv && cat > " + root.settingsPath +
            " << 'VROOMIES_SETTINGS_EOF'\n" + payload + "\nVROOMIES_SETTINGS_EOF"]
        settingsWriter.running = true
    }

    Process { id: settingsWriter }

    Process {
        id: settingsReader
        command: ["bash", "-c", "cat " + root.settingsPath + " 2>/dev/null || echo '{}'"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var s = JSON.parse(data)
                    if (s.barPosition) {
                        // eski kayitlar (top / bottom / isimler) -> sol
                        var legacy = { "Luna": "left", "Sway": "left", "Yuna": "left", "Cyan": "left", "top": "left", "bottom": "left" }
                        var side = legacy[s.barPosition] || s.barPosition
                        if (["left", "right", "both"].indexOf(side) >= 0) root.barPosition = side
                    }
                    if (s.musicStyle)  root.selectedMusic = s.musicStyle
                    if (s.photoPath !== undefined) root.photoPath  = s.photoPath
                    if (s.photoShape)  root.photoShape = s.photoShape
                    if (s.photoEnabled !== undefined) root.photoEnabled = s.photoEnabled
                    if (s.dockEnabled !== undefined)   root.dockEnabled   = s.dockEnabled
                    if (Array.isArray(s.dockFavorites)) root.dockFavorites = s.dockFavorites
                    if (s.clockX !== undefined)      root.clockX      = s.clockX
                    if (s.clockY !== undefined)      root.clockY      = s.clockY
                    if (s.clockScale !== undefined)  root.clockScale  = s.clockScale
                    if (s.photoX !== undefined)      root.photoX      = s.photoX
                    if (s.photoY !== undefined)      root.photoY      = s.photoY
                    if (s.photoScale !== undefined)  root.photoScale  = s.photoScale
                } catch(e) {}
            }
        }
        Component.onCompleted: running = true
    }

    WMService { id: wmService }

    property bool fullscreenActive: wmService.isNiri ? wmService.fullscreenActive : hyprFullscreenActive
    property bool hyprFullscreenActive: false

    Process {
        id: hyprEventListener
        command: ["bash", "-c",
            "socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"]
        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("fullscreen>>")) {
                    root.hyprFullscreenActive = data.trim().endsWith(">>1")
                }
            }
        }
        Component.onCompleted: { if (!wmService.isNiri) running = true }
        onExited: (code, status) => { if (!wmService.isNiri) restartTimer.start() } // socat düşerse tekrar bağlan
    }
    Timer {
        id: restartTimer
        interval: 2000; repeat: false
        onTriggered: hyprEventListener.running = true
    }

    readonly property string configPath: Quickshell.env("HOME") + "/.config/quickshell/vv"
    readonly property string compPath:   configPath + "/components"

    QtObject {
        id: zyuTheme
        property bool floating_feel: true
        property color bar_bg:    "#000000"
        property color bar_fg:    "#ffffff"
        property color accent:    "#ffffff"
        property color widget_bg: "#1a1a1a"
        property int bar_height: 50
        property int rounding:   15
        property font mainFont: Qt.font({family: "JetBrainsMono Nerd Font", pixelSize: 14, bold: true})
    }
    // tab: "home" | "wifi" | "bt" | "ai" | "me"  (Bar dugmeleri buradan sekme secer)
    QtObject { id: dashboardState; property bool show: false; property string tab: "home" }
    QtObject { id: logoutState;    property bool show: false }
    QtObject { id: settingsState;  property bool show: false }

    IpcHandler {
        target: "settings"
        function toggle(): void {
            settingsState.show = !settingsState.show
        }
        function open(): void {
            settingsState.show = true
        }
        function close(): void {
            settingsState.show = false
        }
    }

    Process {
        id: colorProc
        command: ["bash", "-c", "cat " + configPath + "/Colors/colors.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var c = JSON.parse(data)
                    if (c.background)        zyuTheme.bar_bg    = c.background
                    if (c.on_surface)        zyuTheme.bar_fg    = c.on_surface
                    if (c.primary)           zyuTheme.accent    = c.primary
                    if (c.surface_container) zyuTheme.widget_bg = c.surface_container
                } catch(e) {}
            }
        }
        Component.onCompleted: running = true
    }

    Loader { source: compPath + "/Bar/Sway.qml" }
    Loader { source: compPath + "/Arcana/Sway.qml" }
    Loader { source: compPath + "/Settings/Settings.qml" }
    Loader { source: compPath + "/Music/" + root.selectedMusic + ".qml" }
    // Wi-Fi / Bluetooth / AI artik Arcana icinde sekme (eski popup dosyalari yerinde duruyor, yuklenmiyor)
    Loader { source: compPath + "/Wall/Luna.qml" }
    Loader { source: compPath + "/Clock.qml" }
    Loader { source: compPath + "/PhotoFrame.qml" }
    Loader { source: compPath + "/Dock/Dock.qml" }
}

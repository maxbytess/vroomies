import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris

// Yan bar. Settings > Appearance'dan: "left", "right" ya da "both" (her iki yanda bir bar).
// "both" modunda sol bar: saat + workspace'ler, sag bar: muzik + dugmeler.
Variants {
    model: {
        var out = []
        var sides = root.barPosition === "both" ? ["left", "right"] : [root.barPosition]
        for (var i = 0; i < Quickshell.screens.length; i++)
            for (var j = 0; j < sides.length; j++)
                out.push({ screen: Quickshell.screens[i], side: sides[j] })
        return out
    }

    PanelWindow {
        id: barWindow
        required property var modelData
        screen: modelData.screen

        readonly property string pos: modelData.side
        readonly property bool vertical: true
        readonly property int thickness: root.barThickness
        readonly property bool both: root.barPosition === "both"
        readonly property bool showNav:    !both || pos === "left"     // saat + workspace
        readonly property bool showStatus: !both || pos === "right"    // muzik + dugmeler

        anchors {
            top:    true
            bottom: true
            left:   pos === "left"
            right:  pos === "right"
        }
        implicitWidth:  thickness
        implicitHeight: 0
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusiveZone: thickness

        visible: {
            if (wmService.isNiri) {
                return wmService.focusedWorkspaceId > 0
            }
            const activeWs = Hyprland.focusedMonitor?.activeWorkspace
            return activeWs ? activeWs.id > 0 : true
        }

        // shell.qml disinda calisan ayri process'ler (Launcher, Lock) root'a
        // erisemiyor; yonu "yon:kalinlik" seklinde kucuk bir dosyaya da yaziyoruz.
        Process { id: writeBarState }
        function writeState() {
            writeBarState.command = ["bash", "-c",
                "mkdir -p " + Quickshell.env("HOME") + "/.config/quickshell/vv/state && echo -n '" +
                root.barPosition + ":" + root.barThickness + "' > " +
                Quickshell.env("HOME") + "/.config/quickshell/vv/state/bar-position"]
            writeBarState.running = true
        }
        Component.onCompleted: writeState()
        Connections {
            target: root
            function onBarPositionChanged() { barWindow.writeState() }
        }

        function isActive(key) {
            if (key === "wifi" || key === "bt" || key === "ai" || key === "me")
                return typeof dashboardState !== 'undefined' && dashboardState.show && dashboardState.tab === key
            if (key === "wall")     return root.wallVisible
            if (key === "settings") return settingsState.show
            if (key === "dash")     return typeof dashboardState !== 'undefined' && dashboardState.show
            return false
        }

        // Wi-Fi / Bluetooth / AI / Me artik Arcana dashboard'unda sekme
        function openDash(tab) {
            if (typeof dashboardState === 'undefined') return
            if (dashboardState.show && dashboardState.tab === tab) { dashboardState.show = false; return }
            dashboardState.tab = tab
            dashboardState.show = true
        }

        function trigger(key) {
            if (key === "wifi" || key === "bt" || key === "ai" || key === "me") openDash(key)
            else if (key === "wall")     root.wallVisible = !root.wallVisible
            else if (key === "settings") settingsState.show = !settingsState.show
            else if (key === "dash" && typeof dashboardState !== 'undefined') dashboardState.show = !dashboardState.show
        }

        readonly property bool hasMusic: {
            var players = Mpris.players.values
            if (!players || players.length === 0) return false
            for (var i = 0; i < players.length; i++) {
                if (players[i].playbackState === MprisPlaybackState.Playing ||
                    players[i].playbackState === MprisPlaybackState.Paused) return true
            }
            return false
        }

        readonly property var activePlayer: {
            var players = Mpris.players.values
            if (!players || players.length === 0) return null
            for (var i = 0; i < players.length; i++) {
                if (players[i].playbackState === MprisPlaybackState.Playing) return players[i]
            }
            return players.length > 0 ? players[0] : null
        }

        Rectangle {
            id: barBg
            anchors.fill: parent
            color: zyuTheme.bar_bg
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: 0
            bottomRightRadius: 0
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        GridLayout {
            id: content
            anchors.fill: parent
            anchors.leftMargin:   barWindow.vertical ? 0 : 16
            anchors.rightMargin:  barWindow.vertical ? 0 : 16
            anchors.topMargin:    barWindow.vertical ? 14 : 0
            anchors.bottomMargin: barWindow.vertical ? 14 : 0
            flow: barWindow.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
            columns: barWindow.vertical ? 1 : 64
            rows:    barWindow.vertical ? 64 : 1
            columnSpacing: 12
            rowSpacing: 12

            // ---- Saat ----
            GridLayout {
                visible: barWindow.showNav
                Layout.alignment: barWindow.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
                flow: barWindow.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                columns: barWindow.vertical ? 1 : 64
                rows:    barWindow.vertical ? 64 : 1
                columnSpacing: 4
                rowSpacing: 0

                Text {
                    id: hourText
                    Layout.alignment: Qt.AlignHCenter
                    color: zyuTheme.bar_fg
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13; font.bold: true
                    function updateTime() { text = new Date().getHours().toString().padStart(2, '0') }
                    Component.onCompleted: updateTime()
                }
                Text {
                    visible: !barWindow.vertical
                    text: ":"; color: zyuTheme.accent; font.bold: true; font.pixelSize: 13
                }
                Text {
                    id: minText
                    Layout.alignment: Qt.AlignHCenter
                    color: zyuTheme.accent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13; font.bold: true
                    function updateTime() { text = new Date().getMinutes().toString().padStart(2, '0') }
                    Component.onCompleted: updateTime()
                }
                Timer {
                    interval: 30000; running: true; repeat: true
                    onTriggered: { hourText.updateTime(); minText.updateTime() }
                }
            }

            Rectangle {
                visible: barWindow.showNav
                Layout.alignment: barWindow.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
                Layout.preferredWidth:  barWindow.vertical ? 16 : 1
                Layout.preferredHeight: barWindow.vertical ? 1 : 16
                color: Qt.rgba(1, 1, 1, 0.07)
            }

            // ---- Workspace'ler ----
            GridLayout {
                visible: barWindow.showNav
                Layout.alignment: barWindow.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
                flow: barWindow.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                columns: barWindow.vertical ? 1 : 64
                rows:    barWindow.vertical ? 64 : 1
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: wmService.isNiri ? wmService.workspaces : Hyprland.workspaces
                    delegate: Item {
                        required property var modelData
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        visible: modelData.id > 0
                        property bool isActive: wmService.isNiri
                            ? modelData.id === wmService.focusedWorkspaceId
                            : modelData.id === Hyprland.focusedMonitor?.activeWorkspace?.id

                        Rectangle {
                            anchors.centerIn: parent
                            width: isActive ? 12 : 0; height: width; radius: 3
                            color: "transparent"; border.width: 2; border.color: zyuTheme.accent
                            rotation: 45; opacity: isActive ? 1.0 : 0.0
                            Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: isActive ? 0 : 4; height: width; radius: 2
                            color: zyuTheme.bar_fg; opacity: isActive ? 0.0 : 0.28
                            Behavior on width { NumberAnimation { duration: 250 } }
                        }

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: wmService.isNiri
                                ? wmService.focusWorkspace(modelData.id)
                                : Hyprland.dispatch("workspace " + modelData.id)
                        }
                    }
                }
            }

            // ---- Bosluk ----
            Item {
                Layout.fillWidth:  !barWindow.vertical
                Layout.fillHeight: barWindow.vertical
            }

            // ---- Calan muzik ----
            GridLayout {
                Layout.alignment: barWindow.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
                visible: barWindow.hasMusic && barWindow.showStatus
                flow: barWindow.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                columns: barWindow.vertical ? 1 : 64
                rows:    barWindow.vertical ? 64 : 1
                columnSpacing: 8
                rowSpacing: 8

                Rectangle {
                    Layout.preferredWidth: 32; Layout.preferredHeight: 32
                    radius: 8
                    color: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.1)
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: barWindow.activePlayer ? (barWindow.activePlayer.trackArtUrl || "") : ""
                        fillMode: Image.PreserveAspectCrop
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.musicVisible = !root.musicVisible }
                }

                Column {
                    visible: !barWindow.vertical
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                        width: Math.min(implicitWidth, 220)
                        elide: Text.ElideRight
                        text: barWindow.activePlayer ? (barWindow.activePlayer.trackTitle || "") : ""
                        color: zyuTheme.bar_fg; font.pixelSize: 11; font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        width: Math.min(implicitWidth, 220)
                        elide: Text.ElideRight
                        text: barWindow.activePlayer ? (barWindow.activePlayer.trackArtist || "") : ""
                        color: zyuTheme.bar_fg; font.pixelSize: 9; opacity: 0.4
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }
            }

            // ---- Ikonlar ----
            GridLayout {
                visible: barWindow.showStatus
                Layout.alignment: barWindow.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
                flow: barWindow.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                columns: barWindow.vertical ? 1 : 64
                rows:    barWindow.vertical ? 64 : 1
                columnSpacing: 4
                rowSpacing: 4

                Repeater {
                    model: [
                        { key: "wifi",     glyph: "󰤨" },
                        { key: "dash",     glyph: "󰕮" },
                        { key: "wall",     glyph: "󰸉" },
                        { key: "bt",       glyph: "󰂯" },
                        { key: "ai",       glyph: "󰚩" },
                        { key: "me",       glyph: "♥" },
                        { key: "settings", glyph: "󰢻" }
                    ]
                    delegate: Item {
                        id: iconBtn
                        required property var modelData
                        readonly property bool active: barWindow.isActive(modelData.key)
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36

                        Rectangle {
                            anchors.centerIn: parent
                            width: ma.containsMouse || iconBtn.active ? 32 : 0; height: width; radius: 8
                            color: iconBtn.active ? Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.18) : Qt.rgba(1, 1, 1, 0.07)
                            Behavior on width { NumberAnimation { duration: 180 } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: iconBtn.modelData.glyph
                            font.pixelSize: 16
                            font.family: "JetBrainsMono Nerd Font"
                            color: iconBtn.active ? zyuTheme.accent
                                : Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, ma.containsMouse ? 0.8 : 0.4)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: barWindow.trigger(iconBtn.modelData.key)
                        }
                    }
                }
            }
        }
    }
}

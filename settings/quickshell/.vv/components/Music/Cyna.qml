import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: musicPanel

    readonly property int loopNone:     MprisLoopStatus.None
    readonly property int loopTrack:    MprisLoopStatus.Track
    readonly property int loopPlaylist: MprisLoopStatus.Playlist

    visible: true
    exclusionMode: ExclusionMode.Ignore
    // Her zaman asagida acilir (bar yonunden bagimsiz).
    anchors { bottom: true; left: true; right: true }
    margins {
        bottom: root.musicVisible ? ((root.barPosition === "bottom" ? root.barThickness + 10 : 14) + (root.dockEnabled ? Math.max(root.dockHeight, root.dockPillHeight) + 12 : 0)) : -250
    }
    Behavior on margins.bottom { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    implicitHeight: 230
    color: "transparent"
    focusable: false
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property bool expanded: false

    readonly property var player: {
        var players = Mpris.players.values
        if (!players || players.length === 0) return null
        for (var i = 0; i < players.length; i++) {
            if (players[i].isPlaying) return players[i]
        }
        return players[0]
    }

    readonly property bool hasTrack:      player !== null && (player.playbackState === MprisPlaybackState.Playing || player.playbackState === MprisPlaybackState.Paused)
    readonly property bool isPlaying:     player !== null && player.playbackState === MprisPlaybackState.Playing
    readonly property string trackTitle:  player ? (player.trackTitle  || "") : ""
    readonly property string trackArtist: player ? (player.trackArtist || "") : ""
    readonly property string artUrl:      player ? (player.trackArtUrl || "") : ""
    readonly property real trackLength:   player ? (player.length || 0) : 0
    property real trackPosition: 0

    function formatTime(seconds) {
        if (seconds < 0 || isNaN(seconds)) return "0:00"
        var mins = Math.floor(seconds / 60)
        var secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    Timer {
        interval: 1000
        running: root.musicVisible && musicPanel.isPlaying
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (musicPanel.player) {
                musicPanel.player.positionChanged()
                musicPanel.trackPosition = musicPanel.player.position
            }
        }
    }

    Timer {
        id: collapseTimer
        interval: 150
        repeat: false
        onTriggered: musicPanel.expanded = false
    }

    Item {
        id: chip
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        width: musicPanel.expanded ? 320 : 252
        height: musicPanel.expanded ? 212 : 56

        Behavior on width  { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }
        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }

        Rectangle {
            id: shell
            anchors.fill: parent
            radius: musicPanel.expanded ? 24 : height / 2
            color: zyuTheme.bar_bg
            border.width: 1
            border.color: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.22)
            clip: true

            Behavior on radius { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: { collapseTimer.stop(); musicPanel.expanded = true }
                onExited: collapseTimer.start()
            }

            // ---- Daraltilmis pill icerigi ----
            RowLayout {
                id: collapsedRow
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 10
                opacity: musicPanel.expanded ? 0 : 1
                visible: opacity > 0.02
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Item {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40

                    Rectangle {
                        id: coverBg
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.18)
                        visible: false
                    }

                    Image {
                        id: coverImg
                        anchors.fill: parent
                        source: musicPanel.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        visible: false
                    }

                    Rectangle {
                        id: coverMask
                        anchors.fill: parent
                        radius: width / 2
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: musicPanel.artUrl !== "" ? coverImg : coverBg
                        maskSource: coverMask
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: musicPanel.artUrl === ""
                        text: "󰝚"
                        color: zyuTheme.accent
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Item {
                        id: titleClip
                        Layout.fillWidth: true
                        Layout.preferredHeight: titleText.implicitHeight
                        clip: true

                        Text {
                            id: titleText
                            text: musicPanel.hasTrack ? musicPanel.trackTitle : "Not playing"
                            color: zyuTheme.bar_fg
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true

                            readonly property real overflow: Math.max(0, implicitWidth - titleClip.width)
                            onTextChanged: x = 0

                            SequentialAnimation on x {
                                running: titleText.overflow > 0 && !musicPanel.expanded
                                loops: Animation.Infinite
                                PauseAnimation { duration: 1200 }
                                NumberAnimation { to: -titleText.overflow; duration: Math.max(1200, titleText.overflow * 18); easing.type: Easing.Linear }
                                PauseAnimation { duration: 900 }
                                NumberAnimation { to: 0; duration: Math.max(800, titleText.overflow * 18); easing.type: Easing.Linear }
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: musicPanel.hasTrack
                        text: musicPanel.trackArtist
                        color: zyuTheme.bar_fg; opacity: 0.6
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 17
                    color: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.20)

                    Text {
                        anchors.centerIn: parent
                        text: musicPanel.isPlaying ? "󰏤" : "󰐊"
                        color: zyuTheme.accent
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (musicPanel.player) musicPanel.player.togglePlaying()
                    }
                }
            }

            // ---- Uzerine gelince acilan genisletilmis panel ----
            ColumnLayout {
                id: expandedCol
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10
                opacity: musicPanel.expanded ? 1 : 0
                visible: opacity > 0.02
                Behavior on opacity { NumberAnimation { duration: 200 } }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Item {
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 56

                        Rectangle {
                            id: coverBg2
                            anchors.fill: parent
                            radius: width / 2
                            color: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.18)
                            visible: false
                        }
                        Image {
                            id: coverImg2
                            anchors.fill: parent
                            source: musicPanel.artUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                            visible: false
                        }
                        Rectangle {
                            id: coverMask2
                            anchors.fill: parent
                            radius: width / 2
                            visible: false
                        }
                        OpacityMask {
                            anchors.fill: parent
                            source: musicPanel.artUrl !== "" ? coverImg2 : coverBg2
                            maskSource: coverMask2
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: musicPanel.artUrl === ""
                            text: "󰝚"; color: zyuTheme.accent
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: musicPanel.hasTrack ? musicPanel.trackTitle : "Nothing playing"
                            color: zyuTheme.bar_fg; font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14; font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: musicPanel.trackArtist
                            color: zyuTheme.bar_fg; opacity: 0.6
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.topMargin: 4
                            spacing: 3
                            Repeater {
                                model: 13
                                delegate: Rectangle {
                                    required property int index
                                    width: 3; radius: 1.5
                                    color: zyuTheme.accent
                                    opacity: musicPanel.isPlaying ? 0.85 : 0.22
                                    height: 4

                                    SequentialAnimation on height {
                                        running: musicPanel.isPlaying
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 4 + Math.random() * 13; duration: 260 + Math.random() * 260; easing.type: Easing.InOutSine }
                                        NumberAnimation { to: 3 + Math.random() * 4;  duration: 260 + Math.random() * 260; easing.type: Easing.InOutSine }
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4; radius: 2
                        color: Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.15)

                        Rectangle {
                            height: parent.height; radius: 2
                            color: zyuTheme.accent
                            width: musicPanel.trackLength > 0
                                ? parent.width * Math.min(1, musicPanel.trackPosition / musicPanel.trackLength)
                                : 0
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                if (!musicPanel.player || musicPanel.trackLength <= 0) return
                                const ratio = Math.max(0, Math.min(1, mouse.x / width))
                                musicPanel.player.position = ratio * musicPanel.trackLength
                                musicPanel.trackPosition = musicPanel.player.position
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: musicPanel.formatTime(musicPanel.trackPosition)
                            color: zyuTheme.bar_fg; opacity: 0.5
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: musicPanel.formatTime(musicPanel.trackLength)
                            color: zyuTheme.bar_fg; opacity: 0.5
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20

                    Text {
                        text: "󰒞"
                        color: (musicPanel.player && musicPanel.player.shuffle)
                            ? zyuTheme.accent : Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.45)
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (musicPanel.player) musicPanel.player.shuffle = !musicPanel.player.shuffle
                        }
                    }

                    Text {
                        text: "󰒮"
                        color: zyuTheme.bar_fg
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (musicPanel.player) musicPanel.player.previous()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 36; Layout.preferredHeight: 36; radius: 18
                        color: zyuTheme.accent
                        Text {
                            anchors.centerIn: parent
                            text: musicPanel.isPlaying ? "󰏤" : "󰐊"
                            color: zyuTheme.bar_bg
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (musicPanel.player) musicPanel.player.togglePlaying()
                        }
                    }

                    Text {
                        text: "󰒭"
                        color: zyuTheme.bar_fg
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (musicPanel.player) musicPanel.player.next()
                        }
                    }

                    Text {
                        text: (musicPanel.player && musicPanel.player.loopStatus === musicPanel.loopTrack) ? "󰑘"
                            : (musicPanel.player && musicPanel.player.loopStatus === musicPanel.loopPlaylist) ? "󰑖" : "󰑗"
                        color: (musicPanel.player && musicPanel.player.loopStatus !== musicPanel.loopNone)
                            ? zyuTheme.accent : Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.45)
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!musicPanel.player) return
                                if (musicPanel.player.loopStatus === musicPanel.loopNone)
                                    musicPanel.player.loopStatus = musicPanel.loopTrack
                                else if (musicPanel.player.loopStatus === musicPanel.loopTrack)
                                    musicPanel.player.loopStatus = musicPanel.loopPlaylist
                                else
                                    musicPanel.player.loopStatus = musicPanel.loopNone
                            }
                        }
                    }
                }
            }
        }
    }
}

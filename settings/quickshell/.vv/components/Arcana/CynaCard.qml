import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: musicPanel
    required property var th
    property bool active: false

    readonly property int loopNone:     MprisLoopStatus.None
    readonly property int loopTrack:    MprisLoopStatus.Track
    readonly property int loopPlaylist: MprisLoopStatus.Playlist
    readonly property string nf: "JetBrainsMono Nerd Font"

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
    readonly property real cover: Math.max(44, Math.min(84, height * 0.36))

    function formatTime(seconds) {
        if (seconds < 0 || isNaN(seconds)) return "0:00"
        var mins = Math.floor(seconds / 60)
        var secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }
    function icon(cp) { return String.fromCodePoint(cp) }
    function dim(a) { return Qt.rgba(th.fg.r, th.fg.g, th.fg.b, a) }

    Timer {
        interval: 1000
        running: musicPanel.active && musicPanel.isPlaying
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (musicPanel.player) {
                musicPanel.player.positionChanged()
                musicPanel.trackPosition = musicPanel.player.position
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Item {
                Layout.preferredWidth: musicPanel.cover
                Layout.preferredHeight: musicPanel.cover

                Rectangle {
                    id: coverBg
                    anchors.fill: parent; radius: width / 2
                    color: Qt.rgba(musicPanel.th.accent.r, musicPanel.th.accent.g, musicPanel.th.accent.b, 0.18)
                    visible: false
                }
                Image {
                    id: coverImg
                    anchors.fill: parent
                    source: musicPanel.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true; smooth: true
                    sourceSize.width: 168; sourceSize.height: 168
                    visible: false
                }
                Rectangle { id: coverMask; anchors.fill: parent; radius: width / 2; visible: false }
                OpacityMask {
                    anchors.fill: parent
                    source: musicPanel.artUrl !== "" ? coverImg : coverBg
                    maskSource: coverMask
                }
                Text {
                    anchors.centerIn: parent
                    visible: musicPanel.artUrl === ""
                    text: musicPanel.icon(0xF075A)
                    color: musicPanel.th.accent
                    font.family: musicPanel.nf; font.pixelSize: musicPanel.cover * 0.36
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: musicPanel.hasTrack ? musicPanel.trackTitle : "Nothing playing"
                    color: musicPanel.th.fg
                    font.family: musicPanel.nf; font.pixelSize: 14; font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: musicPanel.trackArtist
                    color: musicPanel.dim(0.6)
                    font.family: musicPanel.nf; font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 0 }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: musicPanel.formatTime(musicPanel.trackPosition)
                color: musicPanel.dim(0.5)
                font.family: musicPanel.nf; font.pixelSize: 9
            }
            Rectangle {
                Layout.fillWidth: true
                height: 4; radius: 2
                color: musicPanel.dim(0.15)
                Rectangle {
                    height: parent.height; radius: 2
                    color: musicPanel.th.accent
                    width: musicPanel.trackLength > 0
                        ? parent.width * Math.min(1, musicPanel.trackPosition / musicPanel.trackLength) : 0
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.topMargin: -7; anchors.bottomMargin: -7
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        if (!musicPanel.player || musicPanel.trackLength <= 0) return
                        const ratio = Math.max(0, Math.min(1, mouse.x / width))
                        musicPanel.player.position = ratio * musicPanel.trackLength
                        musicPanel.trackPosition = musicPanel.player.position
                    }
                }
            }
            Text {
                text: musicPanel.formatTime(musicPanel.trackLength)
                color: musicPanel.dim(0.5)
                font.family: musicPanel.nf; font.pixelSize: 9
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 22

            Text {
                text: musicPanel.icon(0xF049E)
                color: (musicPanel.player && musicPanel.player.shuffle) ? musicPanel.th.accent : musicPanel.dim(0.45)
                font.family: musicPanel.nf; font.pixelSize: 15
                MouseArea {
                    anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                    onClicked: if (musicPanel.player) musicPanel.player.shuffle = !musicPanel.player.shuffle
                }
            }
            Text {
                text: musicPanel.icon(0xF04AE)
                color: musicPanel.th.fg
                font.family: musicPanel.nf; font.pixelSize: 18
                MouseArea {
                    anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                    onClicked: if (musicPanel.player) musicPanel.player.previous()
                }
            }
            Rectangle {
                Layout.preferredWidth: 38; Layout.preferredHeight: 38; radius: 19
                color: musicPanel.th.accent
                Text {
                    anchors.centerIn: parent
                    text: musicPanel.isPlaying ? musicPanel.icon(0xF03E4) : musicPanel.icon(0xF040A)
                    color: musicPanel.th.bg
                    font.family: musicPanel.nf; font.pixelSize: 16
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: if (musicPanel.player) musicPanel.player.togglePlaying()
                }
            }
            Text {
                text: musicPanel.icon(0xF04AD)
                color: musicPanel.th.fg
                font.family: musicPanel.nf; font.pixelSize: 18
                MouseArea {
                    anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                    onClicked: if (musicPanel.player) musicPanel.player.next()
                }
            }
            Text {
                text: (musicPanel.player && musicPanel.player.loopStatus === musicPanel.loopTrack) ? musicPanel.icon(0xF0458)
                    : (musicPanel.player && musicPanel.player.loopStatus === musicPanel.loopPlaylist) ? musicPanel.icon(0xF0456) : musicPanel.icon(0xF0457)
                color: (musicPanel.player && musicPanel.player.loopStatus !== musicPanel.loopNone) ? musicPanel.th.accent : musicPanel.dim(0.45)
                font.family: musicPanel.nf; font.pixelSize: 15
                MouseArea {
                    anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!musicPanel.player) return
                        if (musicPanel.player.loopStatus === musicPanel.loopNone)       musicPanel.player.loopStatus = musicPanel.loopTrack
                        else if (musicPanel.player.loopStatus === musicPanel.loopTrack) musicPanel.player.loopStatus = musicPanel.loopPlaylist
                        else                                                           musicPanel.player.loopStatus = musicPanel.loopNone
                    }
                }
            }
        }
    }
}

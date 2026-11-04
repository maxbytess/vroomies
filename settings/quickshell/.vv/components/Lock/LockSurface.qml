import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    required property LockContext context

    color: root.bg

    // Tum renkler matugen colors.json'dan (zyuTheme ile ayni kaynak) gelir;
    // eksik anahtarlar accent'ten turetilir.
    property var theme: ({})
    property color accent: "#6750a4"

    function mix(c1, c2, t) {
        return Qt.rgba(c1.r + (c2.r - c1.r) * t,
                       c1.g + (c2.g - c1.g) * t,
                       c1.b + (c2.b - c1.b) * t,
                       c1.a + (c2.a - c1.a) * t)
    }
    function luminance(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function hasColor(key) { return root.theme[key] !== undefined && root.theme[key] !== null }

    // Ana shell'deki zyuTheme eslesmesi: bar_bg / widget_bg / bar_fg / accent
    readonly property color bg: hasColor("background") ? root.theme.background : Qt.darker(accent, 4.5)
    readonly property color surf: hasColor("surface_container") ? root.theme.surface_container : mix(accent, bg, 0.78)
    // Eskiden Qt.lighter(accent, 2.2) vardi -> acik temalarda kart beyaz gibi oluyordu.
    readonly property color cardBg: mix(surf, accent, 0.30)
    // Yazi rengi: matugen on_surface; yoksa kart kontrastindan otomatik secilir.
    readonly property color ink: hasColor("on_surface") ? root.theme.on_surface
        : (luminance(cardBg) > 0.45 ? mix(accent, "#000000", 0.82) : "#e9e4f2")
    readonly property color mutedInk: hasColor("on_surface_variant")
        ? root.theme.on_surface_variant : mix(ink, bg, 0.45)
    readonly property color errColor: hasColor("error") ? root.theme.error : "#f38ba8"
    readonly property string userName: Quickshell.env("USER") || "user"
    readonly property string displayName: userName.charAt(0).toUpperCase() + userName.slice(1)
    readonly property real shapeSize: Math.min(height * 0.58, 540)

    function tone(offset) {
        var h = accent.hslHue < 0 ? 0.75 : accent.hslHue
        return Qt.hsla((h + offset + 1) % 1, Math.max(0.6, accent.hslSaturation), 0.62, 1)
    }
    readonly property var palette: hasColor("secondary") && hasColor("tertiary")
        ? [root.theme.primary, root.theme.secondary, root.theme.tertiary,
           root.theme.primary, hasColor("error") ? root.theme.error : tone(0.14), root.theme.secondary]
        : [tone(0), tone(0.07), tone(-0.07), tone(0.14), tone(-0.14), tone(0.21)]

    function cookiePoints(size) {
        var pts = []
        var c = size / 2, R = size / 2 * 0.93
        for (var i = 0; i <= 240; i++) {
            var t = i / 240 * Math.PI * 2
            var r = R * (1 + 0.07 * Math.cos(9 * t))
            pts.push(Qt.point(c + r * Math.cos(t), c + r * Math.sin(t)))
        }
        return pts
    }

    Process {
        id: colorProc
        command: ["bash", "-c", "cat " + Quickshell.env("HOME") + "/.config/quickshell/vv/Colors/colors.json 2>/dev/null"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var c = JSON.parse(data)
                    root.theme = c
                    if (c.primary) root.accent = c.primary
                } catch (e) {}
            }
        }
    }

    property string wallPath: ""
    property int wallTries: 0
    Process {
        id: wallProc
        command: ["bash", "-c", "readlink -f \"$HOME/.config/hypr/current_wallpaper\" 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => { var p = data.trim(); if (p.length > 0) root.wallPath = p }
        }
    }
    Timer {
        interval: 700
        repeat: true
        running: wallpaperImg.status !== Image.Ready && root.wallTries < 10
        onTriggered: {
            root.wallTries++
            wallProc.running = true
            if (wallpaperImg.status === Image.Error) {
                var s = wallpaperImg.source
                wallpaperImg.source = ""
                wallpaperImg.source = s
            }
        }
    }

    property string avatarPath: ""
    Process {
        id: avatarProc
        command: ["bash", "-c",
            "cfg=\"$HOME/.config/quickshell/vv\"; f=$(cat \"$cfg/state/profile-picture\" 2>/dev/null); " +
            "if [ ! -f \"$f\" ]; then f=$(ls -t \"$cfg/components/assets/pp/\"*.jpg \"$cfg/components/assets/pp/\"*.png " +
            "\"$cfg/components/assets/pp/\"*.gif 2>/dev/null | head -1); fi; " +
            "[ -n \"$f\" ] && echo \"$f\" || echo \"$HOME/.face\""]
        stdout: SplitParser {
            onRead: data => { var f = data.trim(); if (f.length > 0) root.avatarPath = f }
        }
    }

    property int batteryPct: -1
    Process {
        id: batProc
        command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1"]
        stdout: SplitParser {
            onRead: data => { var n = parseInt(data.trim()); root.batteryPct = isNaN(n) ? -1 : n }
        }
    }
    Timer { interval: 30000; repeat: true; running: true; onTriggered: batProc.running = true }

    readonly property var player: {
        var ps = Mpris.players.values
        if (!ps || ps.length === 0) return null
        for (var i = 0; i < ps.length; i++) {
            if (ps[i].playbackState === MprisPlaybackState.Playing) return ps[i]
        }
        return ps[0]
    }
    readonly property bool isPlaying: player !== null && player.playbackState === MprisPlaybackState.Playing
    readonly property bool hasTrack: player !== null && (isPlaying || player.playbackState === MprisPlaybackState.Paused)

    Component.onCompleted: {
        colorProc.running = true
        wallProc.running = true
        avatarProc.running = true
        batProc.running = true
    }

    MouseArea { anchors.fill: parent; onClicked: pwInput.forceActiveFocus() }

    Row {
        visible: root.batteryPct >= 0
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 28
        spacing: 6
        Text {
            text: "󰁹"
            color: root.batteryPct <= 15 ? "#f38ba8" : root.ink
            font.family: "Monocraft Nerd Font"; font.pixelSize: 16
        }
        Text {
            text: root.batteryPct + "%"
            color: root.ink
            font.family: "Monocraft Nerd Font"; font.pixelSize: 11
        }
    }

    ColumnLayout {
        id: centerBlock
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.height * 0.01
        spacing: 12

        opacity: 0
        scale: 0.92
        Component.onCompleted: enterAnim.start()
        ParallelAnimation {
            id: enterAnim
            NumberAnimation { target: centerBlock; property: "opacity"; to: 1; duration: 420; easing.type: Easing.OutCubic }
            NumberAnimation { target: centerBlock; property: "scale"; to: 1; duration: 520; easing.type: Easing.OutBack }
        }

        Item {
            id: wallBox
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.shapeSize
            Layout.preferredHeight: root.shapeSize

            Shape {
                id: cookieShape
                anchors.fill: parent
                visible: false
                NumberAnimation on rotation { from: 0; to: 360; duration: 90000; loops: Animation.Infinite; running: true }
                ShapePath {
                    fillColor: "#000000"
                    strokeWidth: -1
                    PathPolyline { path: root.cookiePoints(wallBox.width) }
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: wallBox.width * 0.04
                radius: width / 2
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
                visible: wallpaperImg.status !== Image.Ready
            }

            Image {
                id: wallpaperImg
                anchors.fill: parent
                source: root.wallPath !== "" ? "file://" + encodeURI(root.wallPath) : ""
                sourceSize: Qt.size(root.shapeSize * 2, root.shapeSize * 2)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                visible: status === Image.Ready
                layer.enabled: true
                layer.effect: OpacityMask { maskSource: cookieShape }
            }
        }

        // Saat: cookie'nin altinda, yatay H:M, temiz zemin
        Column {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 18
            spacing: 2

            Text {
                id: clock
                property var date: new Date()
                text: date.getHours() + ":" + date.getMinutes().toString().padStart(2, '0')
                color: root.ink
                font.family: "Monocraft Nerd Font"
                font.pixelSize: 44
                font.bold: true
                Timer { running: true; repeat: true; interval: 1000; onTriggered: clock.date = new Date() }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: clock.date.toLocaleDateString(Qt.locale(), "dddd, d MMMM")
                color: root.mutedInk
                font.family: "Monocraft Nerd Font"
                font.pixelSize: 11
            }
        }

        Item {
            id: avatarBox
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 14
            Layout.preferredWidth: 76
            Layout.preferredHeight: 76

            Rectangle { anchors.fill: parent; radius: width / 2; color: root.cardBg }

            Item {
                anchors.fill: parent
                anchors.margins: 4

                Rectangle { id: avatarMask; anchors.fill: parent; radius: width / 2; visible: false }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: root.palette[0]
                    visible: avatarImg.status !== Image.Ready
                    Text {
                        anchors.centerIn: parent
                        text: root.displayName.charAt(0)
                        color: root.ink
                        font.family: "Monocraft Nerd Font"
                        font.pixelSize: 26; font.bold: true
                    }
                }
                Image {
                    id: avatarImg
                    anchors.fill: parent
                    source: root.avatarPath !== "" ? "file://" + encodeURI(root.avatarPath) : ""
                    sourceSize: Qt.size(152, 152)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                    layer.enabled: true
                    layer.effect: OpacityMask { maskSource: avatarMask }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.displayName
            color: root.ink
            font.family: "Monocraft Nerd Font"
            font.pixelSize: 18; font.bold: true
        }

        Rectangle {
            id: pwField
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 14
            Layout.preferredWidth: 360
            Layout.preferredHeight: 52
            radius: 26
            color: root.cardBg
            border.width: 2
            border.color: root.context.showFailure ? root.errColor
                : (pwInput.activeFocus ? root.palette[0] : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.4))
            Behavior on border.color { ColorAnimation { duration: 150 } }

            property int shakeTrigger: 0
            onShakeTriggerChanged: shakeAnim.start()
            transform: Translate { id: shakeTranslate; x: 0 }
            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: shakeTranslate; property: "x"; to: -10; duration: 45 }
                NumberAnimation { target: shakeTranslate; property: "x"; to: 10;  duration: 45 }
                NumberAnimation { target: shakeTranslate; property: "x"; to: -6;  duration: 45 }
                NumberAnimation { target: shakeTranslate; property: "x"; to: 0;   duration: 45 }
            }

            TextInput {
                id: pwInput
                width: 1; height: 1
                opacity: 0
                focus: true
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData
                enabled: !root.context.unlockInProgress
                onTextChanged: root.context.currentText = text
                onAccepted: root.context.tryUnlock()
                Keys.onEscapePressed: text = ""
                Component.onCompleted: forceActiveFocus()

                Connections {
                    target: root.context
                    function onCurrentTextChanged() { pwInput.text = root.context.currentText }
                    function onShowFailureChanged() { if (root.context.showFailure) pwField.shakeTrigger++ }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.context.currentText.length === 0
                text: "Type your password"
                color: root.mutedInk
                font.family: "Monocraft Nerd Font"; font.pixelSize: 11
            }

            Row {
                id: dotsRow
                anchors.centerIn: parent
                spacing: 8
                opacity: root.context.unlockInProgress ? 0.45 : 1
                readonly property int count: root.context.currentText.length
                readonly property real dot: count <= 11 ? 24 : Math.max(12, 260 / count)

                Repeater {
                    model: dotsRow.count
                    delegate: Canvas {
                        id: shapeDot
                        required property int index
                        width: dotsRow.dot; height: dotsRow.dot
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        readonly property color fillColor: root.context.showFailure ? root.errColor : root.palette[index % root.palette.length]

                        onFillColorChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        Component.onCompleted: requestPaint()

                        NumberAnimation on scale { from: 0.3; to: 1; duration: 170; easing.type: Easing.OutBack }

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var w = width, h = height, k
                            ctx.fillStyle = fillColor
                            ctx.beginPath()
                            switch (index % 5) {
                            case 0:
                                ctx.arc(w / 2, h / 2, w / 2, 0, Math.PI * 2); break
                            case 1:
                                ctx.moveTo(w / 2, 2); ctx.lineTo(w - 2, h - 2); ctx.lineTo(2, h - 2); ctx.closePath(); break
                            case 2:
                                ctx.rect(w * 0.15, h * 0.15, w * 0.7, h * 0.7); break
                            case 3:
                                for (k = 0; k < 6; k++) {
                                    var a = Math.PI / 3 * k + Math.PI / 6
                                    var px = w / 2 + Math.cos(a) * w / 2, py = h / 2 + Math.sin(a) * w / 2
                                    if (k === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py)
                                }
                                ctx.closePath(); break
                            default:
                                ctx.moveTo(w / 2, 2); ctx.lineTo(w - 2, h / 2); ctx.lineTo(w / 2, h - 2); ctx.lineTo(2, h / 2); ctx.closePath(); break
                            }
                            ctx.fill()
                        }
                    }
                }

                Rectangle {
                    visible: dotsRow.count > 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2; height: 20; radius: 1
                    color: root.palette[0]
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: dotsRow.count > 0
                        NumberAnimation { to: 0.1; duration: 500 }
                        NumberAnimation { to: 1.0; duration: 500 }
                    }
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "󰁔"
                color: root.palette[0]
                opacity: root.context.currentText.length > 0 ? 1 : 0.25
                font.family: "Monocraft Nerd Font"; font.pixelSize: 18
                MouseArea {
                    anchors.fill: parent; anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.context.tryUnlock()
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.context.unlockInProgress ? "Checking…" : "Incorrect password"
            color: root.context.unlockInProgress ? root.mutedInk : root.errColor
            font.family: "Monocraft Nerd Font"; font.pixelSize: 11
            opacity: (root.context.showFailure || root.context.unlockInProgress) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    Rectangle {
        id: musicCard
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 36
        anchors.bottomMargin: root.hasTrack ? 36 : -140
        width: 320; height: 92
        radius: 26
        color: root.cardBg
        opacity: root.hasTrack ? 1 : 0
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }
        Behavior on opacity { NumberAnimation { duration: 300 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            Item {
                Layout.preferredWidth: 64; Layout.preferredHeight: 64

                Rectangle { id: coverMask; anchors.fill: parent; radius: root.isPlaying ? 20 : 16; visible: false
                            Behavior on radius { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } } }
                Rectangle {
                    anchors.fill: parent
                    radius: root.isPlaying ? 20 : 16
                    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25)
                    visible: coverImg.status !== Image.Ready
                    Behavior on radius { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    Text { anchors.centerIn: parent; text: "󰝚"; color: root.palette[0]
                           font.family: "Monocraft Nerd Font"; font.pixelSize: 24 }
                }
                Image {
                    id: coverImg
                    anchors.fill: parent
                    source: root.player ? (root.player.trackArtUrl || "") : ""
                    sourceSize: Qt.size(128, 128)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                    layer.enabled: true
                    layer.effect: OpacityMask { maskSource: coverMask }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            Layout.fillWidth: true
                            text: root.player ? (root.player.trackTitle || "") : ""
                            elide: Text.ElideRight
                            color: root.ink
                            font.family: "Monocraft Nerd Font"; font.pixelSize: 13; font.bold: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.player ? (root.player.trackArtist || "") : ""
                            elide: Text.ElideRight
                            color: root.mutedInk
                            font.family: "Monocraft Nerd Font"; font.pixelSize: 11
                        }
                    }

                    Row {
                        Layout.alignment: Qt.AlignTop
                        spacing: 3
                        Repeater {
                            model: 4
                            delegate: Rectangle {
                                id: bar
                                required property int index
                                anchors.bottom: parent.bottom
                                width: 3; radius: 1.5
                                color: root.palette[index % 6]
                                height: 4
                                SequentialAnimation on height {
                                    running: root.isPlaying
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 6 + Math.random() * 12; duration: 240 + Math.random() * 220; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 3 + Math.random() * 4;  duration: 240 + Math.random() * 220; easing.type: Easing.InOutSine }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    spacing: 18
                    Text {
                        text: "󰒮"; color: root.ink
                        font.family: "Monocraft Nerd Font"; font.pixelSize: 18
                        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                    onClicked: if (root.player) root.player.previous() }
                    }
                    Rectangle {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16
                        color: root.palette[0]
                        Text { anchors.centerIn: parent; text: root.isPlaying ? "󰏤" : "󰐊"; color: root.darker(root.palette[0], 2.5)
                               font.family: "Monocraft Nerd Font"; font.pixelSize: 16 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: if (root.player) root.player.togglePlaying() }
                    }
                    Text {
                        text: "󰒭"; color: root.ink
                        font.family: "Monocraft Nerd Font"; font.pixelSize: 18
                        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                    onClicked: if (root.player) root.player.next() }
                    }
                }
            }
        }
    }

    RowLayout {
        id: powerRow
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 36
        anchors.bottomMargin: 48
        spacing: 12

        Repeater {
            model: [
                { glyph: "󰒲",   label: "Suspend",   cmd: "systemctl suspend" },
                { glyph: "󰤄", label: "Hibernate", cmd: "systemctl hibernate" },
                { glyph: "󰍃",    label: "Logout",    cmd: "loginctl terminate-user $USER" },
                { glyph: "󰑐",    label: "Reboot",    cmd: "systemctl reboot" },
                { glyph: "󰐥",  label: "Shutdown",  cmd: "systemctl poweroff" }
            ]
            delegate: Rectangle {
                id: pbtn
                required property var modelData
                Layout.preferredWidth: 46
                Layout.preferredHeight: 46
                radius: 16
                color: pbMa.containsMouse ? root.palette[0] : root.cardBg
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: pbtn.modelData.glyph
                    color: pbMa.containsMouse ? root.darker(root.palette[0], 2.5) : root.ink
                    font.family: "Monocraft Nerd Font"; font.pixelSize: 18
                }
                MouseArea {
                    id: pbMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.hoveredPowerLabel = pbtn.modelData.label
                    onExited: root.hoveredPowerLabel = ""
                    onClicked: powerProc.exec(pbtn.modelData.label === "Logout" ? "loginctl terminate-user $USER" : pbtn.modelData.cmd)
                }
            }
        }
    }

    property string hoveredPowerLabel: ""
    Text {
        anchors.horizontalCenter: powerRow.horizontalCenter
        anchors.bottom: powerRow.top
        anchors.bottomMargin: 12
        text: root.hoveredPowerLabel
        visible: text !== ""
        color: root.mutedInk
        font.family: "Monocraft Nerd Font"; font.pixelSize: 11
    }

    Process {
        id: powerProc
        function exec(cmd) {
            powerProc.command = ["sh", "-c", cmd]
            powerProc.running = true
        }
    }
}

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: dock

    property bool dockEnabled: true
    property bool wallVisible: false

    visible: dockEnabled && !wallVisible && (launcherOpen || mode === "wallpaper")

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors {
        top: true
        bottom: true
        left: true
    }

    margins {
        top: 56
        bottom: 10
        left: 12
    }

    implicitWidth: 340
    color: "transparent"
    focusable: true

    property bool launcherOpen: false
    property string query: ""
    property string mode: "apps"
    property bool suppress: false

    readonly property string launcherFont: "Iosevka Nerd Font"
    readonly property int launcherFontSize: 14

    property color bg0: adapter.bg0
    property color bg1: adapter.bg1
    property color bg2: adapter.bg2
    property color bg3: adapter.bg3
    property color text: adapter.text
    property color blue: adapter.blue
    property color grey1: adapter.grey1

    FileView {
        path: Qt.resolvedUrl("colors.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property string bg0: "#1a1112"
            property string bg1: "#271d1e"
            property string bg2: "#322828"
            property string bg3: "#3d3232"
            property string text: "#f0dede"
            property string blue: "#ffb2b6"
            property string grey1: "#9f8c8c"
        }
    }

    readonly property string wallDir: Quickshell.env("HOME") + "/.config/hypr/yuna/"
    readonly property string wallScript: Quickshell.env("HOME") + "/.config/hypr/s/wall"

    property var wallFiles: []
    property string activeWall: ""

    function applyWall(path) {
        if (!path) return
        activeWall = path
        Quickshell.execDetached(["bash", wallScript, path])
        closeLauncher()
    }

    Process {
        id: wallListProc
        command: ["bash", "-c",
            "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort -V",
            "_", dock.wallDir]
        stdout: StdioCollector {
            onStreamFinished: dock.wallFiles = text.split("\n").filter(l => l.length > 0)
        }
    }

    readonly property int appRevision: DesktopEntries.applications.values.length

    readonly property var sortedApps: {
        var rev = appRevision
        var all = [...DesktopEntries.applications.values].filter(
            a => a.icon && a.icon.length > 0 && Quickshell.iconPath(a.icon, true) !== ""
        )
        all.sort((a, b) => (a.name || "").localeCompare(b.name || ""))
        return all
    }

    readonly property bool showList: launcherOpen && mode === "apps"
    readonly property bool showWallpapers: launcherOpen && mode === "wallpaper"

    function filteredApps() {
        var all = sortedApps
        var q = query.trim().toLowerCase()
        if (q === "") return all
        var out = []
        for (var i = 0; i < all.length; i++) {
            var app = all[i]
            var hay = ((app.name || "") + " " + (app.genericName || "") + " " + (app.id || "")).toLowerCase()
            if (hay.indexOf(q) >= 0) out.push(app)
        }
        return out
    }

    readonly property var appModel: showList ? filteredApps() : []

    function handleInput(t) {
        var s = t.trim()
        var low = s.toLowerCase()

        if (low === "/w" || low.indexOf("/w ") === 0) {
            if (mode !== "wallpaper") mode = "wallpaper"
            query = ""
            return
        }

        if (mode !== "apps") mode = "apps"
        query = s
    }

    function toggleLauncher() {
        if (launcherOpen) {
            closeLauncher()
        } else {
            launcherOpen = true
            mode = "apps"
            query = ""
            suppress = true
            searchInput.text = ""
            suppress = false
            focusTimer.restart()
        }
    }

    function closeLauncher() {
        launcherOpen = false
        mode = "apps"
        query = ""
        suppress = true
        searchInput.text = ""
        suppress = false
        if (searchInput.activeFocus) searchInput.focus = false
    }

    function launchApp(app) {
        if (!app) return
        closeLauncher()
        app.execute()
    }

    function openWallpaper() {
        launcherOpen = true
        mode = "wallpaper"
        query = ""
        suppress = true
        searchInput.text = "/w"
        suppress = false
        focusTimer.restart()
    }

    onModeChanged: {
        if (mode === "wallpaper") {
            wallListProc.running = true
            wallList.currentIndex = 0
        }
        Qt.callLater(() => searchInput.forceActiveFocus())
    }

    IpcHandler {
        target: "sky"
        function toggle(): void { dock.toggleLauncher() }
        function open(): void { if (!dock.launcherOpen) dock.toggleLauncher() }
        function close(): void { if (dock.launcherOpen) dock.closeLauncher() }
        function wallpaper(): void { dock.openWallpaper() }
    }

    Timer {
        id: focusTimer
        interval: 160
        repeat: false
        onTriggered: searchInput.forceActiveFocus()
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        MouseArea {
            anchors.fill: parent
            onClicked: dock.closeLauncher()
        }
    }

    Rectangle {
        id: mainPanel
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            topMargin: 4
            bottomMargin: 4
        }
        width: parent.width
        radius: 12
        color: dock.bg0
        border.width: 1
        border.color: Qt.rgba(dock.blue.r, dock.blue.g, dock.blue.b, 0.25)

        opacity: dock.launcherOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        transform: Translate {
            x: dock.launcherOpen ? 0 : -28
            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: dock.mode === "wallpaper" ? "   Walls" : " App Launcher"
                    color: dock.blue
                    font.pixelSize: 19
                    font.bold: true
                    font.family: dock.launcherFont
                }
                Item { Layout.fillWidth: true }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 10
                color: dock.bg1
                border.width: 1
                border.color: searchInput.activeFocus ? dock.blue : Qt.rgba(1, 1, 1, 0.12)
                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Text {
                        text: dock.mode === "wallpaper" ? "W" : "󰍉"
                        color: dock.blue
                        font.pixelSize: 16
                        font.family: dock.launcherFont
                    }

                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        placeholderText: dock.mode === "wallpaper"
                            ? "Wallpaper selector..."
                            : "Search trizen <3  (/w for walls)"
                        font.pixelSize: dock.launcherFontSize
                        font.family: dock.launcherFont
                        color: dock.text
                        placeholderTextColor: dock.grey1
                        leftPadding: 0; rightPadding: 0
                        topPadding: 0; bottomPadding: 0
                        background: Rectangle { color: "transparent" }
                
                        onTextChanged: {
                            if (dock.suppress) return
                            dock.handleInput(text)
                            appList.currentIndex = dock.appModel.length > 0 ? 0 : -1
                        }

                        Keys.onEscapePressed: dock.closeLauncher()

                        Keys.onPressed: event => {
                            if (dock.mode === "wallpaper") {
                                if (event.key === Qt.Key_Down) {
                                    event.accepted = true
                                    wallList.incrementCurrentIndex()
                                } else if (event.key === Qt.Key_Up) {
                                    event.accepted = true
                                    wallList.decrementCurrentIndex()
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    event.accepted = true
                                    dock.applyWall(dock.wallFiles[wallList.currentIndex])
                                }
                            } else {
                                if (event.key === Qt.Key_Down) {
                                    event.accepted = true
                                    if (dock.showList && appList.currentIndex < appList.count - 1)
                                        appList.currentIndex++
                                } else if (event.key === Qt.Key_Up) {
                                    event.accepted = true
                                    if (dock.showList && appList.currentIndex > 0)
                                        appList.currentIndex--
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    event.accepted = true
                                    if (!dock.showList) return
                                    var idx = appList.currentIndex
                                    var app = idx >= 0 ? dock.appModel[idx] : null
                                    dock.launchApp(app)
                                }
                            }
                        }
                    }

                    Text {
                        visible: searchInput.text.length > 0
                        text: "✕"
                        color: dock.grey1
                        font.pixelSize: 12
                        font.family: dock.launcherFont
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = ""
                                searchInput.forceActiveFocus()
                            }
                        }
                    }
                }
            }

            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: dock.showList
                onVisibleChanged: if (visible) appFade.restart()
                NumberAnimation { id: appFade; target: appList; property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
                clip: true
                spacing: 3
                model: dock.appModel
                currentIndex: dock.appModel.length > 0 ? 0 : -1
                keyNavigationWraps: true
                highlightMoveDuration: 0
                highlightMoveVelocity: -1
                boundsBehavior: Flickable.StopAtBounds

                highlight: Rectangle {
                    radius: 8
                    color: dock.bg2
                }

                delegate: Item {
                    id: entry
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: 50

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: appList.currentIndex = entry.index
                        onDoubleClicked: dock.launchApp(entry.modelData)

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: parent.containsMouse && appList.currentIndex !== entry.index
                                ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 10

                        Rectangle {
                            width: 34; height: 34
                            radius: 8
                            color: dock.bg1
                            Image {
                                anchors.centerIn: parent
                                width: 22; height: 22
                                source: Quickshell.iconPath(entry.modelData.icon, true)
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: entry.modelData.name || ""
                                color: appList.currentIndex === entry.index ? dock.blue : dock.text
                                Behavior on color { ColorAnimation { duration: 100 } }
                                font.pixelSize: 13
                                font.family: dock.launcherFont
                                font.bold: appList.currentIndex === entry.index
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            visible: appList.currentIndex === entry.index
                            text: "↵"
                            color: dock.blue
                            font.pixelSize: 14
                            font.family: dock.launcherFont
                        }
                    }
                }

                Item {
                    anchors.centerIn: parent
                    visible: dock.appModel.length === 0 && searchInput.text.length > 0
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰍉"
                            color: dock.grey1
                            font.pixelSize: 32
                            font.family: dock.launcherFont
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No results"
                            color: dock.grey1
                            font.pixelSize: 13
                            font.family: dock.launcherFont
                        }
                    }
                }
            }

            Item {
                id: wallContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: dock.showWallpapers
                onVisibleChanged: if (visible) wallFade.restart()
                NumberAnimation { id: wallFade; target: wallContainer; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }

                ListView {
                    id: wallList
                    anchors.fill: parent
                    clip: true
                    spacing: 8
                    model: dock.wallFiles
                    currentIndex: 0
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 0
                    highlightMoveVelocity: -1
                    cacheBuffer: 1200

                    Keys.onEscapePressed: dock.closeLauncher()
                    Keys.onUpPressed: decrementCurrentIndex()
                    Keys.onDownPressed: incrementCurrentIndex()
                    Keys.onReturnPressed: dock.applyWall(dock.wallFiles[currentIndex])
                    Keys.onEnterPressed: dock.applyWall(dock.wallFiles[currentIndex])

                    delegate: Rectangle {
                        id: card
                        required property string modelData
                        required property int index
                        readonly property bool isCurrent: ListView.isCurrentItem
                        readonly property bool isActive: modelData === dock.activeWall

                        width: ListView.view.width
                        height: Math.round((width - 12) * 9 / 16) + 12
                        radius: 10
                        color: isCurrent ? dock.bg2 : dock.bg1
                        border.width: 2
                        border.color: isCurrent ? dock.blue : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Item {
                            anchors.fill: parent
                            anchors.margins: 6

                            Image {
                                id: thumb
                                anchors.fill: parent
                                source: "file://" + card.modelData
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 480
                                asynchronous: true
                                cache: true
                                smooth: true
                                visible: false
                            }
                            Rectangle {
                                id: thumbMask
                                anchors.fill: parent
                                radius: 6
                                visible: false
                            }
                            OpacityMask {
                                anchors.fill: parent
                                source: thumb
                                maskSource: thumbMask
                                opacity: thumb.status === Image.Ready ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 220 } }
                            }

                            Rectangle {
                                visible: opacity > 0
                                opacity: card.isActive ? 1 : 0
                                scale: card.isActive ? 1 : 0.4
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 6
                                width: 10
                                height: 10
                                radius: 5
                                color: dock.blue
                                border.width: 2
                                border.color: dock.bg0
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: wallList.currentIndex = card.index
                            onClicked: dock.applyWall(card.modelData)
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: dock.wallFiles.length === 0
                    text: "No wallpapers found"
                    color: dock.grey1
                    font.family: dock.launcherFont
                    font.pixelSize: 14
                }
            }
        }
    }
}

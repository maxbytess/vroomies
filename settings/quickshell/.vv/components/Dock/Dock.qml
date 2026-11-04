import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Dock + launcher.
//   Sol: acik uygulamalar | Orta: arama butonu | Sag: favoriler
// Arama butonu launcher'i acar (once sadece arama kutusu). Komutlar:
//   /a  -> uygulama listesi        (duz yazi da uygulama arar)
//   /w  -> duvar kagidi secici
//   /m  -> muzik player (Esc ile cikilir)
PanelWindow {
    id: dock

    visible: root.dockEnabled && !root.wallVisible
    exclusionMode: ExclusionMode.Ignore

    // Pencere boyutu SABIT: pill animasyonla buyurken yuzeyin her karede
    // yeniden boyutlanmasi kasmanin asil sebebiydi.
    anchors { bottom: true; left: true; right: true }
    margins.bottom: 10 + (root.barPosition === "bottom" ? root.barThickness : 0)
    implicitHeight: 420
    color: "transparent"
    focusable: true

    WlrLayershell.layer: launcherOpen ? WlrLayer.Overlay : WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-dock"
    WlrLayershell.keyboardFocus: launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool launcherOpen: false
    property string query: ""
    property string mode: ""          // "" | "apps" | "music"
    property bool suppress: false

    readonly property string launcherFont: "Monocraft Nerd Font"
    readonly property int launcherFontSize: 13
    readonly property var defaultFavorites: ["kitty", "firefox", "thunar"]

    readonly property var favIds: (
        root.dockFavorites && root.dockFavorites.length > 0
        ? root.dockFavorites
        : defaultFavorites
    )

    readonly property int appRevision: DesktopEntries.applications.values.length
    readonly property int toplevelRev: ToplevelManager.toplevels.values.length

    readonly property var sortedApps: {
        var rev = appRevision
        var all = [...DesktopEntries.applications.values]
        all.sort(function(a, b) {
            return (a.name || "").localeCompare(b.name || "")
        })
        return all
    }

    readonly property color rofiBg1: zyuTheme.widget_bg
    readonly property color rofiBorder2: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.22)
    readonly property color rofiBorder3: Qt.rgba(1, 1, 1, 0.12)
    readonly property color rofiText: zyuTheme.bar_fg
    readonly property color rofiBlue: zyuTheme.accent
    readonly property color rofiGrey1: Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.45)

    // Eski Quickshell surumlerinde heuristicLookup / iconPath(fallback) olmayabilir; ikisi de korumali.
    function entryFor(id) {
        var rev = appRevision
        var e = DesktopEntries.byId(id)
        if (!e && typeof DesktopEntries.heuristicLookup === "function") e = DesktopEntries.heuristicLookup(id)
        return e || null
    }

    function iconFor(appId) {
        var e = entryFor(appId)
        var p = Quickshell.iconPath(e && e.icon ? e.icon : appId, true)
        return p !== "" ? p : Quickshell.iconPath("application-x-executable")
    }

    function norm(s) {
        return (s || "").toLowerCase().replace(/\.desktop$/, "")
    }

    function runningWindow(id) {
        var list = ToplevelManager.toplevels.values
        var e = entryFor(id)
        var want = [norm(id)]
        if (e && e.id) want.push(norm(e.id))
        for (var i = 0; i < list.length; i++) {
            if (want.indexOf(norm(list[i].appId)) >= 0) return list[i]
        }
        return null
    }

    // Favorilerin normalize adlari bir kez hesaplanir (her pencere icin tekrar aranmaz)
    readonly property var favWanted: {
        var rev = appRevision
        var out = []
        for (var i = 0; i < favIds.length; i++) {
            out.push(norm(favIds[i]))
            var e = entryFor(favIds[i])
            if (e && e.id) out.push(norm(e.id))
        }
        return out
    }

    function isFavApp(appId) {
        return favWanted.indexOf(norm(appId)) >= 0
    }

    readonly property var nonFavToplevels: {
        var rev = toplevelRev
        var fav = favWanted
        var list = ToplevelManager.toplevels.values
        var out = []
        for (var i = 0; i < list.length; i++) {
            if (!isFavApp(list[i].appId)) out.push(list[i])
        }
        return out
    }

    // ---- Launcher durumu ----
    readonly property bool showList: launcherOpen && (mode === "apps" || (mode === "" && query !== ""))

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
            closeLauncher()
            root.wallVisible = true
            return
        }
        if (low === "/m" || low.indexOf("/m ") === 0) {
            mode = "music"
            query = ""
            root.musicVisible = true
            return
        }
        if (mode === "music") root.musicVisible = false

        if (low === "/a" || low.indexOf("/a ") === 0) {
            mode = "apps"
            query = s.slice(2).trim()
            return
        }
        mode = ""
        query = s.charAt(0) === "/" ? "" : s   // yarim yazilmis komut ("/") liste acmasin
    }

    function toggleLauncher() {
        if (launcherOpen) {
            closeLauncher()
        } else {
            launcherOpen = true
            focusTimer.restart()
        }
    }

    function closeLauncher() {
        if (mode === "music") root.musicVisible = false
        launcherOpen = false
        mode = ""
        query = ""
        suppress = true
        searchInput.text = ""
        suppress = false
    }

    function launchApp(app) {
        if (!app) return
        closeLauncher()
        app.execute()
    }

    // Klavye kisayolu icin:  qs ipc call dock toggle
    IpcHandler {
        target: "dock"
        function toggle(): void { dock.toggleLauncher() }
    }

    // Launcher'in gercek yuksekligini muzik paneline bildir (ustunde acilsin)
    Binding {
        target: root
        property: "dockPillHeight"
        value: dock.visible ? content.implicitHeight + 24 : 0
    }

    Timer {
        id: focusTimer
        interval: 160
        repeat: false
        onTriggered: searchInput.forceActiveFocus()
    }

    // Pill disina tiklayinca kapat
    MouseArea {
        anchors.fill: parent
        enabled: dock.launcherOpen
        onClicked: dock.closeLauncher()
    }

    Rectangle {
        id: pill

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        width: dock.launcherOpen
            ? Math.max(380, dockGrid.implicitWidth + 24)
            : dockGrid.implicitWidth + 24
        height: content.implicitHeight + 24

        radius: dock.launcherOpen ? 18 : 28

        color: Qt.rgba(zyuTheme.bar_bg.r, zyuTheme.bar_bg.g, zyuTheme.bar_bg.b, 0.9)
        border.width: 1
        border.color: rofiBorder2

        Behavior on width  { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        // Pill'in kendi tiklamalari disariya (kapatma alanina) gitmesin
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // ---- Launcher: arama kutusu + (istege bagli) liste ----
            ColumnLayout {
                id: launcherCol
                Layout.fillWidth: true
                Layout.preferredHeight: dock.launcherOpen ? implicitHeight : 0
                spacing: 8
                clip: true

                opacity: dock.launcherOpen ? 1 : 0
                visible: dock.launcherOpen || opacity > 0.01
                enabled: dock.launcherOpen

                Behavior on opacity {
                    NumberAnimation { duration: dock.launcherOpen ? 220 : 120; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 8
                    color: rofiBg1
                    border.width: 1
                    border.color: searchInput.activeFocus ? rofiBlue : rofiBorder3
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: dock.mode === "music" ? "♪" : (dock.mode === "apps" ? "A" : ">")
                            color: rofiBlue
                            font.family: dock.launcherFont
                            font.pixelSize: dock.launcherFontSize
                        }

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true

                            placeholderText: "/a apps   /w wallpaper   /m music"
                            font.family: dock.launcherFont
                            font.pixelSize: dock.launcherFontSize
                            color: rofiText
                            placeholderTextColor: rofiGrey1

                            leftPadding: 0
                            rightPadding: 0
                            topPadding: 0
                            bottomPadding: 0
                            background: Rectangle { color: "transparent" }

                            onTextChanged: {
                                if (dock.suppress) return
                                dock.handleInput(text)
                                appList.currentIndex = dock.appModel.length > 0 ? 0 : -1
                            }

                            Keys.onEscapePressed: dock.closeLauncher()

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Down) {
                                    event.accepted = true
                                    if (appList.currentIndex < appList.count - 1) appList.currentIndex++
                                } else if (event.key === Qt.Key_Up) {
                                    event.accepted = true
                                    if (appList.currentIndex > 0) appList.currentIndex--
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    event.accepted = true
                                    if (!dock.showList) return
                                    var app = dock.appModel[appList.currentIndex]
                                    if (!app && dock.appModel.length > 0) app = dock.appModel[0]
                                    dock.launchApp(app)
                                }
                            }
                        }

                        Text {
                            visible: searchInput.text.length > 0
                            text: "✕"
                            color: rofiGrey1
                            font.family: dock.launcherFont
                            font.pixelSize: 11

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
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
                    Layout.preferredHeight: dock.showList
                        ? Math.min(count, 5) * 32 + Math.max(0, Math.min(count, 5) - 1) * 4
                        : 0
                    visible: dock.showList

                    spacing: 4
                    clip: true
                    model: dock.appModel
                    currentIndex: -1
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: appItem
                        required property var modelData
                        required property int index

                        width: appList.width
                        height: 32
                        radius: 6

                        color: index === appList.currentIndex
                            ? rofiBg1
                            : itemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            elide: Text.ElideRight
                            text: appItem.modelData.name || appItem.modelData.id
                            color: appItem.index === appList.currentIndex ? rofiBlue : rofiText
                            font.family: dock.launcherFont
                            font.pixelSize: dock.launcherFontSize - 1
                        }

                        MouseArea {
                            id: itemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dock.launchApp(appItem.modelData)
                        }
                    }
                }
            }

            // ---- Dock satiri ----
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 44

                GridLayout {
                    id: dockGrid
                    anchors.centerIn: parent
                    rows: 1
                    columns: 3
                    columnSpacing: 10

                    // Sol: acik uygulamalar
                    Item {
                        Layout.preferredWidth: Math.max(openRow.implicitWidth, favRow.implicitWidth)
                        Layout.preferredHeight: 44

                        Row {
                            id: openRow
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Repeater {
                                model: dock.nonFavToplevels

                                delegate: Item {
                                    id: openItem
                                    required property var modelData
                                    width: 44
                                    height: 44

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 12
                                        color: openMa.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    Image {
                                        anchors.centerIn: parent
                                        width: 28; height: 28
                                        sourceSize: Qt.size(56, 56)
                                        source: dock.iconFor(openItem.modelData.appId)
                                        scale: openMa.containsMouse ? 1.15 : 1
                                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                    }

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 2
                                        width: openItem.modelData.activated ? 14 : 5
                                        height: 3
                                        radius: 1.5
                                        color: zyuTheme.accent
                                        opacity: openItem.modelData.activated ? 1 : 0.5
                                    }

                                    MouseArea {
                                        id: openMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: mouse => {
                                            if (mouse.button === Qt.MiddleButton) openItem.modelData.close()
                                            else openItem.modelData.activate()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Orta: arama butonu
                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 22

                        color: searchMa.containsMouse
                            ? Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.4)
                            : Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.24)
                        border.width: 1
                        border.color: zyuTheme.accent
                        scale: searchMa.pressed ? 0.94 : 1

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰍉"
                            color: zyuTheme.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 20
                        }

                        MouseArea {
                            id: searchMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dock.toggleLauncher()
                        }
                    }

                    // Sag: favoriler
                    Item {
                        Layout.preferredWidth: Math.max(openRow.implicitWidth, favRow.implicitWidth)
                        Layout.preferredHeight: 44

                        Row {
                            id: favRow
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Repeater {
                                model: dock.favIds

                                delegate: Item {
                                    id: favItem
                                    required property string modelData

                                    readonly property var entry: dock.entryFor(modelData)
                                    readonly property bool running: dock.runningWindow(modelData) !== null

                                    visible: entry !== null && entry !== undefined
                                    width: visible ? 44 : 0
                                    height: 44

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 12
                                        color: favMa.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    Image {
                                        anchors.centerIn: parent
                                        width: 28; height: 28
                                        sourceSize: Qt.size(56, 56)
                                        source: dock.iconFor(favItem.modelData)
                                        scale: favMa.containsMouse ? 1.15 : 1
                                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                    }

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 2
                                        width: 5; height: 3; radius: 1.5
                                        color: zyuTheme.accent
                                        visible: favItem.running
                                        opacity: 0.6
                                    }

                                    MouseArea {
                                        id: favMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var w = dock.runningWindow(favItem.modelData)
                                            if (w) w.activate()
                                            else if (favItem.entry) favItem.entry.execute()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

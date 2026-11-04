import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import "."

PanelWindow {
    id: main
    visible: root.wallVisible
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    margins {
        top:    root.barPosition === "top"    ? root.barThickness : 0
        left:   root.barLeft  ? root.barThickness : 0
        bottom: root.barPosition === "bottom" ? root.barThickness : 0
        right:  root.barRight ? root.barThickness : 0
    }
    color: "transparent"
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.wallVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property string wallpapersDir: Quickshell.env("HOME") + "/Pictures/Julia-V2/"

    function applyWallpaper(path) {
        wallApplyProc.command = ["bash", Quickshell.env("HOME") + "/.config/quickshell/vv/scripts/wall.sh", path]
        wallApplyProc.running = true
        lastWallpaper.save(path.replace("//", "/"))
        root.wallVisible = false
    }
    Process { id: wallApplyProc }

    Persistence {
        id: lastWallpaper
        path: Quickshell.env("HOME") + "/.config/quickshell/vv/current_wallpaper"
        onReady: restoreTimer.restart()
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        MouseArea { anchors.fill: parent; onClicked: root.wallVisible = false }
    }

    Text {
        anchors.centerIn: parent
        visible: folderModel.status === FolderListModel.Ready && folderModel.count === 0
        horizontalAlignment: Text.AlignHCenter
        color: zyuTheme.bar_fg; opacity: 0.6
        text: main.wallpapersDir + " has no images."
        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
    }

    Item {
        id: pickerFocus
        anchors.fill: parent
        focus: main.visible
        Component.onCompleted: pickerFocus.forceActiveFocus()

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.wallVisible = false
                event.accepted = true
            } else if (event.key === Qt.Key_Left) {
                strip.move(-1)
                event.accepted = true
            } else if (event.key === Qt.Key_Right) {
                strip.move(1)
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                var path = folderModel.get(strip.focusIndex, "filePath")
                if (path) main.applyWallpaper(path)
                event.accepted = true
            }
        }

        Item {
            id: strip
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 40
            width: parent.width - 24
            height: 180

            property int focusIndex: 0
            property real pos: 0
            property int count: folderModel.count

            readonly property var slotW:      [196, 126, 104, 88, 74]
            readonly property var slotH:      [110, 71, 59, 50, 42]
            readonly property var slotCX:     [0, 143, 244, 326, 393]
            readonly property var slotBright: [1, 0.85, 0.70, 0.55, 0.42]

            function slotLerp(arr, ao) {
                if (ao >= 4) return arr[4]
                var i = Math.floor(ao)
                var f = ao - i
                return arr[i] + (arr[i + 1] - arr[i]) * f
            }

            function offsetX(off) {
                var ao = Math.abs(off)
                var cx
                if (ao <= 4)
                    cx = slotLerp(slotCX, ao)
                else
                    cx = slotCX[4] + (ao - 4) * 85
                return off < 0 ? -cx : cx
            }

            function move(delta) {
                if (count === 0) return
                focusIndex = Math.max(0, Math.min(count - 1, focusIndex + delta))
            }

            function findIndexByPath(targetPath) {
                if (!targetPath || count <= 0) return 0
                for (var i = 0; i < count; i++) {
                    if (folderModel.get(i, "filePath") === targetPath) return i
                }
                return 0
            }

            Timer {
                id: restoreTimer
                interval: 50
                repeat: false
                onTriggered: {
                    if (strip.count === 0) return
                    strip.focusIndex = strip.findIndexByPath(lastWallpaper.isReady ? lastWallpaper.load() : "")
                    strip.pos = strip.focusIndex
                }
            }

            FrameAnimation {
                running: strip.pos !== strip.focusIndex
                onTriggered: {
                    var k = 1 - Math.exp(-frameTime / 0.08)
                    var next = strip.pos + (strip.focusIndex - strip.pos) * k
                    strip.pos = Math.abs(next - strip.focusIndex) < 0.001 ? strip.focusIndex : next
                }
            }

            FolderListModel {
                id: folderModel
                folder: "file://" + main.wallpapersDir
                showDirs: false
                caseSensitive: false
                nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
                sortField: FolderListModel.Name
                onStatusChanged: if (status === FolderListModel.Ready) restoreTimer.restart()
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                property real acc: 0
                onWheel: event => {
                    acc += event.angleDelta.y / 120
                    var notches = Math.trunc(acc)
                    if (notches !== 0) {
                        strip.move(-notches)
                        acc -= notches
                    }
                    event.accepted = true
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(zyuTheme.widget_bg.r, zyuTheme.widget_bg.g, zyuTheme.widget_bg.b, 0.92)
                radius: 16
                border.color: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.25)
                border.width: 1
            }

            Repeater {
                model: folderModel

                delegate: Item {
                    id: tile
                    required property int index
                    required property string filePath
                    required property string fileName

                    readonly property real off: index - strip.pos
                    readonly property real ao: Math.abs(off)
                    readonly property bool focused: index === strip.focusIndex
                    readonly property real bright: strip.slotLerp(strip.slotBright, ao)

                    width:   strip.slotLerp(strip.slotW, ao)
                    height:  strip.slotLerp(strip.slotH, ao)
                    x:       strip.width / 2 + strip.offsetX(off) - width / 2
                    y:       (strip.height - height) / 2
                    z:       10 - ao
                    visible: true
                    opacity: 1

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        clip: true
                        color: "#111"
                        border.width: tile.focused ? 2 : 0
                        border.color: zyuTheme.accent

                        OpacityMask {
                            anchors.fill: parent

                            source: Image {
                                anchors.fill: parent
                                source: "file://" + tile.filePath
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize: Qt.size(400, 250)
                                smooth: true
                            }

                            maskSource: Rectangle {
                                width: tile.width
                                height: tile.height
                                radius: 10
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(0, 0, 0, 1 - tile.bright)
                            radius: 10
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: "transparent"
                            border.width: tile.focused ? 2 : 0
                            border.color: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.6)
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (tile.focused) {
                                    main.applyWallpaper(tile.filePath)
                                } else {
                                    strip.focusIndex = tile.index
                                    pickerFocus.forceActiveFocus()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

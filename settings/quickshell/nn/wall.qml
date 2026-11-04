import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: rootScope

    property bool wallVisible: true

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: rootScope.wallVisible
        onActivated: rootScope.wallVisible = false
    }

    readonly property color bg0: adapter.bg0
    readonly property color bg1: adapter.bg1
    readonly property color bg2: adapter.bg2
    readonly property color bg3: adapter.bg3
    readonly property color text: adapter.text
    readonly property color blue: adapter.blue
    readonly property color grey1: adapter.grey1

    readonly property string activeFont: "DaddyTimeMono NF"
    readonly property string wallPath: Quickshell.env("HOME") + "/.config/niri/yuna/"
    readonly property string wallScript: Quickshell.env("HOME") + "/.config/niri/sc/wall"

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

    PanelWindow {
        id: main
        visible: rootScope.wallVisible
        implicitWidth: Screen.width
        implicitHeight: Screen.height
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Item {
            id: root
            anchors.fill: parent
            focus: true

            Component.onCompleted: root.forceActiveFocus()

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                    grid.moveCurrentIndexRight()
                    event.accepted = true
                } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                    grid.moveCurrentIndexLeft()
                    event.accepted = true
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    grid.moveCurrentIndexDown()
                    event.accepted = true
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    grid.moveCurrentIndexUp()
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                    let path = folderModel.get(grid.currentIndex, "filePath")
                    if (path) applyWallpaper(path)
                    event.accepted = true
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: rootScope.wallVisible = false
            }

            Rectangle {
                id: mainPanel
                width: 1120
                height: 700
                anchors.centerIn: parent
                color: bg0
                radius: 16
                border.color: bg3
                border.width: 1
                clip: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                Item {
                    id: header
                    width: parent.width
                    height: 85

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 30
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Text {
                            text: "󰋩"
                            font.pixelSize: 22
                            color: blue
                            font.family: "Symbols Nerd Font"
                        }

                        Text {
                            text: "壁紙"
			    font.pixelSize: 22
			    font.weight: font.Medium
                            color: blue 
                            font.family: "Symbols Nerd Font"
                        }
                    }
                }

                GridView {
                    id: grid
                    width: parent.width - 40
                    height: parent.height - 110
                    anchors.top: header.bottom
                    anchors.topMargin: 5
                    anchors.horizontalCenter: parent.horizontalCenter
                    model: folderModel
                    cellWidth: width / 4
                    cellHeight: 185
                    clip: true
                    cacheBuffer: 1000

                    FolderListModel {
                        id: folderModel
                        folder: "file://" + wallPath
                        showDirs: false
                        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
                    }

                    delegate: Item {
                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            width: parent.width - 12
                            height: parent.height - 12
                            anchors.centerIn: parent
                            radius: 12
                            color: bg1
                            clip: true

                            border.width: grid.currentIndex === index ? 2 : 0
                            border.color: blue

                            Image {
                                anchors.fill: parent
                                source: "file://" + filePath
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize: Qt.size(400, 250)
                                visible: status === Image.Ready
                            }

                            Rectangle {
                                visible: grid.currentIndex === index
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 12
                                width: 68
                                height: 24
                                radius: 6
                                color: blue

                                Text {
                                    anchors.centerIn: parent
                                    text: "ACTIVE"
                                    color: bg0
                                    font.bold: true
                                    font.pixelSize: 10
                                    font.family: activeFont
                                    font.letterSpacing: 1
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    grid.currentIndex = index
                                    root.forceActiveFocus()
                                }
                                onDoubleClicked: applyWallpaper(filePath)
                            }
                        }
                    }
                }
            }
        }
    }

    function applyWallpaper(path) {
        Quickshell.execDetached(["bash", wallScript, path])
        rootScope.wallVisible = false
    }
}

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property color bg0: adapter.bg0
    property color bg1: adapter.bg1
    property color bg2: adapter.bg2
    property color bg3: adapter.bg3
    property color text: adapter.text
    property color blue: adapter.blue
    property color grey1: adapter.grey1
    readonly property string fontFamily: "Iosevka"

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
}

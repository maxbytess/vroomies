import QtQuick
import Quickshell
import Quickshell.Io

// Bar/Dashboard bileşenlerinin hem Hyprland hem niri altında çalışabilmesi için
// eklenen yardımcı servis. Hyprland tarafına dokunmuyor: bileşenler Hyprland
// altında hâlâ doğrudan Quickshell.Hyprland modülünü kullanıyor (regresyon riski
// almamak için). Bu servis sadece niri tarafını niri'nin kendi IPC'si
// (`niri msg --json ...`) üzerinden karşılıyor.
//
// Kullanım (bileşen tarafında):
//   model: wmService.isNiri ? wmService.workspaces : Hyprland.workspaces
//   isActive: wmService.isNiri
//       ? modelData.id === wmService.focusedWorkspaceId
//       : modelData.id === Hyprland.focusedMonitor?.activeWorkspace?.id
//   onClicked: wmService.isNiri
//       ? wmService.focusWorkspace(modelData.id)
//       : Hyprland.dispatch("workspace " + modelData.id)
Item {
    id: wm

    readonly property bool isNiri: {
        const s = Quickshell.env("NIRI_SOCKET")
        return s !== undefined && s !== null && s !== ""
    }

    // [{id: <output-local workspace index>}, ...] — Hyprland.workspaces ile
    // aynı sekilde modelData.id uzerinden kullanilabilsin diye ayni sekle sokuldu.
    property var workspaces: []
    property int focusedWorkspaceId: 0
    property bool fullscreenActive: false

    function focusWorkspace(id) {
        if (!wm.isNiri) return
        niriFocusProc.command = ["niri", "msg", "action", "focus-workspace", String(id)]
        niriFocusProc.running = true
    }

    Process { id: niriFocusProc }

    Process {
        id: niriWsQuery
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector {
            id: wsCollector
            onStreamFinished: {
                try {
                    const list = JSON.parse(wsCollector.text)
                    wm.workspaces = list.map(w => ({ id: w.idx }))
                    const focused = list.find(w => w.is_focused)
                    wm.focusedWorkspaceId = focused ? focused.idx : 0
                } catch (e) {}
            }
        }
    }

    Process {
        id: niriEvents
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("Workspace") !== -1) {
                    niriWsQuery.running = true
                }
                if (line.indexOf("WindowFullscreenChanged") !== -1) {
                    try {
                        const ev = JSON.parse(line)
                        const ch = ev.WindowFullscreenChanged
                        if (ch) wm.fullscreenActive = !!ch.is_fullscreen
                    } catch (e) {}
                }
            }
        }
        onExited: (code, status) => { if (wm.isNiri) niriRestartTimer.start() }
    }

    Timer {
        id: niriRestartTimer
        interval: 2000; repeat: false
        onTriggered: niriEvents.running = true
    }

    Component.onCompleted: {
        if (wm.isNiri) {
            niriWsQuery.running = true
            niriEvents.running = true
        }
    }
}

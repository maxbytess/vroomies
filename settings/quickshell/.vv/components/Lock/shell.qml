import Quickshell
import Quickshell.Wayland

// Baglanti noktasi: bunu ayri bir quickshell sureci olarak calistir, ornegin
// bir Hyprland keybind'iyla:
//   bind = SUPER, L, exec, quickshell -p ~/.config/quickshell/vv/components/Lock/shell.qml
// veya hypridle ile otomatik kilit icin benzer sekilde cagir.
ShellRoot {
    LockContext {
        id: lockContext

        onUnlocked: {
            lock.locked = false
            Qt.quit()
        }
    }

    WlSessionLock {
        id: lock
        locked: true

        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: lockContext
            }
        }
    }
}

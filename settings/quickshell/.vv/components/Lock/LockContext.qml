import QtQuick
import Quickshell
import Quickshell.Services.Pam

// Quickshell'in resmi lockscreen ornegindeki LockContext'in birebir alinmis
// hali -- mantik zaten saglam, degistirilmedi. Tum lock yuzeyleri (coklu
// monitorde) ayni PAM durumunu paylasir.
Scope {
    id: root
    signal unlocked()
    signal failed()

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    onCurrentTextChanged: showFailure = false

    function tryUnlock() {
        if (currentText === "") return
        root.unlockInProgress = true
        pam.start()
    }

    PamContext {
        id: pam
        configDirectory: "pam"
        config: "password.conf"

        onPamMessage: {
            if (this.responseRequired) {
                this.respond(root.currentText)
            }
        }

        onCompleted: result => {
            if (result == PamResult.Success) {
                root.unlocked()
            } else {
                root.currentText = ""
                root.showFailure = true
            }
            root.unlockInProgress = false
        }
    }
}

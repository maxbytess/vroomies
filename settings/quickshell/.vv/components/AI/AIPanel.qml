import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Yerel Ollama ile sohbet paneli + aylik token sayaci.
// ~/.config/quickshell/vv/ai.json: { "host": "http://localhost:11434", "model": "llama3.2", "monthly_limit": 1000000 }
PanelWindow {
    id: aiPanel
    visible: true
    exclusionMode: ExclusionMode.Ignore
    readonly property string pos: root.barPosition
    anchors {
        top:    pos === "top"
        bottom: pos !== "top"
        left:   pos === "left"
        right:  pos !== "left"
    }
    margins {
        top:    pos === "top"  ? (root.aiVisible ? root.barThickness + 8 : -900) : 0
        bottom: pos === "top"  ? 0 : (pos === "bottom" ? (root.aiVisible ? root.barThickness + 8 : -900) : 10)
        left:   pos === "left" ? (root.aiVisible ? root.barThickness + 8 : -900) : 0
        right:  pos === "left" ? 0 : (pos === "right" ? (root.aiVisible ? root.barThickness + 8 : -900) : 10)
    }
    Behavior on margins.top    { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on margins.bottom { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on margins.left   { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on margins.right  { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    implicitWidth: 380
    implicitHeight: 540
    color: "transparent"
    focusable: true
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.aiVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    readonly property string stateDir:  Quickshell.env("HOME") + "/.config/quickshell/vv/state"
    readonly property string cfgPath:   Quickshell.env("HOME") + "/.config/quickshell/vv/ai.json"
    readonly property string usagePath: stateDir + "/ai-usage.json"
    readonly property string reqPath:   stateDir + "/ai-request.json"

    property string cfgHost: "http://localhost:11434"
    property string cfgModel: ""
    property real   cfgLimit: 1000000

    // "checking" | "down" | "ready"
    property string ollamaState: "checking"
    property var models: []
    readonly property bool hasModel: cfgModel !== ""
    property bool setupOpen: false
    readonly property bool showSetup: !hasModel || setupOpen

    property string usageMonth: ""
    property real usedIn: 0
    property real usedOut: 0
    readonly property real usedTotal: usedIn + usedOut
    readonly property real ratio: cfgLimit > 0 ? Math.min(1, usedTotal / cfgLimit) : 0

    property bool busy: false
    property string errorText: ""
    property var history: []

    function currentMonth() {
        var d = new Date()
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0")
    }
    function fmt(n) {
        if (n >= 1000000) return (n / 1000000).toFixed(2) + "M"
        if (n >= 1000) return (n / 1000).toFixed(1) + "k"
        return String(Math.round(n))
    }
    function saveUsage() {
        usageWriter.setText(JSON.stringify({ month: usageMonth, input: usedIn, output: usedOut }))
    }
    function clearChat() { history = []; chatModel.clear(); errorText = "" }

    function refreshModels() {
        ollamaState = "checking"
        tagsProc.command = ["bash", "-c",
            "curl -sS --max-time 4 \"$1/api/tags\" 2>/dev/null || echo '{\"__down\":true}'", "_", cfgHost]
        tagsProc.running = true
    }

    function selectModel(name) {
        cfgModel = name
        cfgWriter.setText(JSON.stringify({ host: cfgHost, model: name, monthly_limit: cfgLimit }, null, 2))
        setupOpen = false
    }

    function send(text) {
        text = text.trim()
        if (busy || text === "" || !hasModel) return
        history.push({ role: "user", content: text })
        chatModel.append({ role: "user", body: text })
        busy = true
        errorText = ""
        reqWriter.setText(JSON.stringify({ model: cfgModel, messages: history.slice(-20), stream: false }))
        aiProc.command = ["bash", Quickshell.env("HOME") + "/.config/quickshell/vv/scripts/ai.sh", reqPath, cfgHost]
        aiProc.running = true
    }

    function handleResponse(raw) {
        busy = false
        var obj
        try { obj = JSON.parse(raw) } catch (e) { errorText = "Bad response"; history.pop(); return }
        if (obj.error) {
            errorText = typeof obj.error === "string" ? obj.error : (obj.error.message || "Request failed")
            history.pop()
            return
        }
        var out = (obj.message && obj.message.content) ? obj.message.content : ""
        out = out.replace(/<think>[\s\S]*?<\/think>/g, "").trim()
        if (out === "") { errorText = "Empty answer"; history.pop(); return }
        history.push({ role: "assistant", content: out })
        chatModel.append({ role: "assistant", body: out })
        if (usageMonth !== currentMonth()) { usageMonth = currentMonth(); usedIn = 0; usedOut = 0 }
        usedIn  += obj.prompt_eval_count || 0
        usedOut += obj.eval_count || 0
        saveUsage()
    }

    // Hyprland keybind example:  bind = SUPER, A, exec, qs ipc call ai toggle
    IpcHandler {
        target: "ai"
        function toggle(): void { root.aiVisible = !root.aiVisible }
        function open(): void   { root.aiVisible = true }
        function close(): void  { root.aiVisible = false }
    }

    Connections {
        target: root
        function onAiVisibleChanged() {
            if (root.aiVisible) { aiPanel.refreshModels(); focusTimer.restart() }
        }
    }
    Timer {
        id: focusTimer
        interval: 150
        onTriggered: if (!aiPanel.showSetup) input.forceActiveFocus()
    }

    ListModel { id: chatModel }

    FileView {
        path: aiPanel.cfgPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                var c = JSON.parse(text())
                if (c.host) aiPanel.cfgHost = c.host
                if (c.model !== undefined) aiPanel.cfgModel = c.model
                if (c.monthly_limit) aiPanel.cfgLimit = c.monthly_limit
                aiPanel.refreshModels()
            } catch (e) {}
        }
    }
    FileView {
        id: usageReader
        path: aiPanel.usagePath
        onLoaded: {
            try {
                var u = JSON.parse(text())
                if (u.month === aiPanel.currentMonth()) {
                    aiPanel.usageMonth = u.month
                    aiPanel.usedIn  = u.input  || 0
                    aiPanel.usedOut = u.output || 0
                }
            } catch (e) {}
        }
    }
    FileView { id: usageWriter; path: aiPanel.usagePath; blockWrites: true }
    FileView { id: reqWriter;   path: aiPanel.reqPath;   blockWrites: true }
    FileView { id: cfgWriter;   path: aiPanel.cfgPath;   blockWrites: true }

    Process {
        id: tagsProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var obj = JSON.parse(this.text)
                    if (obj.__down || !obj.models) { aiPanel.ollamaState = "down"; aiPanel.models = []; return }
                    var names = []
                    for (var i = 0; i < obj.models.length; i++) names.push(obj.models[i].name)
                    aiPanel.models = names
                    aiPanel.ollamaState = "ready"
                    if (aiPanel.cfgModel === "" && names.length > 0) aiPanel.selectModel(names[0])
                } catch (e) { aiPanel.ollamaState = "down"; aiPanel.models = [] }
            }
        }
    }

    Process {
        id: aiProc
        stdout: StdioCollector {
            onStreamFinished: aiPanel.handleResponse(this.text)
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: zyuTheme.rounding
        color: zyuTheme.bar_bg
        border.width: 1
        border.color: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.22)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // ---- Header ----
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "󰚩  AI"
                    color: zyuTheme.bar_fg
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15; font.bold: true
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: modelLabel.implicitWidth + 20
                    radius: 12
                    color: modelMa.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05)
                    Text {
                        id: modelLabel
                        anchors.centerIn: parent
                        text: aiPanel.hasModel ? aiPanel.cfgModel + "  ▾" : "choose model  ▾"
                        color: aiPanel.hasModel ? zyuTheme.bar_fg : zyuTheme.accent
                        opacity: aiPanel.hasModel ? 0.6 : 1
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10
                    }
                    MouseArea {
                        id: modelMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { aiPanel.setupOpen = !aiPanel.setupOpen; if (aiPanel.setupOpen) aiPanel.refreshModels() }
                    }
                }
                Rectangle {
                    Layout.preferredWidth: 26; Layout.preferredHeight: 26; radius: 8
                    color: clearMa.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.18) : "transparent"
                    Text { anchors.centerIn: parent; text: "󰆴"; color: zyuTheme.bar_fg; opacity: 0.6
                           font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                    MouseArea { id: clearMa; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor; onClicked: aiPanel.clearChat() }
                }
            }

            // ---- Usage ----
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Rectangle {
                    Layout.fillWidth: true; height: 6; radius: 3
                    color: Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.12)
                    Rectangle {
                        height: parent.height; radius: 3
                        width: parent.width * aiPanel.ratio
                        color: aiPanel.ratio >= 0.9 ? "#f38ba8" : zyuTheme.accent
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: aiPanel.fmt(aiPanel.usedTotal) + " / " + aiPanel.fmt(aiPanel.cfgLimit) + " tokens"
                        color: zyuTheme.bar_fg; opacity: 0.7
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "in " + aiPanel.fmt(aiPanel.usedIn) + "  out " + aiPanel.fmt(aiPanel.usedOut) + "  ·  " + aiPanel.usageMonth
                        color: zyuTheme.bar_fg; opacity: 0.4
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9
                    }
                }
            }

            // ---- Ollama / model setup ----
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: aiPanel.showSetup
                spacing: 12

                Item { Layout.fillHeight: true }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    color: zyuTheme.bar_fg
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true
                    text: aiPanel.ollamaState === "checking" ? "Looking for Ollama…"
                        : aiPanel.ollamaState === "down" ? "Ollama isn't running"
                        : aiPanel.models.length === 0 ? "No models installed"
                        : "Choose a model"
                }

                Text {
                    Layout.fillWidth: true
                    visible: aiPanel.ollamaState === "down" || (aiPanel.ollamaState === "ready" && aiPanel.models.length === 0)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    color: zyuTheme.accent
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                    text: aiPanel.ollamaState === "down" ? "ollama serve" : "ollama pull llama3.2"
                }

                Text {
                    Layout.fillWidth: true
                    visible: aiPanel.ollamaState === "down" || (aiPanel.ollamaState === "ready" && aiPanel.models.length === 0)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    color: zyuTheme.bar_fg; opacity: 0.45
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10
                    text: aiPanel.ollamaState === "down"
                        ? "Install Ollama and start it, then press Retry."
                        : "Run this in a terminal, then press Retry."
                }

                Flow {
                    Layout.fillWidth: true
                    visible: aiPanel.ollamaState === "ready" && aiPanel.models.length > 0
                    spacing: 8
                    Repeater {
                        model: aiPanel.models
                        delegate: Rectangle {
                            id: chip
                            required property string modelData
                            width: chipText.implicitWidth + 24; height: 32; radius: 16
                            color: modelData === aiPanel.cfgModel
                                ? Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.28)
                                : (chipMa.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.06))
                            border.width: modelData === aiPanel.cfgModel ? 1 : 0
                            border.color: zyuTheme.accent
                            Text {
                                id: chipText
                                anchors.centerIn: parent
                                text: chip.modelData
                                color: chip.modelData === aiPanel.cfgModel ? zyuTheme.accent : zyuTheme.bar_fg
                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                            }
                            MouseArea {
                                id: chipMa
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: aiPanel.selectModel(chip.modelData)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 90; Layout.preferredHeight: 34; radius: 17
                        color: retryMa.containsMouse ? Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.32)
                                                     : Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.2)
                        border.width: 1; border.color: zyuTheme.accent
                        Text { anchors.centerIn: parent; text: "Retry"; color: zyuTheme.accent
                               font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.bold: true }
                        MouseArea { id: retryMa; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor; onClicked: aiPanel.refreshModels() }
                    }

                    Rectangle {
                        visible: aiPanel.ollamaState !== "checking"
                        Layout.preferredWidth: 150; Layout.preferredHeight: 34; radius: 17
                        color: browseMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                        Text { anchors.centerIn: parent; text: "Browse models  ↗"; color: zyuTheme.bar_fg
                               font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                        MouseArea { id: browseMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["xdg-open", "https://ollama.com/library"]) }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // ---- Chat ----
            ListView {
                id: chatView
                visible: !aiPanel.showSetup
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: chatModel
                spacing: 8
                clip: true
                onCountChanged: Qt.callLater(() => chatView.positionViewAtEnd())

                Text {
                    anchors.centerIn: parent
                    visible: chatModel.count === 0
                    horizontalAlignment: Text.AlignHCenter
                    text: "Ask something.\nRuns locally on your machine."
                    color: zyuTheme.bar_fg; opacity: 0.35
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                }

                delegate: Item {
                    id: msg
                    required property string role
                    required property string body
                    readonly property bool mine: role === "user"
                    width: chatView.width
                    height: bubble.height

                    Rectangle {
                        id: bubble
                        anchors.right: msg.mine ? parent.right : undefined
                        anchors.left:  msg.mine ? undefined : parent.left
                        width: Math.min(msg.width * 0.88, label.implicitWidth + 24)
                        height: label.implicitHeight + 16
                        radius: 12
                        color: msg.mine ? Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.22)
                                        : Qt.rgba(1, 1, 1, 0.06)
                        Text {
                            id: label
                            anchors.fill: parent
                            anchors.margins: 8
                            anchors.leftMargin: 12; anchors.rightMargin: 12
                            text: msg.body
                            textFormat: msg.mine ? Text.PlainText : Text.MarkdownText
                            wrapMode: Text.Wrap
                            color: zyuTheme.bar_fg
                            linkColor: zyuTheme.accent
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                            onLinkActivated: link => Qt.openUrlExternally(link)
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: !aiPanel.showSetup && (aiPanel.busy || aiPanel.errorText !== "")
                text: aiPanel.busy ? "Thinking…" : aiPanel.errorText
                wrapMode: Text.Wrap
                color: aiPanel.busy ? zyuTheme.bar_fg : "#f38ba8"
                opacity: aiPanel.busy ? 0.5 : 1
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
            }

            // ---- Input ----
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 22
                color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, input.activeFocus ? 0.5 : 0.15)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16; anchors.rightMargin: 8
                    spacing: 8

                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        color: zyuTheme.bar_fg
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                        clip: true
                        enabled: !aiPanel.busy && aiPanel.hasModel
                        onAccepted: { aiPanel.send(text); text = "" }
                        Keys.onEscapePressed: root.aiVisible = false

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Message…"
                            visible: !input.text.length
                            color: zyuTheme.bar_fg; opacity: 0.35
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 30; Layout.preferredHeight: 30; radius: 15
                        color: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, input.text.length > 0 && !aiPanel.busy ? 0.3 : 0.1)
                        Text { anchors.centerIn: parent; text: "󰒊"; color: zyuTheme.accent
                               font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { aiPanel.send(input.text); input.text = "" }
                        }
                    }
                }
            }
        }
    }
}

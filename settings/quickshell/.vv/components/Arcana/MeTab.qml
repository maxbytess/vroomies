import QtQuick
import QtQuick.Layouts
import "."

Item {
    id: root
    required property var th
    readonly property string nf: "JetBrainsMono Nerd Font"
    function icon(cp) { return String.fromCodePoint(cp) }

    RowLayout {
        anchors.fill: parent
        spacing: 14

        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: 300
            spacing: 14

            DashCard {
                th: root.th
                title: "Profile"; tintIndex: 0
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 104; Layout.preferredHeight: 104

                        Image {
                            id: pfpImage
                            anchors.fill: parent
                            source: root.th.ppActualPath !== "" ? "file://" + root.th.ppActualPath : ""
                            fillMode: Image.PreserveAspectCrop
                            smooth: true; cache: false; asynchronous: true
                            sourceSize.width: 208; sourceSize.height: 208
                            visible: false
                        }
                        Rectangle { id: pfpMask; anchors.fill: parent; radius: width / 2; visible: false }
                        OpacityMask {
                            anchors.fill: parent
                            source: pfpImage; maskSource: pfpMask
                            visible: pfpImage.status === Image.Ready
                        }
                        Rectangle {
                            anchors.fill: parent; radius: width / 2
                            color: "transparent"
                            border.width: 3; border.color: root.th.accent
                            Behavior on border.color { ColorAnimation { duration: 300 } }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: Quickshell.env("USER").charAt(0).toUpperCase()
                            color: root.th.accent
                            font.pixelSize: 40; font.bold: true
                            font.family: root.th.fontFam
                            visible: pfpImage.status !== Image.Ready
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.th.togglePpPicker()
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Quickshell.env("USER")
                        color: root.th.accent
                        font.pixelSize: 20; font.bold: true
                        font.family: root.th.fontFam
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "up " + root.th.uptimeStr
                        color: root.th.muted
                        font.pixelSize: 11
                        font.family: root.th.fontFam
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: chgText.implicitWidth + 24
                        Layout.preferredHeight: 28
                        radius: 14
                        color: chgMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
                        Text {
                            id: chgText
                            anchors.centerIn: parent
                            text: root.th.ppPickerOpen ? "Close" : "Change picture  (M)"
                            color: root.th.muted
                            font.pixelSize: 10; font.family: root.th.fontFam
                        }
                        MouseArea {
                            id: chgMa
                            anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.th.togglePpPicker()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.th.ppPickerOpen
                        color: Qt.rgba(0, 0, 0, 0.2)
                        radius: 10
                        clip: true

                        Flickable {
                            anchors.fill: parent
                            anchors.margins: 8
                            contentWidth: width
                            contentHeight: ppGrid.implicitHeight
                            clip: true

                            GridLayout {
                                id: ppGrid
                                width: parent.width
                                columns: 5
                                rowSpacing: 6; columnSpacing: 6

                                Repeater {
                                    model: root.th.ppFiles
                                    Item {
                                        required property var modelData
                                        Layout.preferredWidth: 44; Layout.preferredHeight: 44
                                        Image {
                                            id: thumbImg
                                            anchors.fill: parent
                                            source: "file://" + modelData
                                            fillMode: Image.PreserveAspectCrop
                                            smooth: false; cache: true; asynchronous: true
                                            sourceSize.width: 64; sourceSize.height: 64
                                            visible: false
                                        }
                                        Rectangle { id: thumbMask; anchors.fill: parent; radius: width / 2; visible: false }
                                        OpacityMask {
                                            anchors.fill: parent
                                            source: thumbImg; maskSource: thumbMask
                                            visible: thumbImg.status === Image.Ready
                                        }
                                        Rectangle {
                                            anchors.fill: parent; radius: width / 2
                                            color: Qt.rgba(1, 1, 1, 0.07)
                                            visible: thumbImg.status !== Image.Ready
                                        }
                                        Rectangle {
                                            anchors.fill: parent; radius: width / 2
                                            color: "transparent"
                                            border.width: 2; border.color: root.th.accent
                                            visible: modelData === root.th.ppActualPath
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.th.pickPp(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true; visible: !root.th.ppPickerOpen }
                }
            }

            DashCard {
                th: root.th
                title: "Quick actions"; tintIndex: 3
                Layout.fillWidth: true
                Layout.preferredHeight: 108

                Row {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 14
                    spacing: 10

                    Repeater {
                        model: [
                            { key: "idle",  cp: root.th.idleOn ? 0xF04B2 : 0xF04B3, active: root.th.idleOn },
                            { key: "shot",  cp: 0xF0100, active: false },
                            { key: "lock",  cp: 0xF033E, active: false },
                            { key: "power", cp: 0x23FB,  active: false }
                        ]
                        Rectangle {
                            required property var modelData
                            width: 52; height: 44; radius: 12
                            color: modelData.active
                                ? Qt.rgba(root.th.accent.r, root.th.accent.g, root.th.accent.b, 0.18)
                                : (qaMa.containsMouse
                                    ? (modelData.key === "power" ? Qt.rgba(root.th.col1.r, root.th.col1.g, root.th.col1.b, 0.2) : Qt.rgba(1, 1, 1, 0.08))
                                    : Qt.rgba(1, 1, 1, 0.04))
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text {
                                anchors.centerIn: parent
                                text: root.icon(modelData.cp)
                                color: modelData.active ? root.th.accent : (modelData.key === "power" ? root.th.col1 : root.th.muted)
                                font.pixelSize: 18
                                font.family: root.nf
                            }
                            MouseArea {
                                id: qaMa
                                anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.key === "idle")       root.th.toggleIdle()
                                    else if (modelData.key === "shot")  root.th.takeScreenshot()
                                    else if (modelData.key === "lock")  root.th.lockScreen()
                                    else                                root.th.powerMenu()
                                }
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: 340
            spacing: 14

            DashCard {
                th: root.th
                title: "Battery"; tintIndex: 2
                Layout.fillWidth: true
                Layout.preferredHeight: 120

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    anchors.topMargin: 2
                    spacing: 14
                    Text {
                        text: root.icon(root.th.batIconCp)
                        color: root.th.batVal <= 20 && root.th.batStatusText !== "Charging..." ? root.th.col1 : root.th.col2
                        font.pixelSize: 38
                        font.family: root.nf
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: root.th.batVal + "%"
                            color: root.th.fg
                            font.pixelSize: 22; font.bold: true
                            font.family: root.th.fontFam
                        }
                        Text {
                            text: root.th.batStatusText
                            color: root.th.muted
                            font.pixelSize: 10
                            font.family: root.th.fontFam
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 5; radius: 2.5
                            color: Qt.rgba(1, 1, 1, 0.10)
                            Rectangle {
                                width: parent.width * root.th.batVal / 100
                                height: parent.height; radius: 2.5
                                color: root.th.col2
                                Behavior on width { NumberAnimation { duration: 200 } }
                            }
                        }
                    }
                }
            }

            DashCard {
                th: root.th
                title: "System"; tintIndex: 1
                Layout.fillWidth: true
                Layout.preferredHeight: 170

                Row {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 14
                    spacing: 8

                    Repeater {
                        model: [
                            { label: "CPU",  cp: 0xF061A, value: root.th.cpuVal,  color: root.th.col1 },
                            { label: "RAM",  cp: 0xF035B, value: root.th.ramVal,  color: root.th.accent },
                            { label: "DISK", cp: 0xF02CA, value: root.th.diskVal, color: root.th.col3 },
                            { label: "TEMP", cp: 0xF050F, value: root.th.tempVal, color: root.th.col2 }
                        ]
                        Item {
                            required property var modelData
                            width: 72; height: 100
                            Column {
                                anchors.centerIn: parent
                                spacing: 6
                                Item {
                                    width: 64; height: 64
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    Canvas {
                                        anchors.fill: parent
                                        property int val: modelData.value
                                        property color col: modelData.color
                                        onValChanged: requestPaint()
                                        onColChanged: requestPaint()
                                        onPaint: {
                                            var ctx = getContext("2d")
                                            ctx.clearRect(0, 0, width, height)
                                            ctx.lineWidth = 5; ctx.lineCap = "round"
                                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08)
                                            ctx.beginPath(); ctx.arc(32, 32, 27, 0, 2 * Math.PI); ctx.stroke()
                                            ctx.strokeStyle = col
                                            ctx.beginPath()
                                            ctx.arc(32, 32, 27, -Math.PI / 2, -Math.PI / 2 + (val / 100) * 2 * Math.PI)
                                            ctx.stroke()
                                        }
                                    }
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 1
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: root.icon(modelData.cp)
                                            color: modelData.color
                                            font.pixelSize: 13
                                            font.family: root.nf
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.value + (modelData.label === "TEMP" ? "°" : "%")
                                            color: root.th.fg
                                            font.pixelSize: 11
                                            font.family: root.th.fontFam
                                        }
                                    }
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    color: root.th.muted
                                    font.pixelSize: 9
                                    font.family: root.th.fontFam
                                }
                            }
                        }
                    }
                }
            }

            DashCard {
                th: root.th
                title: "Sound & light"; tintIndex: 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 110

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    anchors.topMargin: 4
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            Layout.preferredWidth: 22
                            text: root.icon(root.th.volVal === 0 ? 0xF075F : root.th.volVal < 50 ? 0xF0580 : 0xF057E)
                            color: root.th.col3
                            font.pixelSize: 17; font.family: root.nf
                            horizontalAlignment: Text.AlignHCenter
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: root.th.toggleMute()
                            }
                        }
                        Rectangle {
                            id: volTrack
                            Layout.fillWidth: true
                            height: 6; radius: 3
                            color: Qt.rgba(1, 1, 1, 0.1)
                            Rectangle {
                                width: parent.width * root.th.volVal / 100
                                height: parent.height; radius: 3; color: root.th.col3
                                Behavior on width { NumberAnimation { duration: 100 } }
                            }
                            MouseArea {
                                anchors.fill: parent; anchors.topMargin: -8; anchors.bottomMargin: -8
                                cursorShape: Qt.PointingHandCursor
                                onPressed: (mouse) => root.th.setVolume(Math.round(mouse.x / width * 100))
                                onPositionChanged: (mouse) => { if (pressed) root.th.setVolume(Math.round(mouse.x / width * 100)) }
                            }
                        }
                        Text {
                            Layout.preferredWidth: 34
                            text: root.th.volVal + "%"
                            color: root.th.muted; font.pixelSize: 10; font.family: root.th.fontFam
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            Layout.preferredWidth: 22
                            text: root.icon(root.th.brightVal < 30 ? 0xF00DE : root.th.brightVal < 70 ? 0xF00DF : 0xF00E0)
                            color: root.th.col1
                            font.pixelSize: 17; font.family: root.nf
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 6; radius: 3
                            color: Qt.rgba(1, 1, 1, 0.1)
                            Rectangle {
                                width: parent.width * root.th.brightVal / 100
                                height: parent.height; radius: 3; color: root.th.col1
                                Behavior on width { NumberAnimation { duration: 100 } }
                            }
                            MouseArea {
                                anchors.fill: parent; anchors.topMargin: -8; anchors.bottomMargin: -8
                                cursorShape: Qt.PointingHandCursor
                                onPressed: (mouse) => root.th.setBrightness(Math.round(mouse.x / width * 100))
                                onPositionChanged: (mouse) => { if (pressed) root.th.setBrightness(Math.round(mouse.x / width * 100)) }
                            }
                        }
                        Text {
                            Layout.preferredWidth: 34
                            text: root.th.brightVal + "%"
                            color: root.th.muted; font.pixelSize: 10; font.family: root.th.fontFam
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }

        DashCard {
            th: root.th
            title: "Notifications"; tintIndex: 1
            Layout.fillHeight: true
            Layout.fillWidth: true

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 12
                y: 6
                spacing: 6

                Rectangle {
                    width: 28; height: 28; radius: 8
                    color: root.th.doNotDisturb
                        ? Qt.rgba(root.th.col1.r, root.th.col1.g, root.th.col1.b, 0.25)
                        : (dndMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text {
                        anchors.centerIn: parent
                        text: root.icon(root.th.doNotDisturb ? 0xF009B : 0xF009A)
                        color: root.th.doNotDisturb ? root.th.col1 : root.th.muted
                        font.pixelSize: 14; font.family: root.nf
                    }
                    MouseArea {
                        id: dndMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.th.doNotDisturb = !root.th.doNotDisturb
                    }
                }
                Rectangle {
                    width: 28; height: 28; radius: 8
                    visible: (root.th.notifs.trackedNotifications.values?.length ?? 0) > 0
                    color: clrMa.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: root.icon(0xF01B4)
                        color: root.th.muted
                        font.pixelSize: 14; font.family: root.nf
                    }
                    MouseArea {
                        id: clrMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var l = root.th.notifs.trackedNotifications.values ?? []
                            for (var i = l.length - 1; i >= 0; i--) l[i].dismiss()
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 26; radius: 8
                    visible: root.th.doNotDisturb
                    color: Qt.rgba(root.th.col1.r, root.th.col1.g, root.th.col1.b, 0.12)
                    Text {
                        anchors.centerIn: parent
                        text: root.icon(0xF009B) + "  Rahatsız etme modu açık"
                        color: root.th.col1
                        font.pixelSize: 10; font.family: root.th.fontFam
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: notifCol.implicitHeight
                    clip: true

                    Column {
                        id: notifCol
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: root.th.notifs.trackedNotifications.values ?? []
                            Rectangle {
                                required property var modelData
                                width: notifCol.width
                                height: notifRow.implicitHeight + 16
                                radius: 10
                                color: Qt.rgba(1, 1, 1, 0.04)

                                RowLayout {
                                    id: notifRow
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 10
                                    Rectangle {
                                        Layout.preferredWidth: 32; Layout.preferredHeight: 32
                                        Layout.alignment: Qt.AlignTop
                                        radius: 8
                                        color: root.th.surface
                                        Text {
                                            anchors.centerIn: parent
                                            text: (modelData.appName || "?").charAt(0).toUpperCase()
                                            color: root.th.accent
                                            font.pixelSize: 13; font.bold: true
                                            font.family: root.th.fontFam
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.summary || modelData.appName || "Notification"
                                            color: root.th.fg
                                            font.pixelSize: 11; font.bold: true
                                            elide: Text.ElideRight
                                            font.family: root.th.fontFam
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            visible: (modelData.body || "") !== ""
                                            text: modelData.body || ""
                                            color: root.th.muted
                                            font.pixelSize: 10
                                            wrapMode: Text.WordWrap
                                            maximumLineCount: 4
                                            elide: Text.ElideRight
                                            font.family: root.th.fontFam
                                        }
                                    }
                                    Rectangle {
                                        Layout.preferredWidth: 20; Layout.preferredHeight: 20
                                        Layout.alignment: Qt.AlignTop
                                        radius: 5
                                        color: xMa.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                                        Text { anchors.centerIn: parent; text: "✕"; color: root.th.muted; font.pixelSize: 10; font.family: root.th.fontFam }
                                        MouseArea { id: xMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.dismiss() }
                                    }
                                }
                            }
                        }

                        Item {
                            width: notifCol.width
                            height: 60
                            visible: (root.th.notifs.trackedNotifications.values?.length ?? 0) === 0
                            Text {
                                anchors.centerIn: parent
                                text: "No notifications " + root.icon(0xF009B)
                                color: root.th.muted
                                font.pixelSize: 11
                                font.family: root.th.fontFam
                            }
                        }
                    }
                }
            }
        }
    }
}

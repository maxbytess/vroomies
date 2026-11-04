import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

Scope {
    id: notifRoot

    property color bg0: adapter.bg0
    property color bg1: adapter.bg1
    property color text: adapter.text
    property color blue: adapter.blue
    property color grey1: adapter.grey1

    FileView {
        path: Qt.resolvedUrl("colors.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            property string bg0: "#0f1511"
            property string bg1: "#1b211d"
            property string text: "#dee4de"
            property string blue: "#90d5ae"
            property string grey1: "#8a938c"
        }
    }

    NotificationServer {
        id: notificationServer

        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        imageSupported: true
        persistenceSupported: false

        onNotification: notification => {
            notification.tracked = true
        }
    }

    PanelWindow {
        id: notifWindow

        visible: notificationServer.trackedNotifications.values.length > 0

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: false

        anchors {
            top: true
            right: true
        }

        margins {
            top: 56
            right: 15
        }

        implicitWidth: 350
        implicitHeight: Math.min(notifCol.implicitHeight, 600)

        Flickable {
            anchors.fill: parent

            contentWidth: width
            contentHeight: notifCol.implicitHeight
            clip: true

            ColumnLayout {
                id: notifCol

                width: parent.width
                spacing: 10

                Repeater {
                    model: notificationServer.trackedNotifications

                    delegate: Rectangle {
                        required property var modelData

                        property var notification: modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(
                            notifText.implicitHeight + 24,
                            64
                        )

                        topLeftRadius: 0
                        topRightRadius: 12
                        bottomLeftRadius: 0
                        bottomRightRadius: 12

                        color: bg0

                        border {
                            color: blue
                            width: 1
                        }

                        opacity: 0

                        Component.onCompleted: opacity = 1

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                            }
                        }

                        Timer {
                            id: expireTimer

                            interval: 5000
                            repeat: false
                            running: true

                            onTriggered: {
                                if (notification.tracked)
                                    notification.expire()
                            }
                        }

                        Rectangle {
                            id: closeBtn

                            width: 28
                            height: 28

                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                rightMargin: 22
                            }

                            z: 2
                            radius: 7

                            color: closeMa.containsMouse
                                ? Qt.rgba(255, 255, 255, 0.15)
                                : "transparent"

                            Text {
                                anchors.centerIn: parent

                                text: "✕"
                                color: Qt.rgba(255, 255, 255, 0.8)

                                font.family: "DaddyTime Nerd Font"
                                font.pixelSize: 16
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                id: closeMa

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    if (notification.tracked)
                                        notification.dismiss()
                                }
                            }
                        }

                        Column {
                            id: notifText

                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right

                                topMargin: 12
                                leftMargin: 12
                                rightMargin: 60
                            }

                            spacing: 4

                            Text {
                                width: parent.width

                                text: notification.summary
                                color: "#ffffff"

                                font.family: "DaddyTime Nerd Font"
                                font.pixelSize: 12
                                font.bold: true

                                wrapMode: Text.WordWrap
                            }

                            Text {
                                width: parent.width

                                text: notification.body
                                color: Qt.rgba(255, 255, 255, 0.7)

                                font.family: "DaddyTime Nerd Font"
                                font.pixelSize: 11

                                wrapMode: Text.WordWrap
                                visible: text !== ""
                            }
                        }
                    }
                }
            }
        }
    }
}


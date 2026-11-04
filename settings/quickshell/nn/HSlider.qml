import QtQuick

Item {
    id: root

    property real value: 0
    property color trackColor: "#22242b"
    property color fillColor: "#a1bdce"
    readonly property bool dragging: area.pressed
    signal moved(real v)

    implicitWidth: 70
    implicitHeight: 10

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.trackColor
    }

    Rectangle {
        width: parent.width * Math.max(0, Math.min(100, root.value)) / 100
        height: parent.height
        radius: height / 2
        color: root.fillColor
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        cursorShape: Qt.PointingHandCursor

        function setFrom(x) {
            root.moved(Math.max(0, Math.min(100, 100 * x / width)))
        }
        onPressed: mouse => setFrom(mouse.x)
        onPositionChanged: mouse => { if (pressed) setFrom(mouse.x) }
    }
}

import QtQuick

Item {
    id: root
    property real value: 0
    property color color: "#ffffff"
    property color track: Qt.rgba(1, 1, 1, 0.08)
    property real lineWidth: 8

    onValueChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var r = Math.max(1, Math.min(width, height) / 2 - root.lineWidth / 2 - 1)
            var cx = width / 2, cy = height / 2
            ctx.lineWidth = root.lineWidth
            ctx.lineCap = "round"
            ctx.strokeStyle = root.track
            ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2 * Math.PI); ctx.stroke()
            var v = Math.max(0, Math.min(1, root.value))
            if (v > 0.002) {
                ctx.strokeStyle = root.color
                ctx.beginPath()
                ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + v * 2 * Math.PI)
                ctx.stroke()
            }
        }
    }
}

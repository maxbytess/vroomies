import QtQuick

Item {
    id: root
    property var values: []
    property real peak: 0
    property color color: "#ffffff"
    property real lineWidth: 2

    onValuesChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var v = root.values
            if (!v || v.length < 2) return
            var mx = root.peak > 0 ? root.peak : 0
            if (mx <= 0) { for (var i = 0; i < v.length; i++) mx = Math.max(mx, v[i]); mx = Math.max(mx, 1) }
            var pad = root.lineWidth
            var h = height - pad * 2
            var step = width / (v.length - 1)
            function px(i) { return i * step }
            function py(i) { return pad + h - Math.min(1, v[i] / mx) * h }

            ctx.beginPath()
            ctx.moveTo(px(0), py(0))
            for (var k = 1; k < v.length; k++) {
                var mxp = (px(k - 1) + px(k)) / 2
                var myp = (py(k - 1) + py(k)) / 2
                ctx.quadraticCurveTo(px(k - 1), py(k - 1), mxp, myp)
            }
            ctx.lineTo(px(v.length - 1), py(v.length - 1))
            ctx.lineWidth = root.lineWidth
            ctx.lineJoin = "round"
            ctx.strokeStyle = root.color
            ctx.stroke()

            ctx.lineTo(px(v.length - 1), height)
            ctx.lineTo(px(0), height)
            ctx.closePath()
            var g = ctx.createLinearGradient(0, 0, 0, height)
            g.addColorStop(0, Qt.rgba(root.color.r, root.color.g, root.color.b, 0.30))
            g.addColorStop(1, Qt.rgba(root.color.r, root.color.g, root.color.b, 0.0))
            ctx.fillStyle = g
            ctx.fill()
        }
    }
}

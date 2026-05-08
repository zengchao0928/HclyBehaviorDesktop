import QtQuick

Item {
    id: root
    width: 52
    height: 52
    opacity: 0.92

    property color normalColor: "#20346C"
    property color pressedColor: "#304A94"
    property color borderColor: "#8EA0D2"
    property color iconColor: "#FFFFFF"
    property real borderWidth: 1.4
    property real iconStrokeWidth: 4.6

    signal clicked()

    Canvas {
        id: canvas
        anchors.fill: parent

        function drawChevron(ctx, size) {
            var center = size / 2
            var chevronHalfWidth = size * 0.12
            var chevronHalfHeight = size * 0.16

            ctx.strokeStyle = root.iconColor
            ctx.lineWidth = root.iconStrokeWidth
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.beginPath()
            ctx.moveTo(center + chevronHalfWidth, center - chevronHalfHeight)
            ctx.lineTo(center - chevronHalfWidth, center)
            ctx.lineTo(center + chevronHalfWidth, center + chevronHalfHeight)
            ctx.stroke()
        }

        onPaint: {
            var ctx = getContext("2d")
            var size = Math.min(width, height)
            var center = size / 2
            var radius = center - root.borderWidth - 1

            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            ctx.globalAlpha = root.opacity
            ctx.fillStyle = backArea.pressed ? root.pressedColor : root.normalColor
            ctx.beginPath()
            ctx.arc(center, center, radius, 0, Math.PI * 2)
            ctx.fill()

            ctx.globalAlpha = 1
            ctx.strokeStyle = root.borderColor
            ctx.lineWidth = root.borderWidth
            ctx.beginPath()
            ctx.arc(center, center, radius, 0, Math.PI * 2)
            ctx.stroke()

            drawChevron(ctx, size)
        }
    }

    MouseArea {
        id: backArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onPressedChanged: canvas.requestPaint()
    }

    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
    onNormalColorChanged: canvas.requestPaint()
    onPressedColorChanged: canvas.requestPaint()
    onBorderColorChanged: canvas.requestPaint()
    onIconColorChanged: canvas.requestPaint()
    onBorderWidthChanged: canvas.requestPaint()
    onIconStrokeWidthChanged: canvas.requestPaint()

    Component.onCompleted: canvas.requestPaint()
}

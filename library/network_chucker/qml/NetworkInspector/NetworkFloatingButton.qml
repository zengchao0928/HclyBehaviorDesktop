import QtQuick 2.15

Item {
    id: floatingButton
    property var inspector: null
    signal clicked()

    width: 76
    height: 76
    visible: inspector && inspector.enabled

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: floatingMouseArea.pressed ? "#1F6FB2" : "#2389D7"
        border.color: "#BFE6FF"
        border.width: 1

        Canvas {
            id: networkIcon
            anchors.centerIn: parent
            width: 42
            height: 42

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = "#FFFFFF"
                ctx.fillStyle = "#FFFFFF"
                ctx.lineWidth = 3
                ctx.lineCap = "round"

                ctx.beginPath()
                ctx.moveTo(21, 20)
                ctx.lineTo(21, 9)
                ctx.moveTo(21, 20)
                ctx.lineTo(10, 31)
                ctx.moveTo(21, 20)
                ctx.lineTo(32, 31)
                ctx.stroke()

                drawNode(ctx, 21, 20, 5)
                drawNode(ctx, 21, 8, 5)
                drawNode(ctx, 9, 32, 5)
                drawNode(ctx, 33, 32, 5)
            }

            function drawNode(ctx, x, y, radius) {
                ctx.beginPath()
                ctx.arc(x, y, radius, 0, Math.PI * 2)
                ctx.fill()
            }
        }
    }

    Rectangle {
        visible: inspector && inspector.count > 0
        width: Math.max(24, countText.implicitWidth + 10)
        height: 24
        radius: 12
        anchors.right: parent.right
        anchors.top: parent.top
        color: "#E94E4E"
        border.color: "#FFFFFF"
        border.width: 1

        Text {
            id: countText
            anchors.centerIn: parent
            text: inspector ? Math.min(inspector.count, 99) : 0
            color: "#FFFFFF"
            font.pixelSize: 13
            font.bold: true
        }
    }

    MouseArea {
        id: floatingMouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        
        property bool longPressActive: false
        
        onClicked: {
            if (!longPressActive) {
                floatingButton.clicked()
            }
        }
        
        onPressAndHold: {
            longPressActive = true
            if (inspector) {
                inspector.setEnabled(false)
            }
        }
        
        onReleased: {
            longPressActive = false
        }
    }
}

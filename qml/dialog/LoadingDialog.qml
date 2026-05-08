import QtQuick
import QtQuick.Controls

// 通用 Loading 遮罩组件
Rectangle {
    id: root
    anchors.fill: parent
    color: "#B0060D18"
    visible: active || opacity > 0.01
    opacity: active ? 1 : 0
    z: 999
    
    // 自定义属性
    property string loadingText: "请稍等"
    property int panelSize: 188
    property bool active: false
    signal dismissed()

    Behavior on opacity {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    // 点击遮罩背景时关闭 loading，面板自身会阻止事件继续传递。
    MouseArea {
        anchors.fill: parent
        enabled: root.active
        onClicked: root.dismiss()
    }

    Rectangle {
        id: panel
        width: root.panelSize
        height: 172
        anchors.centerIn: parent
        color: "#D90B1625"
        radius: 8
        opacity: 0.98
        scale: root.active ? 1 : 0.94
        antialiasing: true
        border.width: 1
        border.color: "#3DEBFF"

        Rectangle {
            anchors.fill: parent
            anchors.margins: -7
            radius: panel.radius + 7
            color: "transparent"
            border.width: 1
            border.color: "#31E6FF"
            opacity: root.active ? 0.34 : 0
            antialiasing: true

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: root.active

                NumberAnimation {
                    from: 0.18
                    to: 0.5
                    duration: 780
                    easing.type: Easing.OutQuad
                }

                NumberAnimation {
                    from: 0.5
                    to: 0.18
                    duration: 780
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutBack
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) {
                mouse.accepted = true
            }
        }
        
        Column {
            anchors.centerIn: parent
            spacing: 10
            
            // 霓虹扫描核心：双层反向旋转光栅、轨道粒子和脉冲外环。
            Item {
                id: spinner
                width: 100
                height: 100
                anchors.horizontalCenter: parent.horizontalCenter

                Canvas {
                    id: ringCanvas
                    anchors.centerIn: parent
                    width: spinner.width * renderScale
                    height: spinner.height * renderScale
                    scale: 1 / renderScale
                    transformOrigin: Item.Center
                    antialiasing: true
                    smooth: true
                    renderTarget: Canvas.Image
                    renderStrategy: Canvas.Immediate
                    property int renderScale: 3
                    property real pulseRadius: 38
                    property real pulseOpacity: 0.1

                    onPulseRadiusChanged: requestPaint()
                    onPulseOpacityChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d")
                        var cx = width / 2
                        var cy = height / 2

                        ctx.clearRect(0, 0, width, height)
                        ctx.lineCap = "round"

                        // 用高分辨率 Canvas 画圆环，避免 Linux software backend 缩放圆角边框产生锯齿。
                        drawRing(ctx, cx, cy, pulseRadius * renderScale, 5.5 * renderScale,
                                 "rgba(30, 214, 255, " + (pulseOpacity * 0.28) + ")")
                        drawRing(ctx, cx, cy, pulseRadius * renderScale, 1.5 * renderScale,
                                 "rgba(124, 255, 234, " + pulseOpacity + ")")
                        drawRing(ctx, cx, cy, 36 * renderScale, 1.2 * renderScale,
                                 "rgba(107, 140, 255, 0.24)")
                        drawRing(ctx, cx, cy, 24 * renderScale, 1 * renderScale,
                                 "rgba(56, 232, 255, 0.18)")
                    }

                    SequentialAnimation on pulseRadius {
                        loops: Animation.Infinite
                        running: root.active

                        NumberAnimation {
                            from: 38
                            to: 52
                            duration: 900
                            easing.type: Easing.OutQuad
                        }

                        NumberAnimation {
                            from: 52
                            to: 38
                            duration: 900
                            easing.type: Easing.InOutQuad
                        }
                    }

                    SequentialAnimation on pulseOpacity {
                        loops: Animation.Infinite
                        running: root.active

                        NumberAnimation {
                            from: 0.08
                            to: 0.28
                            duration: 900
                        }

                        NumberAnimation {
                            from: 0.28
                            to: 0.08
                            duration: 900
                        }
                    }

                    function drawRing(ctx, cx, cy, radius, lineWidth, color) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, radius, 0, Math.PI * 2, false)
                        ctx.lineWidth = lineWidth
                        ctx.strokeStyle = color
                        ctx.stroke()
                    }
                }

                Item {
                    id: outerRing
                    anchors.fill: parent
                    layer.enabled: true
                    layer.smooth: true

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 980
                        loops: Animation.Infinite
                        running: root.active
                    }

                    Repeater {
                        model: 28

                        Rectangle {
                            width: index % 7 === 0 ? 4 : 3
                            height: index % 7 === 0 ? 16 : 8
                            radius: width / 2
                            color: index % 4 === 0 ? "#7CFFEA" : (index % 4 === 1 ? "#28D7FF" : (index % 4 === 2 ? "#6C8CFF" : "#FFFFFF"))
                            opacity: index % 7 === 0 ? 0.92 : 0.18
                            antialiasing: true
                            x: spinner.width / 2 - width / 2
                            y: 1

                            transform: Rotation {
                                origin.x: width / 2
                                origin.y: spinner.height / 2 - y
                                angle: index * 360 / 28
                            }
                        }
                    }
                }

                Item {
                    id: innerRing
                    anchors.centerIn: parent
                    width: 74
                    height: 74
                    layer.enabled: true
                    layer.smooth: true

                    RotationAnimator on rotation {
                        from: 360
                        to: 0
                        duration: 1380
                        loops: Animation.Infinite
                        running: root.active
                    }

                    Repeater {
                        model: 18

                        Rectangle {
                            width: 3
                            height: index % 3 === 0 ? 12 : 6
                            radius: 1.5
                            color: "#30F1FF"
                            opacity: index % 3 === 0 ? 0.78 : 0.18
                            antialiasing: true
                            x: innerRing.width / 2 - width / 2
                            y: 0

                            transform: Rotation {
                                origin.x: width / 2
                                origin.y: innerRing.height / 2 - y
                                angle: index * 20
                            }
                        }
                    }
                }

                Item {
                    id: particleOrbit
                    anchors.fill: parent
                    layer.enabled: true
                    layer.smooth: true

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 1240
                        loops: Animation.Infinite
                        running: root.active
                    }

                    Repeater {
                        model: 4

                        Rectangle {
                            width: index === 0 ? 8 : 5
                            height: width
                            radius: width / 2
                            color: index === 0 ? "#FFFFFF" : "#67F7FF"
                            opacity: index === 0 ? 0.95 : 0.58
                            x: spinner.width / 2 - width / 2
                            y: 5

                            transform: Rotation {
                                origin.x: width / 2
                                origin.y: spinner.height / 2 - y
                                angle: index * 90
                            }
                        }
                    }
                }

                Canvas {
                    id: coreCanvas
                    anchors.centerIn: parent
                    width: 42 * renderScale
                    height: 42 * renderScale
                    scale: 1 / renderScale
                    transformOrigin: Item.Center
                    antialiasing: true
                    smooth: true
                    renderTarget: Canvas.Image
                    renderStrategy: Canvas.Immediate
                    property int renderScale: 3
                    property real coreRadius: 15

                    onCoreRadiusChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d")
                        var cx = width / 2
                        var cy = height / 2

                        ctx.clearRect(0, 0, width, height)
                        ctx.lineCap = "round"

                        drawFilledCircle(ctx, cx, cy, coreRadius * renderScale,
                                         "rgba(16, 29, 50, 0.94)")
                        drawRing(ctx, cx, cy, coreRadius * renderScale, 1.25 * renderScale,
                                 "rgba(169, 250, 255, 0.9)")
                        drawFilledCircle(ctx, cx, cy, 6 * renderScale,
                                         "rgba(111, 255, 242, 0.92)")
                    }

                    SequentialAnimation on coreRadius {
                        loops: Animation.Infinite
                        running: root.active

                        NumberAnimation {
                            from: 15
                            to: 18
                            duration: 520
                            easing.type: Easing.OutQuad
                        }

                        NumberAnimation {
                            from: 18
                            to: 15
                            duration: 520
                            easing.type: Easing.InOutQuad
                        }
                    }

                    function drawRing(ctx, cx, cy, radius, lineWidth, color) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, radius, 0, Math.PI * 2, false)
                        ctx.lineWidth = lineWidth
                        ctx.strokeStyle = color
                        ctx.stroke()
                    }

                    function drawFilledCircle(ctx, cx, cy, radius, color) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, radius, 0, Math.PI * 2, false)
                        ctx.fillStyle = color
                        ctx.fill()
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 82
                    height: 1
                    color: "#38E8FF"
                    opacity: 0.26
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 82
                    color: "#38E8FF"
                    opacity: 0.2
                }
            }
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: panel.width - 30
                text: root.loadingText
                font.pixelSize: 15
                color: "#D9FBFF"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Rectangle {
                width: 78
                height: 2
                radius: 1
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#3DEBFF"
                opacity: 0.48
            }
        }
    }

    function showLoading(text) {
        loadingText = text && text.length > 0 ? text : "请稍等"
        active = true
    }

    function hideLoading() {
        active = false
    }

    // 用户主动关闭（与 hideLoading 区分：hideLoading 多用于业务流程结束时自动隐藏）
    function dismiss() {
        if (!active) {
            return
        }
        active = false
        dismissed()
    }
}

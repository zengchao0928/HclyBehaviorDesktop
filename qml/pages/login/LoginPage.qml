import QtQuick
import QtQuick.Controls
import "../../components"
import "../../dialog"
import "../../" as Root

Item {
    id: loginPage
    width: parent.width
    height: parent.height
    clip: true
    property bool loginPending: false
    property bool passwordVisible: false

    component LoginInputIconButton: Item {
        id: iconButton

        property string iconType: "clear"
        property bool active: false
        property bool filledBackground: false
        property string tooltipText: ""
        property color iconColor: active ? "#2F80C7" : "#697785"

        signal clicked()

        implicitWidth: 26
        implicitHeight: 26

        Rectangle {
            anchors.fill: parent
            radius: 13
            color: {
                if (iconMouseArea.pressed) {
                    return "#D7E7F5"
                }
                if (iconMouseArea.containsMouse) {
                    return "#EEF5FB"
                }
                return iconButton.filledBackground ? "#F2F6FA" : "transparent"
            }
            border.color: iconButton.filledBackground ? "#DDE8F1" : "transparent"
            border.width: iconButton.filledBackground ? 1 : 0
        }

        Canvas {
            id: iconCanvas
            anchors.centerIn: parent
            width: 18
            height: 18

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = iconButton.iconColor
                ctx.fillStyle = iconButton.iconColor
                ctx.lineWidth = 2
                ctx.lineCap = "round"
                ctx.lineJoin = "round"

                if (iconButton.iconType === "eye") {
                    ctx.beginPath()
                    ctx.moveTo(2.5, height / 2)
                    ctx.quadraticCurveTo(width / 2, 3.2, width - 2.5, height / 2)
                    ctx.quadraticCurveTo(width / 2, height - 3.2, 2.5, height / 2)
                    ctx.stroke()

                    ctx.beginPath()
                    ctx.arc(width / 2, height / 2, 2.7, 0, Math.PI * 2)
                    ctx.fill()

                    if (!iconButton.active) {
                        ctx.beginPath()
                        ctx.moveTo(3.5, height - 3.5)
                        ctx.lineTo(width - 3.5, 3.5)
                        ctx.stroke()
                    }
                    return
                }

                ctx.beginPath()
                ctx.moveTo(5, 5)
                ctx.lineTo(width - 5, height - 5)
                ctx.moveTo(width - 5, 5)
                ctx.lineTo(5, height - 5)
                ctx.stroke()
            }

            Connections {
                target: iconButton

                function onActiveChanged() {
                    iconCanvas.requestPaint()
                }

                function onIconTypeChanged() {
                    iconCanvas.requestPaint()
                }

                function onIconColorChanged() {
                    iconCanvas.requestPaint()
                }
            }
        }

        MouseArea {
            id: iconMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: iconButton.clicked()
        }

        ToolTip.visible: tooltipText.length > 0 && iconMouseArea.containsMouse
        ToolTip.delay: 400
        ToolTip.text: tooltipText
    }

    Component.onCompleted: {
        if (typeof networkInspector !== "undefined" && networkInspector) {
            networkInspector.clear()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#0D1724"
    }
    
    // 监听登录控制器信号
    Connections {
        target: loginController
        
        function onLoginStatusChanged(success, message) {
            loginPage.loginPending = false
            loadingOverlay.hideLoading()
            if (success) {
                toast.showSuccess(message || "登录成功")
                windowManager.replaceWithPage("behavior")
                return
            }
            toast.showError(message || "登录失败")
        }
        
        function onLoadingChanged(isLoading) {
            if (isLoading) {
                loadingOverlay.showLoading("正在登录")
            } else if (!loginPage.loginPending) {
                loadingOverlay.hideLoading()
            }
        }
        
        function onValidationFailed(message) {
            loginPage.loginPending = false
            loadingOverlay.hideLoading()
            toast.showError(message)
        }
    }
    
    // 背景图片
    Image {
        anchors.fill: parent
        source: Root.ImageResources.loginBg
        fillMode: Image.PreserveAspectCrop
    }
    
    // 使用通用 Loading 组件
    LoadingDialog {
        id: loadingOverlay
        onDismissed: {
            // 用户手动关闭 loading 时，认为这次登录被取消，允许再次发起登录并让控制器复位。
            loginPage.loginPending = false
            if (loginController && loginController.cancelLogin) {
                loginController.cancelLogin()
            }
        }
    }

    // 使用通用 Toast 组件
    Toast {
        id: toast
    }
    
    // 右上角设置按钮
    Rectangle {
        width: 40
        height: 40
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        color: "transparent"
        
        Image {
            anchors.centerIn: parent
            width: 24
            height: 24
            source: Root.ImageResources.iconSettings
            fillMode: Image.PreserveAspectFit
            opacity: 0.8
        }
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                console.log("设置按钮被点击")
                windowManager.switchToPage("password")
            }
        }
    }
    
    // 中心内容区域
    Item {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        
        Column {
            anchors.centerIn: parent
            spacing: 60
            
            // Logo 和标题
            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: Root.ImageResources.loginSystemIcon
                fillMode: Image.PreserveAspectFit
            }
            
            // 登录表单容器
            Rectangle {
                width: 700
                height: 400
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#40ffffff"
                radius: 8
                
                // 错误提示（移到外层，避免被遮挡）
                
                Row {
                    anchors.centerIn: parent
                    width: 580
                    height: 225
                    spacing: 30
                    
                    // 左侧用户图标
                    Rectangle {
                        width: 120
                        height: 120
                        anchors.top: parent.top
                        color: "#60ffffff"
                        radius: 4
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: 10

                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 76
                                height: 76
                                source: Root.ImageResources.userIcon
                                fillMode: Image.PreserveAspectFit
                            }
                            
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "请先登录"
                                font.pixelSize: 18
                                color: "#ffffff"
                            }
                        }
                    }
                    
                    // 右侧输入区域
                    Column {
                        width: 400
                        anchors.top: parent.top
                        spacing: 20

                        Column {
                            width: parent.width
                            height: 150
                            spacing: 20
                            
                            // 用户名输入框
                            Rectangle {
                                width: parent.width
                                height: 50
                                color: "#ffffff"
                                radius: 4
                                
                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 15
                                    anchors.rightMargin: 15
                                    spacing: 10
                                    
                                    Image {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18
                                        height: 18
                                        source: Root.ImageResources.userIcon
                                        fillMode: Image.PreserveAspectFit
                                    }
                                    
                                    TextInput {
                                        id: usernameInput
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.max(120, parent.width - 18 - usernameClearButton.width - 20)
                                        activeFocusOnTab: true
                                        KeyNavigation.priority: KeyNavigation.BeforeItem
                                        KeyNavigation.tab: passwordInput
                                        font.pixelSize: 14
                                        color: "#333333"
                                        text: loginController ? loginController.suggestedUsername : ""
                                        
                                        Text {
                                            visible: usernameInput.text.length === 0
                                            text: "请输入用户名"
                                            font.pixelSize: 14
                                            color: "#999999"
                                        }
                                    }

                                    LoginInputIconButton {
                                        id: usernameClearButton
                                        visible: usernameInput.text.length > 0
                                        width: visible ? implicitWidth : 0
                                        height: implicitHeight
                                        anchors.verticalCenter: parent.verticalCenter
                                        filledBackground: true
                                        tooltipText: "清空"
                                        onClicked: {
                                            usernameInput.text = ""
                                            usernameInput.forceActiveFocus()
                                        }
                                    }
                                }
                            }
                            
                            // 密码输入框
                            Rectangle {
                                width: parent.width
                                height: 50
                                color: "#ffffff"
                                radius: 4
                                
                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 15
                                    anchors.rightMargin: 15
                                    spacing: 10
                                    
                                    Image {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18
                                        height: 18
                                        source: Root.ImageResources.lockIcon
                                        fillMode: Image.PreserveAspectFit
                                    }
                                    
                                    TextInput {
                                        id: passwordInput
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.max(120, parent.width - 18 - passwordClearButton.width - passwordVisibilityButton.width - 30)
                                        activeFocusOnTab: true
                                        KeyNavigation.priority: KeyNavigation.BeforeItem
                                        KeyNavigation.backtab: usernameInput
                                        font.pixelSize: 14
                                        color: "#333333"
                                        echoMode: loginPage.passwordVisible ? TextInput.Normal : TextInput.Password
                                        text: loginController ? loginController.suggestedPassword : ""
                                        
                                        Text {
                                            visible: passwordInput.text.length === 0
                                            text: "请输入密码"
                                            font.pixelSize: 14
                                            color: "#999999"
                                        }
                                    }

                                    LoginInputIconButton {
                                        id: passwordVisibilityButton
                                        iconType: "eye"
                                        active: loginPage.passwordVisible
                                        width: implicitWidth
                                        height: implicitHeight
                                        anchors.verticalCenter: parent.verticalCenter
                                        tooltipText: loginPage.passwordVisible ? "隐藏密码" : "显示密码"
                                        onClicked: {
                                            loginPage.passwordVisible = !loginPage.passwordVisible
                                            passwordInput.forceActiveFocus()
                                        }
                                    }

                                    LoginInputIconButton {
                                        id: passwordClearButton
                                        visible: passwordInput.text.length > 0
                                        width: visible ? implicitWidth : 0
                                        height: implicitHeight
                                        anchors.verticalCenter: parent.verticalCenter
                                        filledBackground: true
                                        tooltipText: "清空"
                                        onClicked: {
                                            passwordInput.text = ""
                                            passwordInput.forceActiveFocus()
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 登录按钮
                        Rectangle {
                            width: parent.width
                            height: 50
                            color: {
                                if (loginPage.loginPending) {
                                    return "#6D95BE"
                                }
                                return loginMouseArea.pressed ? "#3a7bc8" : "#4a8fd8"
                            }
                            radius: 4
                            
                            Text {
                                anchors.centerIn: parent
                                text: "登 录"
                                font.pixelSize: 16
                                color: "#ffffff"
                                font.bold: true
                                font.letterSpacing: 8
                            }
                            
                            MouseArea {
                                id: loginMouseArea
                                anchors.fill: parent
                                enabled: !loginPage.loginPending
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    loginPage.loginPending = true
                                    // 直接显示，避免依赖 loadingChanged(true) 是否会再次触发（例如上一次请求未正确结束）。
                                    loadingOverlay.showLoading("正在登录")
                                    loginController.login(usernameInput.text, passwordInput.text)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

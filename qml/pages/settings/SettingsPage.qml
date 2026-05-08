import QtQuick
import QtQuick.Controls
import "../../components"
import "../../" as Root

Item {
    id: settingsPage
    width: parent.width
    height: parent.height
    property var monitorController: typeof networkInspector !== "undefined" ? networkInspector : null
    
    // 信号：返回上一页
    signal backRequested()

    function showSettingsToast(message, toastType) {
        if (typeof appRuntime !== "undefined" && appRuntime) {
            appRuntime.showToast(message, toastType || "info", 2200)
        }
    }
    
    // 背景
    Rectangle {
        anchors.fill: parent
        color: "#0D1724"
    }
    
    // 背景图片
    Image {
        anchors.fill: parent
        source: Root.ImageResources.bgOutdoor
        fillMode: Image.PreserveAspectCrop
        opacity: 0.3
    }
    
    // 顶部标题栏
    Rectangle {
        id: titleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80
        color: "transparent"
        
        // 左侧返回按钮（圆形带边框）
        BackCircleButton {
            id: backButton
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 20
            onClicked: settingsPage.backRequested()
        }
        
        // 中间标题
        Text {
            text: "设置"
            font.pixelSize: 28
            font.bold: true
            color: "#FFFFFF"
            anchors.centerIn: parent
        }
    }
    
    // 内容区域（紧靠标题栏下方）
    Column {
        anchors.top: titleBar.bottom
        anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 24

        // 网络请求查看开关
        Rectangle {
            width: 520
            height: 86
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 10
            color: "#1B3048"
            border.color: "#375778"
            border.width: 1

            Row {
                anchors.fill: parent
                anchors.leftMargin: 26
                anchors.rightMargin: 26
                spacing: 20

                Column {
                    width: parent.width - networkSwitch.width - 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        width: parent.width
                        text: "打开网络请求"
                        font.pixelSize: 22
                        font.bold: true
                        color: "#FFFFFF"
                    }

                    Text {
                        width: parent.width
                        text: "记录并查看当前应用的请求和返回数据"
                        font.pixelSize: 14
                        color: "#A9C1DA"
                        elide: Text.ElideRight
                    }
                }

                // iOS 风格 Switch
                Item {
                    id: networkSwitch
                    width: 60
                    height: 34
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: settingsPage.monitorController !== null
                    
                    property bool checked: false
                    
                    Component.onCompleted: {
                        checked = settingsPage.monitorController ? settingsPage.monitorController.enabled : false
                    }
                    
                    // 监听 monitorController 的 enabled 属性变化
                    Binding {
                        target: networkSwitch
                        property: "checked"
                        value: settingsPage.monitorController ? settingsPage.monitorController.enabled : false
                        when: settingsPage.monitorController !== null
                    }
                    
                    // 背景轨道
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: networkSwitch.checked ? "#34C759" : "#39393D"
                        opacity: networkSwitch.enabled ? 1.0 : 0.5
                        
                        Behavior on color {
                            ColorAnimation { duration: 250; easing.type: Easing.InOutCubic }
                        }
                        
                        // 滑动按钮
                        Rectangle {
                            id: switchHandle
                            width: 30
                            height: 30
                            radius: width / 2
                            color: "#FFFFFF"
                            x: networkSwitch.checked ? parent.width - width - 2 : 2
                            y: (parent.height - height) / 2
                            
                            // 简单的阴影效果（使用边框模拟）
                            border.color: "#E0E0E0"
                            border.width: 0.5
                            
                            Behavior on x {
                                NumberAnimation { duration: 250; easing.type: Easing.InOutCubic }
                            }
                            
                            // 外层阴影（使用半透明矩形）
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + 2
                                height: parent.height + 2
                                radius: width / 2
                                color: "transparent"
                                border.color: "#00000010"
                                border.width: 1
                                z: -1
                            }
                            
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + 4
                                height: parent.height + 4
                                radius: width / 2
                                color: "transparent"
                                border.color: "#00000008"
                                border.width: 1
                                z: -2
                            }
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (settingsPage.monitorController) {
                                networkSwitch.checked = !networkSwitch.checked
                                settingsPage.monitorController.setEnabled(networkSwitch.checked)
                            }
                        }
                    }
                }
            }
        }

        // 退出应用按钮
        Rectangle {
            width: 300
            height: 60
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 15
            color: quitMouseArea.pressed ? "#C0392B" : "#E74C3C"
            
            Text {
                anchors.centerIn: parent
                text: "退出应用"
                font.pixelSize: 24
                font.bold: true
                color: "#FFFFFF"
            }
            
            MouseArea {
                id: quitMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    console.log("退出应用")
                    appRuntime.quitApplication()
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

ApplicationWindow {
    id: mainWindow
    property var windowConfig: typeof appConfig !== "undefined" ? appConfig : null
    property var runtimeController: typeof appRuntime !== "undefined" ? appRuntime : null

    visible: false
    width: windowConfig ? windowConfig.windowWidth : 1280
    height: windowConfig ? windowConfig.windowHeight : 800
    minimumWidth: windowConfig ? windowConfig.windowMinWidth : 1280
    minimumHeight: windowConfig ? windowConfig.windowMinHeight : 800
    title: windowConfig ? windowConfig.appName : "行为记录桌面端"
    color: "#0D1724"

    background: Rectangle {
        color: "#0D1724"
    }

    function createPage(pageName) {
        var pageUrl = "pages/" + pageName + "/" + pageName.charAt(0).toUpperCase() + pageName.slice(1) + "Page.qml"
        var component = Qt.createComponent(pageUrl)
        if (component.status !== Component.Ready) {
            console.error("加载页面失败:", pageUrl, component.errorString())
            if (runtimeController) {
                runtimeController.showToast("当前只实现登录界面", "info", 2400)
            }
            return null
        }

        var page = component.createObject(stackView)
        if (!page) {
            console.error("创建页面对象失败:", pageUrl)
            if (runtimeController) {
                runtimeController.showToast("页面创建失败", "error", 2400)
            }
            return null
        }

        return page
    }

    function showPage(pageName, replaceCurrent) {
        var page = createPage(pageName)
        if (!page) {
            return
        }

        if (replaceCurrent && stackView.depth > 0) {
            stackView.replace(page)
            return
        }

        stackView.push(page)
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: "pages/login/LoginPage.qml"

        pushEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 300
            }
        }

        pushExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 300
            }
        }

        popEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 300
            }
        }

        popExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 300
            }
        }
    }

    Connections {
        target: windowManager

        function onSwitchPage(pageName) {
            console.log("切换到页面:", pageName)
            showPage(pageName, false)
        }

        function onReplacePage(pageName) {
            console.log("替换为页面:", pageName)
            showPage(pageName, true)
        }

        function onGoBackRequested() {
            console.log("返回上一页，当前深度:", stackView.depth)
            if (stackView.depth > 1) {
                stackView.pop()
            }
        }
    }

    Connections {
        target: runtimeController

        function onToastRequested(message, toastType, duration) {
            globalToast.show(message, toastType || "info", duration || 3000)
        }
    }

    Toast {
        id: globalToast
    }

    Item {
        id: fatalErrorOverlay
        anchors.fill: parent
        visible: runtimeController ? runtimeController.fatalErrorVisible : false
        z: 999

        Rectangle {
            anchors.fill: parent
            color: "#AA000000"
        }

        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            width: Math.min(parent.width * 0.8, 960)
            height: Math.min(parent.height * 0.78, 620)
            anchors.centerIn: parent
            radius: 14
            color: "#142338"
            border.color: "#4D80B3"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                Text {
                    text: runtimeController ? runtimeController.fatalErrorTitle : ""
                    font.pixelSize: 24
                    font.bold: true
                    color: "white"
                    Layout.fillWidth: true
                }

                Text {
                    text: runtimeController ? runtimeController.fatalErrorMessage : ""
                    font.pixelSize: 18
                    color: "#D7E6F5"
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#0D1724"
                    radius: 10
                    border.color: "#2A415A"

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 12
                        clip: true

                        TextArea {
                            readOnly: true
                            text: runtimeController ? runtimeController.fatalErrorDetails : ""
                            wrapMode: Text.WrapAnywhere
                            color: "#E6EEF7"
                            selectByMouse: true
                            background: null
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 12

                    Button {
                        text: "关闭"
                        onClicked: {
                            if (runtimeController) {
                                runtimeController.clearFatalError()
                            }
                        }
                    }
                }
            }
        }
    }
}

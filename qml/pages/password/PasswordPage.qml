import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components"
import "../../" as Root

Item {
    id: passwordPage
    width: parent.width
    height: parent.height
    clip: true
    focus: true

    signal passwordVerified()
    signal backRequested()

    property string currentPassword: ""
    property int maxPasswordLength: 6
    property string correctPassword: "111111"
    readonly property var keypadButtons: [
        { "label": "1", "value": "1" },
        { "label": "2", "value": "2" },
        { "label": "3", "value": "3" },
        { "label": "4", "value": "4" },
        { "label": "5", "value": "5" },
        { "label": "6", "value": "6" },
        { "label": "7", "value": "7" },
        { "label": "8", "value": "8" },
        { "label": "9", "value": "9" },
        { "label": "重置", "action": "reset" },
        { "label": "0", "value": "0" },
        { "label": "删除", "action": "delete" }
    ]

    Component.onCompleted: forceActiveFocus()

    Keys.onPressed: function(event) {
        if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
            appendDigit(String(event.key - Qt.Key_0))
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) {
            removeLastDigit()
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Escape) {
            passwordPage.backRequested()
            event.accepted = true
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0C2067" }
            GradientStop { position: 1.0; color: "#09184B" }
        }
    }

    Image {
        anchors.fill: parent
        source: Root.ImageResources.bgOutdoor
        fillMode: Image.PreserveAspectCrop
        opacity: 0.12
    }

    Rectangle {
        anchors.fill: parent
        color: "#081643"
        opacity: 0.18
    }

    BackCircleButton {
        id: backButton
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 26
        z: 10
        onClicked: passwordPage.backRequested()
    }

    Rectangle {
        id: panel
        width: Math.min(parent.width * 0.84, 1160)
        height: Math.min(parent.height * 0.92, 760)
        anchors.centerIn: parent
        clip: true
        radius: 46
        border.color: "#6277AE"
        border.width: 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2A3E81" }
            GradientStop { position: 1.0; color: "#23376F" }
        }
        opacity: 0.97

        readonly property real contentTopMargin: 54
        readonly property real contentBottomMargin: 46
        readonly property real keypadTopMargin: 34
        readonly property real innerWidth: Math.min(width - 120, 700)

        Rectangle {
            width: parent.width * 0.82
            height: parent.height * 0.34
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24
            radius: height / 2
            color: "#2A4A98"
            opacity: 0.16
        }

        Rectangle {
            width: parent.width * 0.54
            height: parent.height * 0.18
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 72
            radius: height / 2
            color: "#3B5FB7"
            opacity: 0.08
        }

        Column {
            id: contentColumn
            anchors.top: parent.top
            anchors.topMargin: panel.contentTopMargin
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 24

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "当前版本：" + (typeof appConfig !== "undefined" && appConfig ? appConfig.appVersion : "-")
                font.pixelSize: 18
                font.weight: Font.DemiBold
                color: "#E7EEFF"
                opacity: 0.82
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "输入密码进入设置"
                font.pixelSize: Math.min(54, Math.max(38, panel.width * 0.05))
                font.bold: true
                color: "#FFFFFF"
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 36

                Repeater {
                    model: passwordPage.maxPasswordLength

                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: index < passwordPage.currentPassword.length ? "#FFFFFF" : "transparent"
                        border.color: "#FFFFFF"
                        border.width: index < passwordPage.currentPassword.length ? 0 : 3
                        opacity: index < passwordPage.currentPassword.length ? 1.0 : 0.95
                    }
                }
            }
        }

        Item {
            id: keypadArea
            anchors.top: contentColumn.bottom
            anchors.topMargin: panel.keypadTopMargin
            anchors.bottom: parent.bottom
            anchors.bottomMargin: panel.contentBottomMargin
            anchors.horizontalCenter: parent.horizontalCenter
            width: panel.innerWidth

            GridLayout {
                id: keypadGrid
                anchors.centerIn: parent
                columns: 3
                rowSpacing: Math.min(22, Math.max(14, keypadArea.height * 0.04))
                columnSpacing: Math.min(34, Math.max(18, keypadArea.width * 0.04))

                property real buttonWidth: Math.min(170, Math.max(120, (keypadArea.width - columnSpacing * 2) / 3))
                property real buttonHeight: Math.min(126, Math.max(86, (keypadArea.height - rowSpacing * 3) / 4))

                width: buttonWidth * 3 + columnSpacing * 2
                height: buttonHeight * 4 + rowSpacing * 3

                Repeater {
                    model: passwordPage.keypadButtons

                    delegate: Item {
                        property var buttonModel: modelData

                        Layout.preferredWidth: keypadGrid.buttonWidth
                        Layout.preferredHeight: keypadGrid.buttonHeight

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.topMargin: 8
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            radius: 28
                            color: "#162A61"
                            opacity: 0.18
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 28
                            border.color: buttonArea.pressed ? "#90A5D9" : "#6277AE"
                            border.width: 1
                            color: buttonArea.pressed ? "#3A5296" : "#314784"
                            scale: buttonArea.pressed ? 0.985 : 1.0

                            gradient: Gradient {
                                GradientStop { position: 0.0; color: buttonArea.pressed ? "#425CA7" : "#394F8E" }
                                GradientStop { position: 1.0; color: buttonArea.pressed ? "#30467F" : "#2D4279" }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 120
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: buttonModel.label
                                font.pixelSize: buttonModel.label.length > 1 ? 22 : 30
                                font.bold: true
                                color: "#FFFFFF"
                            }

                            MouseArea {
                                id: buttonArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: passwordPage.handleButton(buttonModel)
                            }
                        }
                    }
                }
            }
        }
    }

    Toast {
        id: toast
    }

    function appendDigit(digit) {
        if (passwordPage.currentPassword.length >= passwordPage.maxPasswordLength) {
            return
        }

        passwordPage.currentPassword += digit
        checkPassword()
    }

    function removeLastDigit() {
        if (passwordPage.currentPassword.length === 0) {
            return
        }

        passwordPage.currentPassword = passwordPage.currentPassword.slice(0, -1)
    }

    function handleButton(buttonModel) {
        if (buttonModel.action === "reset") {
            passwordPage.currentPassword = ""
            return
        }

        if (buttonModel.action === "delete") {
            removeLastDigit()
            return
        }

        appendDigit(buttonModel.value)
    }

    function checkPassword() {
        if (passwordPage.currentPassword.length !== passwordPage.maxPasswordLength) {
            return
        }

        if (passwordPage.currentPassword === passwordPage.correctPassword) {
            passwordPage.passwordVerified()
            return
        }

        toast.showError("密码错误")
        wrongPasswordTimer.restart()
    }

    Timer {
        id: wrongPasswordTimer
        interval: 500
        onTriggered: passwordPage.currentPassword = ""
    }
}

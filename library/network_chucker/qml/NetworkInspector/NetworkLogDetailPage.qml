import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: detailPage
    property var entry: ({})
    signal closeRequested()

    function read(name, fallback) {
        if (!entry) {
            return fallback
        }
        var value = entry[name]
        if (value === undefined || value === null || value === "") {
            return fallback
        }
        return value
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 24
        clip: true

        Column {
            id: contentColumn
            width: detailPage.width - 48
            spacing: 14

            Rectangle {
                width: parent.width
                height: 96
                radius: 8
                color: "#15263A"
                border.color: "#2A4766"
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 20

                    Rectangle {
                        width: 80
                        height: 36
                        radius: 5
                        anchors.verticalCenter: parent.verticalCenter
                        color: detailPage.read("success", false) ? "#1D7A55" : (detailPage.read("state", "") === "请求中" ? "#856A25" : "#8C3030")

                        Text {
                            anchors.centerIn: parent
                            text: detailPage.read("method", "-")
                            color: "#FFFFFF"
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }

                    Column {
                        width: parent.width - 120
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            width: parent.width
                            text: detailPage.read("statusText", "-") + "  " + detailPage.read("elapsedText", "-") + "  " + detailPage.read("responseSizeText", "-")
                            color: "#FFFFFF"
                            font.pixelSize: 18
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: detailPage.read("fullStartedAtText", "-")
                            color: "#9FB8D1"
                            font.pixelSize: 14
                        }
                    }
                }
            }

            Repeater {
                model: [
                    {"title": "请求地址", "body": detailPage.read("url", "-")},
                    {"title": "请求头", "body": detailPage.read("requestHeadersText", "(空)")},
                    {"title": "请求体", "body": detailPage.read("requestBodyText", "(空)")},
                    {"title": "响应头", "body": detailPage.read("responseHeadersText", "(空)")},
                    {"title": "响应体", "body": detailPage.read("responseBodyText", "(空)")},
                    {"title": "错误信息", "body": detailPage.read("errorMessage", "(空)")}
                ]

                delegate: Rectangle {
                    id: sectionCard
                    property bool copyable: modelData.title === "请求头" || modelData.title === "请求体" || modelData.title === "响应体"

                    width: contentColumn.width
                    height: sectionColumn.implicitHeight + 24
                    radius: 8
                    color: "#111F31"
                    border.color: "#263F5D"
                    border.width: 1

                    Column {
                        id: sectionColumn
                        width: parent.width - 24
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 8

                        Item {
                            width: parent.width
                            height: 28

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: sectionCard.copyable ? parent.width - copyButton.width - 10 : parent.width
                                text: modelData.title
                                color: "#CFE4FA"
                                font.pixelSize: 16
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                id: copyButton
                                property bool copied: false

                                visible: sectionCard.copyable
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28
                                height: 28
                                radius: 5
                                color: copyMouseArea.pressed ? "#254563" : (copyMouseArea.containsMouse ? "#1C3855" : "transparent")
                                border.color: copyMouseArea.containsMouse || copied ? "#5CA7E8" : "transparent"
                                border.width: 1

                                ToolTip.visible: copyMouseArea.containsMouse || copied
                                ToolTip.delay: copied ? 0 : 400
                                ToolTip.text: copied ? "已复制" : "复制"

                                Item {
                                    width: 18
                                    height: 18
                                    anchors.centerIn: parent

                                    Rectangle {
                                        x: 6
                                        y: 3
                                        width: 9
                                        height: 11
                                        radius: 1
                                        color: "transparent"
                                        border.color: "#A9D8FF"
                                        border.width: 1
                                    }

                                    Rectangle {
                                        x: 3
                                        y: 6
                                        width: 9
                                        height: 11
                                        radius: 1
                                        color: "transparent"
                                        border.color: "#EAF4FF"
                                        border.width: 1
                                    }
                                }

                                MouseArea {
                                    id: copyMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        detailText.forceActiveFocus()
                                        detailText.selectAll()
                                        detailText.copy()
                                        detailText.deselect()
                                        copyButton.copied = true
                                        copyFeedbackTimer.restart()
                                    }
                                }

                                Timer {
                                    id: copyFeedbackTimer
                                    interval: 1200
                                    onTriggered: copyButton.copied = false
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: Math.max(74, detailText.implicitHeight + 20)
                            radius: 5
                            color: "#0B1522"
                            border.color: "#1E334D"
                            border.width: 1

                            TextEdit {
                                id: detailText
                                anchors.fill: parent
                                anchors.margins: 10
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.WrapAnywhere
                                text: modelData.body
                                color: "#EAF4FF"
                                font.pixelSize: 14
                                font.family: "monospace"
                            }
                        }
                    }
                }
            }
        }
    }
}

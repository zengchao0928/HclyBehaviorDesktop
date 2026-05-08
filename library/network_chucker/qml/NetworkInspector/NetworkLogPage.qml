import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: networkLogPage
    property var inspector: null
    property bool detailVisible: false
    property var detailEntry: ({})
    signal backRequested()

    function formatStatusText(model) {
        // 优先显示明确的 HTTP 状态码，例如 403/404/500。
        if (model && model.statusCode && String(model.statusCode).length > 0) {
            if (model.statusText && String(model.statusText).length > 0) {
                return String(model.statusText)
            }
            return String(model.statusCode)
        }

        // 兼容部分调用方只把状态码塞进 errorMessage 的情况：例如 "服务器错误: 403"。
        var message = model && model.errorMessage ? String(model.errorMessage) : ""
        var match = message.match(/\\b(\\d{3})\\b/)
        if (match && match.length > 1) {
            return "请求异常 (" + match[1] + ")"
        }

        // 没有 HTTP 状态码时，通常表示请求没拿到响应（超时/断网/SSL 等）。
        // 这类场景无法展示 4xx/5xx，但仍尽量给出更具体的异常类型。
        if (message.length > 0) {
            var upper = message.toUpperCase()
            if (message.indexOf("超时") !== -1) {
                return "请求超时"
            }
            if (message.indexOf("无法连接") !== -1 || message.indexOf("连接") !== -1) {
                return "连接失败"
            }
            if (upper.indexOf("SSL") !== -1) {
                return "SSL 异常"
            }
            return "请求异常"
        }

        return (model && (model.statusText || model.state)) ? (model.statusText || model.state) : "-"
    }

    Rectangle {
        anchors.fill: parent
        color: "#0D1724"
    }

    Rectangle {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 84
        color: "#101D2E"
        border.color: "#223954"
        border.width: 1

        Rectangle {
            id: backButton
            width: 44
            height: 44
            radius: 22
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            color: backMouseArea.pressed ? "#2B4A6C" : "#19304A"
            border.color: "#5B7897"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "<"
                color: "#FFFFFF"
                font.pixelSize: 24
                font.bold: true
            }

            MouseArea {
                id: backMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (networkLogPage.detailVisible) {
                        networkLogPage.detailVisible = false
                    } else {
                        networkLogPage.backRequested()
                    }
                }
            }
        }

        Column {
            anchors.left: backButton.right
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                text: networkLogPage.detailVisible ? "网络请求详情" : "网络请求"
                color: "#FFFFFF"
                font.pixelSize: 26
                font.bold: true
            }

            Text {
                text: networkLogPage.inspector ? ("已记录 " + networkLogPage.inspector.count + " 条") : "未接入网络查看器"
                color: "#9FB8D1"
                font.pixelSize: 14
            }
        }

        Rectangle {
            visible: !networkLogPage.detailVisible
            width: 92
            height: 40
            radius: 6
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            color: clearMouseArea.pressed ? "#314F6D" : "#203A56"
            border.color: "#4D6C8D"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "清空"
                color: "#EAF4FF"
                font.pixelSize: 16
            }

            MouseArea {
                id: clearMouseArea
                anchors.fill: parent
                enabled: networkLogPage.inspector && networkLogPage.inspector.count > 0
                cursorShape: Qt.PointingHandCursor
                onClicked: networkLogPage.inspector.clear()
            }
        }
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom

        ListView {
            id: requestList
            anchors.fill: parent
            anchors.margins: 24
            spacing: 12
            clip: true
            visible: !networkLogPage.detailVisible
            model: networkLogPage.inspector ? networkLogPage.inspector.logModel : null

            delegate: Rectangle {
                width: ListView.view.width
                height: 104
                radius: 8
                color: requestMouseArea.pressed ? "#1F3854" : "#15263A"
                border.color: "#2A4766"
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Rectangle {
                        width: 74
                        height: 34
                        radius: 5
                        anchors.verticalCenter: parent.verticalCenter
                        color: model.success ? "#1D7A55" : (model.state === "请求中" ? "#856A25" : "#8C3030")

                        Text {
                            anchors.centerIn: parent
                            text: model.method || "-"
                            color: "#FFFFFF"
                            font.pixelSize: 15
                            font.bold: true
                        }
                    }

                    Column {
                        width: parent.width - 260
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            width: parent.width
                            text: model.url || "-"
                            color: "#FFFFFF"
                            font.pixelSize: 17
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: (model.startedAtText || "-") + "  " + (model.elapsedText || "-") + "  " + (model.responseSizeText || "-")
                            color: "#9FB8D1"
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }
                    }

                    Column {
                        width: 150
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignRight
                            text: networkLogPage.formatStatusText(model)
                            color: model.success ? "#6EE7B7" : (model.state === "请求中" ? "#F7D57E" : "#FF9D9D")
                            font.pixelSize: 16
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignRight
                            text: model.contentType || model.host || ""
                            color: "#86A1BD"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    id: requestMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        networkLogPage.detailEntry = {
                            "requestId": model.requestId,
                            "method": model.method,
                            "url": model.url,
                            "host": model.host,
                            "path": model.path,
                            "state": model.state,
                            "success": model.success,
                            "statusText": model.statusText,
                            "elapsedText": model.elapsedText,
                            "startedAtText": model.startedAtText,
                            "fullStartedAtText": model.fullStartedAtText,
                            "requestHeadersText": model.requestHeadersText,
                            "requestBodyText": model.requestBodyText,
                            "responseHeadersText": model.responseHeadersText,
                            "responseBodyText": model.responseBodyText,
                            "responseSizeText": model.responseSizeText,
                            "contentType": model.contentType,
                            "errorMessage": model.errorMessage
                        }
                        networkLogPage.detailVisible = true
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !networkLogPage.detailVisible && (!networkLogPage.inspector || networkLogPage.inspector.count === 0)
            text: "暂无网络请求"
            color: "#9FB8D1"
            font.pixelSize: 22
        }

        NetworkLogDetailPage {
            anchors.fill: parent
            visible: networkLogPage.detailVisible
            entry: networkLogPage.detailEntry
            onCloseRequested: networkLogPage.detailVisible = false
        }
    }
}

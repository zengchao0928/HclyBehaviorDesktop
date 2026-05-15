import QtQuick
import QtQuick.Controls
import "../../components"
import "../../dialog"
import "../../" as Root

Item {
    id: behaviorPage
    width: parent ? parent.width : 1280
    height: parent ? parent.height : 800
    clip: true

    property var controller: typeof behaviorController !== "undefined" ? behaviorController : null
    property bool inlineRecordRefreshActive: false
    property string recordRefreshState: "idle"
    property string recordRefreshResultText: ""

    readonly property real uiScale: Math.min(1, Math.max(0.58, width / 2048))
    readonly property real pageLeftPadding: sp(15)
    readonly property real panelGap: sp(15)
    readonly property real sidePanelWidth: sp(90)
    readonly property real headerHeight: sp(58)
    readonly property real toolbarIconSize: sp(44)
    readonly property real topActionButtonSize: sp(58)
    readonly property real topActionIconSize: sp(48)
    readonly property real bodyWidth: Math.max(0, width - pageLeftPadding)
    readonly property real bodyHeight: Math.min(height * 0.9, height - headerHeight - sp(32))
    readonly property real centerPanelWidth: Math.max(360, width * 0.3)
    readonly property real leftPanelWidth: Math.max(0, bodyWidth - centerPanelWidth - sidePanelWidth - panelGap * 2)
    readonly property color panelColor: "#4DFFFFFF"
    readonly property color selectedContentColor: "#22FFAE"
    readonly property int selectedRowHeight: sp(210)
    readonly property int selectedCardHeight: sp(190)

    function sp(value) {
        return Math.round(value * uiScale)
    }

    function recordRefreshTitle() {
        if (recordRefreshState === "pull") {
            return "下拉刷新"
        }
        if (recordRefreshState === "release") {
            return "松开刷新"
        }
        if (recordRefreshState === "refreshing") {
            return "正在刷新"
        }
        if (recordRefreshState === "success") {
            return recordRefreshResultText || "刷新成功"
        }
        if (recordRefreshState === "error") {
            return recordRefreshResultText || "刷新失败"
        }
        return ""
    }

    function recordRefreshSubtitle() {
        if (recordRefreshState === "pull") {
            return "继续下拉获取最新记录"
        }
        if (recordRefreshState === "release") {
            return "松手立即更新记录"
        }
        if (recordRefreshState === "refreshing") {
            return "正在同步最新记录"
        }
        if (recordRefreshState === "success") {
            return "记录已更新"
        }
        if (recordRefreshState === "error") {
            return "请稍后重试"
        }
        return ""
    }

    Component.onCompleted: {
        if (controller) {
            controller.requestData()
        }
    }

    Connections {
        target: controller

        function onLoadingChanged(isLoading) {
            if (isLoading) {
                if (!behaviorPage.inlineRecordRefreshActive) {
                    loadingOverlay.showLoading("请稍等")
                }
            } else {
                loadingOverlay.hideLoading()
                if (behaviorPage.inlineRecordRefreshActive && behaviorPage.recordRefreshState === "refreshing") {
                    behaviorPage.recordRefreshState = "idle"
                }
                behaviorPage.inlineRecordRefreshActive = false
            }
        }

        function onRecordRefreshFinished(success, message) {
            if (!behaviorPage.inlineRecordRefreshActive && behaviorPage.recordRefreshState !== "refreshing") {
                return
            }
            behaviorPage.inlineRecordRefreshActive = false
            behaviorPage.recordRefreshResultText = message || (success ? "刷新成功" : "刷新失败")
            behaviorPage.recordRefreshState = success ? "success" : "error"
            recordRefreshDoneTimer.restart()
        }

        function onToastRequested(message, toastType) {
            toast.show(message, toastType || "info", 2200)
        }

        function onDataChanged() {
            if (controller && !remarkEdit.activeFocus && remarkEdit.text !== controller.remark) {
                remarkEdit.text = controller.remark
            }
        }
    }

    Timer {
        id: recordRefreshDoneTimer
        interval: 900
        repeat: false
        onTriggered: {
            behaviorPage.recordRefreshState = "idle"
            behaviorPage.recordRefreshResultText = ""
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#0D1724"
    }

    Image {
        anchors.fill: parent
        source: Root.ImageResources.bgOutdoor
        fillMode: Image.Stretch
    }

    Column {
        id: contentColumn
        width: behaviorPage.bodyWidth
        height: behaviorPage.headerHeight + behaviorPage.sp(20) + behaviorPage.bodyHeight
        anchors.left: parent.left
        anchors.leftMargin: behaviorPage.pageLeftPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: behaviorPage.sp(20)

        Item {
            width: parent.width
            height: behaviorPage.headerHeight

            Text {
                id: timeText
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                text: controller ? controller.currentTime : ""
                color: "#FFFFFF"
                font.pixelSize: behaviorPage.sp(30)
                width: Math.min(implicitWidth + 4, parent.width * 0.36)
                elide: Text.ElideRight
            }

            Image {
                id: refreshIcon
                width: behaviorPage.toolbarIconSize
                height: behaviorPage.toolbarIconSize
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: timeText.right
                anchors.leftMargin: behaviorPage.sp(30)
                source: Root.ImageResources.iconRefreshAll
                fillMode: Image.PreserveAspectFit
                opacity: refreshArea.pressed ? 0.65 : 1

                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (controller) controller.requestData()
                }
            }

            Text {
                id: selectedCodeText
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                width: behaviorPage.sp(520)
                text: controller ? controller.selectedLienCodeText : ""
                color: "#FF4242"
                font.pixelSize: behaviorPage.sp(24)
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Rectangle {
                id: settingsButton
                width: behaviorPage.topActionButtonSize
                height: behaviorPage.topActionButtonSize
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: logoutButton.left
                anchors.rightMargin: behaviorPage.sp(24)
                radius: behaviorPage.sp(8)
                color: settingsMouseArea.pressed ? "#335B82" : "transparent"

                Image {
                    anchors.centerIn: parent
                    source: Root.ImageResources.iconSettings
                    width: behaviorPage.topActionIconSize
                    height: behaviorPage.topActionIconSize
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    id: settingsMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: windowManager.switchToPage("password")
                }
            }

            Rectangle {
                id: logoutButton
                width: behaviorPage.topActionButtonSize
                height: behaviorPage.topActionButtonSize
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: behaviorPage.sp(20)
                radius: behaviorPage.sp(8)
                color: logoutMouseArea.pressed ? "#335B82" : "transparent"

                Canvas {
                    id: logoutCanvas
                    width: behaviorPage.topActionIconSize
                    height: behaviorPage.topActionIconSize
                    anchors.centerIn: parent
                    antialiasing: true
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d")
                        var w = width
                        var h = height
                        ctx.clearRect(0, 0, w, h)
                        ctx.strokeStyle = "#FFFFFF"
                        ctx.lineWidth = Math.max(3, behaviorPage.sp(4))
                        ctx.lineCap = "round"
                        ctx.lineJoin = "round"
                        ctx.beginPath()
                        ctx.moveTo(w * 0.54, h * 0.18)
                        ctx.lineTo(w * 0.20, h * 0.18)
                        ctx.lineTo(w * 0.20, h * 0.82)
                        ctx.lineTo(w * 0.54, h * 0.82)
                        ctx.stroke()
                        ctx.beginPath()
                        ctx.moveTo(w * 0.47, h * 0.5)
                        ctx.lineTo(w * 0.88, h * 0.5)
                        ctx.moveTo(w * 0.68, h * 0.32)
                        ctx.lineTo(w * 0.88, h * 0.5)
                        ctx.lineTo(w * 0.68, h * 0.68)
                        ctx.stroke()
                    }
                }

                MouseArea {
                    id: logoutMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: windowManager.replaceWithPage("login")
                }
            }
        }

        Row {
            id: bodyRow
            width: parent.width
            height: behaviorPage.bodyHeight
            spacing: behaviorPage.panelGap

            Rectangle {
                id: leftPanel
                width: behaviorPage.leftPanelWidth
                height: parent.height
                radius: 15
                color: behaviorPage.panelColor
                clip: true

                Column {
                    anchors.fill: parent
                    anchors.margins: behaviorPage.sp(20)
                    spacing: behaviorPage.sp(15)

                    Item {
                        width: parent.width
                        height: behaviorPage.sp(15)
                    }

                    Row {
                        width: parent.width
                        height: behaviorPage.sp(34)
                        spacing: behaviorPage.sp(20)

                        Rectangle {
                            width: behaviorPage.sp(4)
                            height: behaviorPage.sp(20)
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#FFFFFF"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "行为记录"
                            color: "#FFFFFF"
                            font.pixelSize: behaviorPage.sp(30)
                        }
                    }

                    ListView {
                        id: lienListView
                        width: parent.width
                        height: behaviorPage.sp(180)
                        orientation: ListView.Horizontal
                        spacing: behaviorPage.sp(20)
                        clip: true
                        model: controller ? controller.liens : []

                        delegate: Rectangle {
                            width: behaviorPage.sp(180)
                            height: lienListView.height
                            radius: behaviorPage.sp(15)
                            color: controller && controller.selectedLienIndex === index ? "#00FFFF" : "#80153BA9"

                            Column {
                                anchors.centerIn: parent
                                width: parent.width
                                height: behaviorPage.sp(160)
                                spacing: behaviorPage.sp(7)

                                Image {
                                    id: avatarImage
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: behaviorPage.sp(100)
                                    height: behaviorPage.sp(130)
                                    source: modelData.localFaceUrl || modelData.faceUrl
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: status !== Image.Error && source !== ""

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: behaviorPage.sp(4)
                                        border.color: "#1AFFFFFF"
                                        color: "transparent"
                                    }
                                }

                                Image {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: behaviorPage.sp(100)
                                    height: behaviorPage.sp(130)
                                    source: Root.ImageResources.defaultAvatarIcon
                                    fillMode: Image.PreserveAspectFit
                                    visible: !avatarImage.visible
                                }

                                Text {
                                    width: parent.width - 12
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "看护室：" + modelData.roomName
                                    color: controller && controller.selectedLienIndex === index ? "#000000" : "#FFFFFF"
                                    font.pixelSize: behaviorPage.sp(18)
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (controller) controller.selectLienInfo(index)
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: controller && controller.liens.length === 0
                            text: "暂无留置对象"
                            color: "#C8FFFFFF"
                            font.pixelSize: behaviorPage.sp(22)
                        }
                    }

                    Row {
                        width: parent.width
                        height: behaviorPage.selectedRowHeight
                        spacing: behaviorPage.sp(20)

                        Rectangle {
                            width: behaviorPage.sp(300)
                            height: behaviorPage.selectedCardHeight
                            anchors.verticalCenter: parent.verticalCenter
                            radius: behaviorPage.sp(15)
                            color: behaviorPage.panelColor

                            Row {
                                id: selectedContentSummary
                                anchors.centerIn: parent
                                height: behaviorPage.sp(70)
                                spacing: behaviorPage.sp(12)

                                Image {
                                    id: selectedIconImage
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: behaviorPage.sp(70)
                                    height: behaviorPage.sp(70)
                                    source: controller ? controller.selectedContentIconUrl : ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    visible: status !== Image.Error && source !== ""
                                }

                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: behaviorPage.sp(70)
                                    height: behaviorPage.sp(70)
                                    source: Root.ImageResources.iconBehaviorCfSelect
                                    fillMode: Image.PreserveAspectFit
                                    visible: !selectedIconImage.visible
                                }

                                Text {
                                    height: selectedContentSummary.height
                                    text: controller ? controller.selectedContentName : ""
                                    color: behaviorPage.selectedContentColor
                                    font.pixelSize: behaviorPage.sp(36)
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width - behaviorPage.sp(320)
                            height: behaviorPage.selectedCardHeight
                            anchors.verticalCenter: parent.verticalCenter
                            radius: behaviorPage.sp(15)
                            color: "#26D0D3D7"
                            border.color: "#8FFFFFFF"
                            border.width: 2

                            TextEdit {
                                id: remarkEdit
                                anchors.fill: parent
                                anchors.margins: behaviorPage.sp(10)
                                anchors.rightMargin: submitButton.width + behaviorPage.sp(20)
                                color: "#FFFFFF"
                                font.pixelSize: behaviorPage.sp(24)
                                wrapMode: TextEdit.Wrap
                                selectByMouse: true
                                inputMethodHints: Qt.ImhPreferLowercase
                                text: controller ? controller.remark : ""
                                onTextChanged: if (controller && activeFocus) controller.setRemark(text)

                                Text {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    visible: remarkEdit.text.length === 0
                                    text: "请输入备注信息"
                                    color: "#9B9B9B"
                                    font.pixelSize: behaviorPage.sp(24)
                                }
                            }

                            Rectangle {
                                id: submitButton
                                width: behaviorPage.sp(132)
                                height: behaviorPage.sp(52)
                                anchors.right: parent.right
                                anchors.rightMargin: behaviorPage.sp(10)
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: behaviorPage.sp(10)
                                radius: height / 2
                                color: submitMouseArea.pressed ? "#E5E5E5" : "#FFFFFF"

                                Text {
                                    anchors.centerIn: parent
                                    text: "提交"
                                    color: "#000000"
                                    font.pixelSize: behaviorPage.sp(28)
                                }

                                MouseArea {
                                    id: submitMouseArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (controller) controller.addActionRecord()
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        height: parent.height - behaviorPage.sp(15 + 34 + 180 + 15 * 4) - behaviorPage.selectedRowHeight
                        spacing: behaviorPage.sp(20)

                        Item {
                            width: parent.width
                            height: behaviorPage.sp(40)

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: "#FFFFFF"
                            }

                            ListView {
                                id: actionTitleList
                                anchors.fill: parent
                                orientation: ListView.Horizontal
                                model: controller ? controller.actions : []
                                clip: true
                                interactive: false

                                delegate: Item {
                                    width: Math.max(behaviorPage.sp(120), actionTitleList.width / Math.max(1, (controller ? controller.actions.length : 1)))
                                    height: parent.height

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.name
                                        color: "#FFFFFF"
                                        font.pixelSize: behaviorPage.sp(28)
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        visible: controller && controller.selectedTitleIndex === index
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        width: behaviorPage.sp(80)
                                        height: behaviorPage.sp(3)
                                        color: "#FFFFFF"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (controller) controller.selectTitle(index)
                                    }
                                }
                            }

                        }

                        GridView {
                            id: actionGrid
                            width: parent.width
                            height: parent.height - behaviorPage.sp(60)
                            cellWidth: width / 7
                            cellHeight: behaviorPage.sp(172)
                            clip: true
                            model: controller ? controller.currentContents : []

                            delegate: MouseArea {
                                width: actionGrid.cellWidth
                                height: actionGrid.cellHeight
                                acceptedButtons: Qt.LeftButton
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                preventStealing: false
                                onClicked: if (controller) controller.selectBehaviourById(modelData.id)

                                readonly property bool selected: controller && controller.selectedContent && controller.selectedContent.id === modelData.id

                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.topMargin: behaviorPage.sp(8)
                                    width: parent.width
                                    spacing: behaviorPage.sp(10)

                                    Rectangle {
                                        width: behaviorPage.sp(114)
                                        height: behaviorPage.sp(114)
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        radius: behaviorPage.sp(10)
                                        color: selected ? "#153BA9" : "#33153BA9"
                                        border.color: selected ? behaviorPage.selectedContentColor : "#4D22FFAE"
                                        border.width: 1

                                        Image {
                                            id: actionIconImage
                                            anchors.centerIn: parent
                                            width: behaviorPage.sp(100)
                                            height: behaviorPage.sp(80)
                                            source: selected ? (modelData.selectedLocalIconUrl || modelData.localIconUrl || modelData.iconUrl) : (modelData.localIconUrl || modelData.iconUrl)
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            visible: status !== Image.Error && source !== ""
                                        }

                                        Image {
                                            anchors.centerIn: parent
                                            width: behaviorPage.sp(80)
                                            height: behaviorPage.sp(90)
                                            source: Root.ImageResources.iconBehaviorCfSelect
                                            fillMode: Image.PreserveAspectFit
                                            visible: !actionIconImage.visible
                                        }
                                    }

                                    Text {
                                        width: parent.width
                                        height: behaviorPage.sp(32)
                                        text: modelData.name
                                        color: selected ? behaviorPage.selectedContentColor : "#FFFFFF"
                                        font.pixelSize: behaviorPage.sp(22)
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }
                                }

                            }
                        }
                    }
                }
            }

            Rectangle {
                id: centerPanel
                width: behaviorPage.centerPanelWidth
                height: parent.height
                radius: 15
                color: behaviorPage.panelColor
                clip: true

                Column {
                    anchors.fill: parent
                    anchors.margins: behaviorPage.sp(20)
                    spacing: behaviorPage.sp(6)

                    Text {
                        width: parent.width - 15
                        height: behaviorPage.sp(38)
                        leftPadding: behaviorPage.sp(15)
                        text: "当前记录 " + (controller ? controller.currentDateText : "")
                        color: "#00FFFF"
                        font.pixelSize: behaviorPage.sp(26)
                        elide: Text.ElideRight
                    }

                    Row {
                        width: parent.width
                        height: behaviorPage.sp(45)
                        spacing: 0

                        Column {
                            width: behaviorPage.sp(15)
                            height: parent.height

                            Rectangle {
                                width: behaviorPage.sp(15)
                                height: behaviorPage.sp(15)
                                radius: 8
                                color: "#FB8E46"
                            }

                            Rectangle {
                                width: behaviorPage.sp(4)
                                height: behaviorPage.sp(30)
                                anchors.horizontalCenter: parent.horizontalCenter
                                radius: 2
                                color: "#FFFFFF"
                            }
                        }

                        Image {
                            width: parent.width - behaviorPage.sp(15)
                            height: behaviorPage.sp(6)
                            anchors.top: parent.top
                            source: Root.ImageResources.bgBehaviorRightLine
                            fillMode: Image.Stretch
                        }
                    }

                    Item {
                        width: parent.width
                        height: parent.height - behaviorPage.sp(89)
                        clip: true

                        ListView {
                            id: recordListView
                            anchors.fill: parent
                            clip: true
                            boundsBehavior: Flickable.DragAndOvershootBounds
                            model: controller ? controller.records : []
                            property bool pullRefreshArmed: false
                            readonly property real pullRefreshThreshold: behaviorPage.sp(70)
                            readonly property real pullRefreshDistance: Math.max(0, originY - contentY)

                            onMovementStarted: {
                                if (!behaviorPage.inlineRecordRefreshActive) {
                                    recordRefreshDoneTimer.stop()
                                    if (behaviorPage.recordRefreshState !== "refreshing") {
                                        behaviorPage.recordRefreshState = "idle"
                                        behaviorPage.recordRefreshResultText = ""
                                    }
                                }
                                pullRefreshArmed = false
                            }
                            onContentYChanged: {
                                if (draggingVertically && controller && !behaviorPage.inlineRecordRefreshActive) {
                                    pullRefreshArmed = contentY < originY - pullRefreshThreshold
                                    if (pullRefreshDistance > behaviorPage.sp(8)) {
                                        behaviorPage.recordRefreshState = pullRefreshArmed ? "release" : "pull"
                                    } else if (behaviorPage.recordRefreshState === "pull" || behaviorPage.recordRefreshState === "release") {
                                        behaviorPage.recordRefreshState = "idle"
                                    }
                                }
                            }
                            onMovementEnded: {
                                if (pullRefreshArmed && controller) {
                                    behaviorPage.inlineRecordRefreshActive = true
                                    behaviorPage.recordRefreshState = "refreshing"
                                    behaviorPage.recordRefreshResultText = ""
                                    controller.refreshRecords()
                                } else if (behaviorPage.recordRefreshState === "pull" || behaviorPage.recordRefreshState === "release") {
                                    behaviorPage.recordRefreshState = "idle"
                                }
                                pullRefreshArmed = false
                            }

                            delegate: Item {
                                width: recordListView.width
                                height: Math.max(behaviorPage.sp(60), recordContentText.implicitHeight + behaviorPage.sp(16))

                                Item {
                                    id: recordTimeline
                                    width: behaviorPage.sp(15)
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom

                                    Rectangle {
                                        width: behaviorPage.sp(4)
                                        height: behaviorPage.sp(7)
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: parent.top
                                        color: "#FFFFFF"
                                    }

                                    Rectangle {
                                        id: recordDot
                                        width: behaviorPage.sp(15)
                                        height: behaviorPage.sp(15)
                                        radius: 8
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: parent.top
                                        anchors.topMargin: behaviorPage.sp(7)
                                        color: "#FFFFFF"
                                    }

                                    Rectangle {
                                        width: behaviorPage.sp(4)
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: recordDot.bottom
                                        anchors.bottom: parent.bottom
                                        color: "#FFFFFF"
                                    }
                                }

                                Text {
                                    id: recordTimeText
                                    width: behaviorPage.sp(102)
                                    anchors.left: recordTimeline.right
                                    anchors.leftMargin: behaviorPage.sp(14)
                                    anchors.top: parent.top
                                    text: modelData.timeText || ""
                                    color: "#F2FFFFFF"
                                    font.pixelSize: behaviorPage.sp(24)
                                    lineHeight: 1.16
                                    lineHeightMode: Text.ProportionalHeight
                                    elide: Text.ElideRight
                                }

                                Text {
                                    id: recordContentText
                                    anchors.left: recordTimeText.right
                                    anchors.leftMargin: behaviorPage.sp(8)
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    text: modelData.content || ""
                                    color: "#FFFFFF"
                                    font.pixelSize: behaviorPage.sp(24)
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 3
                                    lineHeight: 1.16
                                    lineHeightMode: Text.ProportionalHeight
                                    elide: Text.ElideRight
                                }
                            }

                            footer: Item {
                                width: recordListView.width
                                height: behaviorPage.sp(64)
                                visible: controller && controller.records.length > 0 && controller.hasMoreRecords

                                Rectangle {
                                    width: behaviorPage.sp(180)
                                    height: behaviorPage.sp(42)
                                    anchors.centerIn: parent
                                    radius: height / 2
                                    color: loadMoreArea.pressed ? "#DDE7EF" : "#F8FBFF"
                                    border.color: "#35E6F0"
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "加载更多"
                                        color: "#24425D"
                                        font.pixelSize: behaviorPage.sp(18)
                                        font.weight: Font.Medium
                                    }

                                    MouseArea {
                                        id: loadMoreArea
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (controller) controller.loadMoreRecords()
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: controller && controller.records.length === 0
                                text: controller && controller.liens.length === 0 ? "暂无留置对象" : "暂无记录"
                                color: "#C8FFFFFF"
                                font.pixelSize: behaviorPage.sp(22)
                            }
                        }

                        Rectangle {
                            id: recordRefreshIndicator
                            width: behaviorPage.sp(224)
                            height: behaviorPage.sp(58)
                            x: (parent.width - width) / 2
                            y: {
                                if (behaviorPage.recordRefreshState === "idle") {
                                    return -height - behaviorPage.sp(6)
                                }
                                if (behaviorPage.recordRefreshState === "refreshing"
                                        || behaviorPage.recordRefreshState === "success"
                                        || behaviorPage.recordRefreshState === "error") {
                                    return behaviorPage.sp(2)
                                }
                                return Math.min(behaviorPage.sp(2), -height + recordListView.pullRefreshDistance * 0.9)
                            }
                            radius: behaviorPage.sp(8)
                            color: "#7011263D"
                            border.color: recordRefreshIndicator.accentColor
                            border.width: 0
                            opacity: behaviorPage.recordRefreshState === "idle"
                                     ? 0
                                     : ((behaviorPage.recordRefreshState === "refreshing"
                                         || behaviorPage.recordRefreshState === "success"
                                         || behaviorPage.recordRefreshState === "error")
                                        ? 1
                                        : Math.min(1, 0.25 + recordListView.pullRefreshDistance / recordListView.pullRefreshThreshold))
                            scale: behaviorPage.recordRefreshState === "idle" ? 0.96 : 1
                            z: 10
                            antialiasing: true

                            readonly property color accentColor: behaviorPage.recordRefreshState === "error"
                                                                 ? "#FF6F7D"
                                                                 : (behaviorPage.recordRefreshState === "success" ? "#22FFAE" : "#00FFFF")

                            Behavior on y {
                                NumberAnimation {
                                    duration: 210
                                    easing.type: Easing.OutBack
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 140
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutBack
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: parent.radius - 1
                                opacity: 0.28
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop {
                                        position: 0
                                        color: "#2A00FFFF"
                                    }
                                    GradientStop {
                                        position: 1
                                        color: behaviorPage.recordRefreshState === "error" ? "#24FF6F7D" : "#1622FFAE"
                                    }
                                }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: behaviorPage.sp(12)

                                Rectangle {
                                    id: recordRefreshIconShell
                                    width: behaviorPage.sp(36)
                                    height: width
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: width / 2
                                    color: "#33102032"
                                    border.color: recordRefreshIndicator.accentColor
                                    border.width: 1
                                    scale: behaviorPage.recordRefreshState === "pull"
                                           ? 0.9 + Math.min(0.1, recordListView.pullRefreshDistance / recordListView.pullRefreshThreshold * 0.1)
                                           : 1
                                    antialiasing: true

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 180
                                            easing.type: Easing.OutBack
                                        }
                                    }

                                    Canvas {
                                        id: recordRefreshIcon
                                        anchors.centerIn: parent
                                        width: behaviorPage.sp(27)
                                        height: width
                                        antialiasing: true
                                        property real progress: behaviorPage.recordRefreshState === "refreshing"
                                                                ? 0.72
                                                                : Math.min(1, recordListView.pullRefreshDistance / recordListView.pullRefreshThreshold)
                                        property real spinAngle: 0

                                        onProgressChanged: requestPaint()
                                        onSpinAngleChanged: requestPaint()
                                        onWidthChanged: requestPaint()
                                        onHeightChanged: requestPaint()

                                        NumberAnimation on spinAngle {
                                            from: 0
                                            to: 360
                                            duration: 820
                                            loops: Animation.Infinite
                                            running: behaviorPage.recordRefreshState === "refreshing"
                                        }

                                        Connections {
                                            target: behaviorPage
                                            function onRecordRefreshStateChanged() {
                                                recordRefreshIcon.requestPaint()
                                            }
                                        }

                                        onPaint: {
                                            var ctx = getContext("2d")
                                            var cx = width / 2
                                            var cy = height / 2
                                            var radius = Math.min(width, height) / 2 - behaviorPage.sp(3)
                                            var state = behaviorPage.recordRefreshState
                                            var accent = recordRefreshIndicator.accentColor

                                            ctx.clearRect(0, 0, width, height)
                                            ctx.lineCap = "round"
                                            ctx.lineJoin = "round"
                                            ctx.lineWidth = Math.max(2, behaviorPage.sp(2.4))

                                            if (state === "success") {
                                                ctx.strokeStyle = accent
                                                ctx.beginPath()
                                                ctx.moveTo(cx - radius * 0.58, cy - radius * 0.02)
                                                ctx.lineTo(cx - radius * 0.18, cy + radius * 0.42)
                                                ctx.lineTo(cx + radius * 0.62, cy - radius * 0.42)
                                                ctx.stroke()
                                                return
                                            }

                                            if (state === "error") {
                                                ctx.strokeStyle = accent
                                                ctx.beginPath()
                                                ctx.moveTo(cx - radius * 0.45, cy - radius * 0.45)
                                                ctx.lineTo(cx + radius * 0.45, cy + radius * 0.45)
                                                ctx.moveTo(cx + radius * 0.45, cy - radius * 0.45)
                                                ctx.lineTo(cx - radius * 0.45, cy + radius * 0.45)
                                                ctx.stroke()
                                                return
                                            }

                                            ctx.strokeStyle = "rgba(255, 255, 255, 0.22)"
                                            ctx.beginPath()
                                            ctx.arc(cx, cy, radius, 0, Math.PI * 2)
                                            ctx.stroke()

                                            if (state === "refreshing") {
                                                var spinStart = (spinAngle - 90) * Math.PI / 180
                                                ctx.strokeStyle = accent
                                                ctx.beginPath()
                                                ctx.arc(cx, cy, radius, spinStart, spinStart + Math.PI * 1.35)
                                                ctx.stroke()
                                                return
                                            }

                                            var start = -Math.PI / 2
                                            var end = start + Math.max(0.08, progress) * Math.PI * 1.72
                                            ctx.strokeStyle = accent
                                            ctx.beginPath()
                                            ctx.arc(cx, cy, radius, start, end)
                                            ctx.stroke()

                                            ctx.save()
                                            ctx.translate(cx, cy)
                                            if (state === "release") {
                                                ctx.rotate(Math.PI)
                                            }
                                            ctx.strokeStyle = "#FFFFFF"
                                            ctx.beginPath()
                                            ctx.moveTo(0, -radius * 0.42)
                                            ctx.lineTo(0, radius * 0.36)
                                            ctx.moveTo(-radius * 0.33, radius * 0.04)
                                            ctx.lineTo(0, radius * 0.38)
                                            ctx.lineTo(radius * 0.33, radius * 0.04)
                                            ctx.stroke()
                                            ctx.restore()
                                        }
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: behaviorPage.sp(2)
                                    width: behaviorPage.sp(146)

                                    Text {
                                        width: parent.width
                                        text: behaviorPage.recordRefreshTitle()
                                        color: "#FFFFFF"
                                        font.pixelSize: behaviorPage.sp(17)
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: behaviorPage.recordRefreshSubtitle()
                                        color: behaviorPage.recordRefreshState === "error" ? "#FFD9DF" : "#CFEFFF"
                                        font.pixelSize: behaviorPage.sp(12)
                                        elide: Text.ElideRight
                                        opacity: 0.88
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Column {
                width: behaviorPage.sidePanelWidth
                height: parent.height
                spacing: behaviorPage.sp(10)

                RequestSideButton {
                    label: "事项请求"
                    iconSource: Root.ImageResources.iconBehaviorSx
                    onClicked: openApplyDialog("matter")
                }

                RequestSideButton {
                    label: "物品请求"
                    iconSource: Root.ImageResources.iconBehaviorWp
                    onClicked: openApplyDialog("goods")
                }
            }
        }
    }

    component RequestSideButton: Rectangle {
        id: sideButton
        property string label: ""
        property string iconSource: ""
        signal clicked()

        width: behaviorPage.sidePanelWidth
        height: behaviorPage.sp(82)
        radius: behaviorPage.sp(15)
        color: sideMouseArea.pressed ? "#66FFFFFF" : behaviorPage.panelColor

        Column {
            anchors.centerIn: parent
            spacing: behaviorPage.sp(4)

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: sideButton.iconSource
                width: behaviorPage.sp(42)
                height: behaviorPage.sp(42)
                fillMode: Image.PreserveAspectFit
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: sideButton.width - 8
                text: sideButton.label
                color: "#FFFFFF"
                font.pixelSize: behaviorPage.sp(14)
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }

        MouseArea {
            id: sideMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: sideButton.clicked()
        }
    }

    ApplyRequestDialog {
        id: applyRequestDialog
        anchors.fill: parent
        controller: behaviorPage.controller

        onApplyRequested: function(dialogType, itemId, count) {
            if (!controller) {
                return
            }
            if (dialogType === "matter") {
                controller.applyMatter(itemId)
            } else {
                controller.applyGoods(itemId, count)
            }
        }
    }

    LoadingDialog {
        id: loadingOverlay
    }

    Toast {
        id: toast
    }

    function openApplyDialog(dialogType) {
        applyRequestDialog.openFor(dialogType)
        if (controller) {
            controller.openApplyDialog(dialogType)
        }
    }
}

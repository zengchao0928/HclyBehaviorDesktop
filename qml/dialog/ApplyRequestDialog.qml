import QtQuick
import "../" as Root

Item {
    id: root

    property var controller: null
    property string dialogType: ""
    property string selectedItemId: ""
    property int selectedGoodsCount: 1
    property var applyItems: !controller ? [] : (dialogType === "matter" ? controller.matters : controller.goods)

    readonly property real uiScale: Math.min(1, Math.max(0.58, width / 2048))
    readonly property string dialogTitle: dialogType === "matter" ? "事项请求" : "物品请求"

    signal applyRequested(string dialogType, string itemId, int count)

    visible: false
    z: 990

    function sp(value) {
        return Math.round(value * uiScale)
    }

    function openFor(typeName) {
        dialogType = typeName
        selectedItemId = ""
        selectedGoodsCount = 1
        visible = true
        selectFirstItem()
    }

    function closeDialog() {
        visible = false
        dialogType = ""
        selectedItemId = ""
        selectedGoodsCount = 1
    }

    function selectFirstItem() {
        if (!visible || selectedItemId.length > 0 || !applyItems || applyItems.length === 0) {
            return
        }
        selectedItemId = String(applyItems[0].id || "")
    }

    onApplyItemsChanged: selectFirstItem()

    Rectangle {
        anchors.fill: parent
        color: "#66000000"
    }

    MouseArea {
        anchors.fill: parent
    }

    Rectangle {
        id: dialogPanel
        width: Math.min(parent.width * 0.9, root.sp(1680))
        height: Math.min(parent.height * 0.78, root.sp(760))
        anchors.centerIn: parent
        radius: root.sp(20)
        color: "#9DC0DE"
        clip: true

        Row {
            id: titleRow
            anchors.left: parent.left
            anchors.leftMargin: root.sp(42)
            anchors.top: parent.top
            anchors.topMargin: root.sp(46)
            height: root.sp(52)
            spacing: root.sp(16)

            Rectangle {
                width: root.sp(4)
                height: root.sp(28)
                anchors.verticalCenter: parent.verticalCenter
                color: "#FFFFFF"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.dialogTitle
                color: "#FFFFFF"
                font.pixelSize: root.sp(42)
                font.weight: Font.Medium
            }
        }

        Item {
            id: closeButton
            width: root.sp(74)
            height: root.sp(74)
            anchors.right: parent.right
            anchors.rightMargin: root.sp(42)
            anchors.top: parent.top
            anchors.topMargin: root.sp(34)

            Image {
                anchors.centerIn: parent
                width: root.sp(62)
                height: root.sp(62)
                source: Root.ImageResources.iconCloseDialog
                fillMode: Image.PreserveAspectFit
                opacity: closeMouseArea.pressed ? 0.7 : 1
            }

            MouseArea {
                id: closeMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeDialog()
            }
        }

        GridView {
            id: requestGrid
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: titleRow.bottom
            anchors.bottom: footer.top
            anchors.leftMargin: root.sp(58)
            anchors.rightMargin: root.sp(58)
            anchors.topMargin: root.sp(54)
            anchors.bottomMargin: root.sp(24)
            clip: true
            cellWidth: Math.max(root.sp(138), width / 8)
            cellHeight: root.sp(164)
            model: root.applyItems

            delegate: Item {
                width: requestGrid.cellWidth
                height: requestGrid.cellHeight

                readonly property bool selected: root.selectedItemId === String(modelData.id || "")

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    spacing: root.sp(8)

                    Rectangle {
                        width: root.sp(116)
                        height: root.sp(116)
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: root.sp(9)
                        color: selected ? "#2D6FB4" : "#5D88BD"
                        border.color: selected ? "#18F5EC" : "#32D8E5"
                        border.width: selected ? 2 : 1

                        Image {
                            id: requestIcon
                            anchors.centerIn: parent
                            width: root.sp(86)
                            height: root.sp(76)
                            source: modelData.localIconUrl || modelData.iconUrl
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            visible: status !== Image.Error && source !== ""
                        }

                        Image {
                            anchors.centerIn: parent
                            width: root.sp(76)
                            height: root.sp(82)
                            source: Root.ImageResources.iconBehaviorCfSelect
                            fillMode: Image.PreserveAspectFit
                            visible: !requestIcon.visible
                        }
                    }

                    Text {
                        width: parent.width
                        text: modelData.name
                        color: selected ? "#22FFAE" : "#FFFFFF"
                        font.pixelSize: root.sp(22)
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectedItemId = String(modelData.id || "")
                }
            }

            Text {
                anchors.centerIn: parent
                visible: requestGrid.count === 0
                text: "暂无可申请内容"
                color: "#E8FFFFFF"
                font.pixelSize: root.sp(24)
            }
        }

        Item {
            id: footer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.sp(120)

            Row {
                visible: root.dialogType === "goods"
                anchors.right: applyButton.left
                anchors.rightMargin: root.sp(28)
                anchors.verticalCenter: applyButton.verticalCenter
                spacing: root.sp(10)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "数量"
                    color: "#FFFFFF"
                    font.pixelSize: root.sp(20)
                }

                Rectangle {
                    width: root.sp(38)
                    height: root.sp(34)
                    radius: height / 2
                    color: minusArea.pressed ? "#DDE7EF" : "#FFFFFF"

                    Text {
                        anchors.centerIn: parent
                        text: "-"
                        color: "#2C5475"
                        font.pixelSize: root.sp(24)
                        font.bold: true
                    }

                    MouseArea {
                        id: minusArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedGoodsCount = Math.max(1, root.selectedGoodsCount - 1)
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.sp(32)
                    text: root.selectedGoodsCount
                    color: "#FFFFFF"
                    font.pixelSize: root.sp(22)
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    width: root.sp(38)
                    height: root.sp(34)
                    radius: height / 2
                    color: plusArea.pressed ? "#DDE7EF" : "#FFFFFF"

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: "#2C5475"
                        font.pixelSize: root.sp(24)
                        font.bold: true
                    }

                    MouseArea {
                        id: plusArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedGoodsCount += 1
                    }
                }
            }

            Rectangle {
                id: applyButton
                width: root.sp(190)
                height: root.sp(58)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                radius: height / 2
                color: root.selectedItemId.length > 0
                       ? (applyMouseArea.pressed ? "#DDE7EF" : "#FFFFFF")
                       : "#D8D8D8"
                opacity: root.selectedItemId.length > 0 ? 1 : 0.72

                Text {
                    anchors.centerIn: parent
                    text: "立即申请"
                    color: root.selectedItemId.length > 0 ? "#1B1B1B" : "#8D8D8D"
                    font.pixelSize: root.sp(24)
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: applyMouseArea
                    anchors.fill: parent
                    enabled: root.selectedItemId.length > 0
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.applyRequested(root.dialogType, root.selectedItemId, root.selectedGoodsCount)
                        root.closeDialog()
                    }
                }
            }
        }
    }
}

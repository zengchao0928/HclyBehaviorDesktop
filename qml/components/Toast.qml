import QtQuick
import QtQuick.Controls

// 通用 Toast 提示组件
Rectangle {
    id: root
    width: Math.min(parent ? parent.width - 64 : 480, Math.max(280, toastText.implicitWidth + 40))
    height: Math.max(56, toastText.implicitHeight + 24)
    anchors.centerIn: parent
    radius: 8
    visible: shown || opacity > 0.01
    z: 1000
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.9
    
    // 自定义属性
    property string message: ""
    property string toastType: "error" // "error", "success", "info"
    property int duration: 3000
    property bool shown: false
    
    // 根据类型设置颜色
    color: {
        switch(toastType) {
            case "success": return "#4caf50"
            case "error": return "#f44336"
            case "info": return "#2196f3"
            default: return "#f44336"
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutBack
        }
    }
    
    Text {
        id: toastText
        anchors.centerIn: parent
        width: parent.width - 28
        text: root.message
        color: "#ffffff"
        font.pixelSize: 14
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }
    
    Timer {
        id: hideTimer
        interval: root.duration
        onTriggered: root.hide()
    }
    
    // 显示 Toast 的方法
    function show(msg, type, dur) {
        message = msg || ""
        toastType = type || "error"
        duration = dur || 3000
        shown = true
        hideTimer.restart()
    }

    function hide() {
        shown = false
    }
    
    // 快捷方法
    function showError(msg) {
        show(msg, "error", 3000)
    }
    
    function showSuccess(msg) {
        show(msg, "success", 2000)
    }
    
    function showInfo(msg) {
        show(msg, "info", 2000)
    }
}

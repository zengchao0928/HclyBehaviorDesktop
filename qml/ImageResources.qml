pragma Singleton
import QtQuick

QtObject {
    // 登录页面相关图片（使用 Qt.resolvedUrl 解析相对于此文件的路径）
    readonly property string loginBg: Qt.resolvedUrl("../resources/images/login_bg.webp")
    readonly property string loginSystemIcon: Qt.resolvedUrl("../resources/images/login_look_system_icon.webp")
    readonly property string userIcon: Qt.resolvedUrl("../resources/images/icon_user.svg")
    readonly property string lockIcon: Qt.resolvedUrl("../resources/images/icon_lock.svg")
    readonly property string iconSettings: Qt.resolvedUrl("../resources/images/icon_settings.webp")
}

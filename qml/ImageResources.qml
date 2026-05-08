pragma Singleton
import QtQuick

QtObject {
    // 登录页面相关图片（使用 Qt.resolvedUrl 解析相对于此文件的路径）
    readonly property string loginBg: Qt.resolvedUrl("../resources/images/login_bg.webp")
    readonly property string loginSystemIcon: Qt.resolvedUrl("../resources/images/login_look_system_icon.webp")
    readonly property string userIcon: Qt.resolvedUrl("../resources/images/icon_user.svg")
    readonly property string lockIcon: Qt.resolvedUrl("../resources/images/icon_lock.svg")
    readonly property string iconSettings: Qt.resolvedUrl("../resources/images/icon_settings.webp")
    readonly property string bgOutdoor: Qt.resolvedUrl("../resources/images/bg_outdoor.webp")
    readonly property string iconRefreshAll: Qt.resolvedUrl("../resources/images/icon_refresh_all.webp")
    readonly property string bgBehaviorRightLine: Qt.resolvedUrl("../resources/images/bg_behavior_right_line.webp")
    readonly property string defaultAvatarIcon: Qt.resolvedUrl("../resources/images/default_avatar_icon.webp")
    readonly property string iconBehaviorCfSelect: Qt.resolvedUrl("../resources/images/icon_behavior_cf_select.webp")
    readonly property string iconBehaviorSx: Qt.resolvedUrl("../resources/images/icon_behavior_sx.webp")
    readonly property string iconBehaviorWp: Qt.resolvedUrl("../resources/images/icon_behavior_wp.webp")
    readonly property string iconCloseDialog: Qt.resolvedUrl("../resources/images/icon_close_dialog.webp")
}

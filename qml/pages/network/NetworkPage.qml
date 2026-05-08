import QtQuick 2.15
import NetworkInspector 1.0

Item {
    id: networkPage
    width: parent.width
    height: parent.height

    signal backRequested()

    NetworkLogPage {
        anchors.fill: parent
        inspector: typeof networkInspector !== "undefined" ? networkInspector : null
        onBackRequested: networkPage.backRequested()
    }
}

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import "../../components/"

BarButton {
    id: root

    active: monitorWindow.visible
    contentItem: content
    onClicked: monitorWindow.visible = !monitorWindow.visible


    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: Config.spacing

        RowLayout {
            spacing: 4

            Text {
                text: "󰍛"
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal
                color: Config.accentColor
            }

            Text {
                text: SystemMonitorService.cpuUsage + "%"
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                font.bold: true
                color: Config.textColor
            }
        }


        RowLayout {
            spacing: 4

            Text {
                text: "󰘚"
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal
                color: Config.accentColor
            }

            Text {
                text: SystemMonitorService.ramUsage + "%"
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                font.bold: true
                color: Config.textColor
            }
        }
    }

    SystemMonitorWindow {
        id: monitorWindow
        visible: false
    }

}
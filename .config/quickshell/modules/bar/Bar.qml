pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

import "../../components/"
import "../quickSettings/"
import "../notifications/"
import "../systemMonitor/"
import "../calendar/"

Scope {
    id: root

    readonly property int gapIn: 8
    readonly property int gapOut: 15

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            property bool enableAutoHide: StateService.get("bar.autoHide", false)

            WlrLayershell.namespace: "qs_modules"

            implicitHeight: StateService.get("bar.height", 30)
            color: "transparent"
            screen: modelData

            exclusionMode: enableAutoHide ? ExclusionMode.Ignore : ExclusionMode.Normal
            exclusiveZone: enableAutoHide ? 0 : height

            anchors {
                top: true
                left: true
                right: true
            }

            margins.top: {
                if (WindowManagerService.anyModuleOpen
                    || !enableAutoHide
                    || mouseSensor.hovered)
                    return 0

                return (-1 * (height - 1))
            }

            Behavior on margins.top {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutExpo
                }
            }

            HoverHandler {
                id: mouseSensor
            }

            Rectangle {
                anchors.fill: parent
                color: Config.backgroundTransparentColor

                //////////////////////////////////////////////////////
                // LEFT (launcher + workspaces + window title)
                //////////////////////////////////////////////////////
                RowLayout {

                    anchors.left: parent.left
                    anchors.leftMargin: root.gapOut
                    anchors.verticalCenter: parent.verticalCenter

                    spacing: root.gapIn

                    Workspaces {}

                    ActiveWindow {
                        Layout.leftMargin: 10
                    }
                }

                //////////////////////////////////////////////////////
                // CENTER (clock)
                //////////////////////////////////////////////////////
                RowLayout {

                    anchors.centerIn: parent
                    anchors.verticalCenter: parent.verticalCenter

                    CalendarButton {}
                }

                //////////////////////////////////////////////////////
                // RIGHT (system + tray + controls)
                //////////////////////////////////////////////////////
                RowLayout {

                    anchors.right: parent.right
                    anchors.rightMargin: root.gapOut
                    anchors.verticalCenter: parent.verticalCenter

                    spacing: root.gapIn

                    TrayWidget {}

                    SystemMonitorButton {}

                    QuickSettingsButton {}

                    NotificationButton {}
                }
            }
        }
    }
}
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
            id: barWindow

            required property var modelData

            property bool enableAutoHide: Config.barAutoHide

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

            IdleInhibitor {
                enabled: IdleInhibitService.enabled
                window: barWindow
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

                    Rectangle {
                        visible: RecordingService.recording
                        Layout.preferredWidth: recordingRow.implicitWidth + 14
                        Layout.preferredHeight: 22
                        radius: height / 2
                        color: Qt.alpha(Config.errorColor, recordingStopArea.containsMouse ? 0.28 : 0.18)
                        border.width: 1
                        border.color: Qt.alpha(Config.errorColor, 0.6)

                        RowLayout {
                            id: recordingRow
                            anchors.centerIn: parent
                            spacing: 6

                            Rectangle {
                                Layout.preferredWidth: 8
                                Layout.preferredHeight: 8
                                radius: 4
                                color: Config.errorColor

                                SequentialAnimation on opacity {
                                    running: RecordingService.recording
                                    loops: Animation.Infinite
                                    NumberAnimation {
                                        to: 0.35
                                        duration: 700
                                    }
                                    NumberAnimation {
                                        to: 1
                                        duration: 700
                                    }
                                }
                            }

                            Text {
                                text: RecordingService.formatElapsed()
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeSmall
                                font.bold: true
                                color: Config.textColor
                            }

                            Text {
                                text: "󰓛"
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeSmall
                                color: recordingStopArea.containsMouse ? Config.errorColor : Config.subtextColor
                            }
                        }

                        MouseArea {
                            id: recordingStopArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: RecordingService.stop()
                        }
                    }

                    TrayWidget {}

                    SystemMonitorButton {}

                    QuickSettingsButton {}

                    NotificationButton {}
                }
            }
        }
    }
}

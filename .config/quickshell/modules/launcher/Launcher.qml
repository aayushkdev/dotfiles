pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.config

PanelWindow {
    id: root

    visible: LauncherService.visible

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "qs_modules"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    color: "transparent"

    // Click on background closes
    MouseArea {
        anchors.fill: parent
        onClicked: {
            contentLoader.item.forceActiveFocus();
            LauncherService.hide();
        }
    }

    // Loader that creates/destroys the content
    Loader {
        id: contentLoader
        anchors.centerIn: parent
        active: LauncherService.visible

        sourceComponent: Rectangle {
            id: content
            width: 520

            // Dynamic height based on content
            property int listHeight: 420
            height: listHeight + searchBar.height + 32

            radius: Config.radiusLarge
            color: Config.backgroundTransparentColor
            border.color: Qt.alpha(Config.accentColor, 0.2)
            border.width: 1

            // Scale animation on entry
            scale: 1
            opacity: 1

            // Smooth height animation
            Behavior on height {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Config.spacing + 4
                spacing: Config.spacing

                // Search bar
                Rectangle {
                    id: searchBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: Config.radius
                    color: Config.surface0Color
                    border.width: searchInput.activeFocus ? 2 : 0
                    border.color: Config.accentColor

                    Behavior on border.width {
                        NumberAnimation {
                            duration: Config.animDurationShort
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Config.spacing + 6
                        anchors.rightMargin: Config.spacing + 6
                        spacing: Config.spacing

                        Text {
                            text: ""
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeNormal
                            color: searchInput.activeFocus ? Config.accentColor : Config.subtextColor

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDurationShort
                                }
                            }
                        }

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            color: Config.textColor
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeLarge
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            placeholderText: "Search apps..."
                            placeholderTextColor: Config.mutedColor
                            background: null

                            onTextChanged: LauncherService.query = text

                            Keys.onEscapePressed: {
                                focus = false;
                                LauncherService.hide();
                            }

                            Keys.onReturnPressed: LauncherService.launchSelected()

                            Keys.onUpPressed: {
                                if (LauncherService.selectedIndex > 0)
                                    LauncherService.selectedIndex--;
                            }

                            Keys.onDownPressed: {
                                if (LauncherService.selectedIndex < (LauncherService.results || []).length - 1)
                                    LauncherService.selectedIndex++;
                            }

                            Keys.onTabPressed: event => {
                                if (LauncherService.selectedIndex < (LauncherService.results || []).length - 1)
                                    LauncherService.selectedIndex++;
                                event.accepted = true;
                            }

                            Keys.onPressed: event => {
                                const isBacktab = event.key === Qt.Key_Backtab;
                                const isShiftTab = event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier);

                                if (isBacktab || isShiftTab) {
                                    if (LauncherService.selectedIndex > 0)
                                        LauncherService.selectedIndex--;
                                    event.accepted = true;
                                }
                            }

                            Component.onCompleted: {
                                LauncherService.query = "";
                                LauncherService.selectedIndex = 0;
                                Qt.callLater(() => {
                                    if (LauncherService.visible) {
                                        forceActiveFocus();
                                    }
                                });
                            }
                        }

                        // Results counter
                        Rectangle {
                            visible: (LauncherService.results || []).length > 0
                            Layout.preferredWidth: countText.implicitWidth + 12
                            Layout.preferredHeight: 22
                            radius: height / 2
                            color: Config.surface1Color

                            Text {
                                id: countText
                                anchors.centerIn: parent
                                text: (LauncherService.results || []).length
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeSmall
                                color: Config.subtextColor
                            }
                        }

                        // Clear button
                        Rectangle {
                            visible: searchInput.text
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: height / 2
                            color: clearMouse.containsMouse ? Config.surface2Color : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDurationShort
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeSmall
                                color: Config.subtextColor
                            }

                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = "";
                                    searchInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Config.surface1Color
                }

                // App list
                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.preferredHeight: content.listHeight

                    clip: true
                    spacing: 4
                    model: LauncherService.results || []
                    currentIndex: LauncherService.selectedIndex
                    highlightFollowsCurrentItem: false
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: height

                    onCurrentIndexChanged: {
                        positionViewAtIndex(currentIndex, ListView.Contain)
                    }
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    highlight: Rectangle {
                        width: appList.width
                        height: 56
                        radius: Config.radius
                        color: Config.surface2Color
                        y: appList.currentItem ? appList.currentItem.y : 0
                    }

                    delegate: Item {
                        id: delegateItem
                        required property int index
                        required property var modelData

                        property var entry: delegateItem.modelData?.data ?? {}
                        property var provider: delegateItem.modelData?.provider ?? null

                        width: appList.width
                        height: 56

                        property bool isSelected: index === LauncherService.selectedIndex
                        property bool isHovered: delegateMouse.containsMouse

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 14

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                radius: Config.radiusSmall
                                color: Config.surface0Color

                                Image {
                                    anchors.centerIn: parent
                                    width: 32
                                    height: 32
                                    source: {
                                        const icon = entry?.icon ?? provider?.icon ?? "";
                                        return icon ? "image://icon/" + icon : "image://icon/application-x-executable";
                                    }
                                    sourceSize: Qt.size(32, 32)
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: entry?.name ?? entry ?? ""
                                    color: delegateItem.isSelected ? Config.textColor : Config.textColor
                                    font.family: Config.font
                                    font.pixelSize: Config.fontSizeNormal
                                    font.weight: delegateItem.isSelected ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: entry?.comment || entry?.genericName || provider?.name || ""
                                    color: Config.subtextColor
                                    font.family: Config.font
                                    font.pixelSize: Config.fontSizeSmall
                                    elide: Text.ElideRight
                                    visible: text !== ""
                                }
                            }

                            Text {
                                visible: delegateItem.isSelected
                                text: "󰌑"
                                color: Config.accentColor
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeSmall
                            }
                        }

                        MouseArea {
                            id: delegateMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                LauncherService.selectedIndex = delegateItem.index;
                                LauncherService.launchSelected();
                            }
                        }
                    }
                }
            }
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: LauncherService.hide()
    }
}
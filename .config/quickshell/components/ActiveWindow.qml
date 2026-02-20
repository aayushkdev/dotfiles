pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.config

Item {
    id: root

    property int maxWidth: 400

    readonly property var activeWindow: Hyprland.activeToplevel
    readonly property bool windowExists: activeWindow !== null
    readonly property string windowTitle: activeWindow?.title ?? ""

    implicitWidth: windowExists ? content.implicitWidth : 0
    implicitHeight: content.implicitHeight

    visible: opacity > 0
    opacity: windowExists ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: Config.animDuration
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        id: content
        spacing: 6
        anchors.fill: parent

        Text {
            id: titleText

            text: root.windowTitle !== "" ? "    " + root.windowTitle : ""

            color: Config.surface3Color
            font.family: Config.font
            font.pixelSize: Config.fontSizeNormal

            elide: Text.ElideRight

            Layout.fillWidth: true
            Layout.maximumWidth: root.maxWidth
        }
    }
}
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import "../../../components/"

Item {
    id: root

    signal backRequested

    Layout.fillWidth: true
    implicitHeight: Math.min(620, main.implicitHeight)

    ScrollView {
        id: scroll
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            id: main
            width: scroll.availableWidth
            spacing: 12

            PageHeader {
                icon: AudioService.systemIcon
                title: "Audio"
                onBackClicked: root.backRequested()
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Config.surface1Color
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                spacing: 18

                AudioSection {
                    title: "Output"
                    icon: AudioService.systemIcon
                    activeName: AudioService.outputName
                    muted: AudioService.muted
                    volume: AudioService.volume
                    devices: AudioService.outputDevices
                    activeDevice: AudioService.effectiveSink
                    emptyText: "No output devices"
                    onVolumeMoved: value => {
                        AudioService.setVolume(value);
                    }
                    onMuteClicked: {
                        AudioService.toggleMute();
                    }
                    onDeviceClicked: device => {
                        AudioService.setDefaultSink(device);
                    }
                }

                AudioSection {
                    title: "Input"
                    icon: AudioService.sourceMuted ? "󰍭" : "󰍬"
                    activeName: AudioService.inputName
                    muted: AudioService.sourceMuted
                    volume: AudioService.sourceVolume
                    devices: AudioService.inputDevices
                    activeDevice: AudioService.effectiveSource
                    emptyText: "No input devices"
                    onVolumeMoved: value => {
                        AudioService.setSourceVolume(value);
                    }
                    onMuteClicked: {
                        AudioService.toggleSourceMute();
                    }
                    onDeviceClicked: device => {
                        AudioService.setDefaultSource(device);
                    }
                }

                StreamSection {
                    title: "Apps"
                    emptyText: "No active playback streams"
                    streams: AudioService.outputStreams
                    devices: AudioService.outputDevices
                }

            }
        }
    }

    component SectionTitle: RowLayout {
        id: sectionTitle

        property string title: ""
        property string icon: ""

        Layout.fillWidth: true
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            radius: Config.radius
            color: Qt.alpha(Config.accentColor, 0.16)

            Text {
                anchors.centerIn: parent
                text: sectionTitle.icon
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal
                color: Config.accentColor
            }
        }

        Text {
            text: sectionTitle.title
            font.family: Config.font
            font.pixelSize: Config.fontSizeLarge
            font.bold: true
            color: Config.textColor
        }
    }

    component AudioSection: ColumnLayout {
        id: section

        property string title: ""
        property string icon: ""
        property string activeName: ""
        property bool muted: false
        property real volume: 0
        property var devices: []
        property var activeDevice: null
        property string emptyText: ""

        signal volumeMoved(real value)
        signal muteClicked
        signal deviceClicked(var device)

        Layout.fillWidth: true
        spacing: 8
        z: deviceSelector.expanded ? 30 : 0

        SectionTitle {
            title: section.title
            icon: section.icon
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: controlColumn.implicitHeight + 20
            radius: Config.radiusLarge
            color: Config.surface1Color

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 3
                radius: 2
                color: section.muted ? Config.warningColor : Config.accentColor
            }

            ColumnLayout {
                id: controlColumn
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: section.activeName
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeNormal
                            font.bold: true
                            color: Config.textColor
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: section.muted ? "Muted" : "Current · " + Math.round(section.volume * 100) + "%"
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeSmall
                            color: section.muted ? Config.warningColor : Config.subtextColor
                        }
                    }

                    ActionButton {
                        icon: section.muted ? "󰖁" : "󰕾"
                        baseColor: section.muted ? Config.warningColor : Config.surface2Color
                        hoverColor: section.muted ? Config.warningColor : Config.surface3Color
                        textColor: section.muted ? Config.textReverseColor : Config.textColor
                        hoverTextColor: section.muted ? Config.textReverseColor : Config.textColor
                        onClicked: {
                            section.muteClicked();
                        }
                    }
                }

                QsSlider {
                    value: section.volume
                    icon: section.icon
                    onMoved: value => {
                        section.volumeMoved(value);
                    }
                    onIconClicked: {
                        section.muteClicked();
                    }
                }
            }
        }

        AudioDropdown {
            id: deviceSelector
            Layout.fillWidth: true
            title: section.title + " device"
            currentLabel: section.activeName
            direction: "down"
            devices: section.devices
            activeDevice: section.activeDevice
            emptyText: section.emptyText
            onSelected: device => {
                section.deviceClicked(device);
            }
        }
    }

    component StreamSection: ColumnLayout {
        id: streamSection

        property string title: ""
        property string emptyText: ""
        property var streams: []
        property var devices: []

        Layout.fillWidth: true
        spacing: 8

        SectionTitle {
            title: streamSection.title
            icon: "󰕾"
        }

        Repeater {
            model: streamSection.streams

            StreamRow {
                required property var modelData
                stream: modelData
                devices: streamSection.devices
            }
        }

        EmptyRow {
            visible: streamSection.streams.length === 0
            text: streamSection.emptyText
        }
    }

    component StreamRow: Rectangle {
        id: streamRow

        property var stream: null
        property var devices: []

        Layout.fillWidth: true
        implicitHeight: streamColumn.implicitHeight + 20
        radius: Config.radiusLarge
        color: Config.surface1Color
        z: routeSelector.expanded ? 30 : 0

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3
            radius: 2
            color: streamRow.stream?.muted ? Config.warningColor : Config.accentColor
        }

        ColumnLayout {
            id: streamColumn
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 10
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: Config.radius
                    color: Config.surface2Color

                    Text {
                        anchors.centerIn: parent
                        text: "󰝚"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeNormal
                        color: Config.accentColor
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: AudioService.appName(streamRow.stream)
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeNormal
                        font.bold: true
                        color: Config.textColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: streamRow.stream?.muted ? "Muted" : Math.round((streamRow.stream?.volume ?? 0) * 100) + "%"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        color: streamRow.stream?.muted ? Config.warningColor : Config.subtextColor
                    }
                }

                ActionButton {
                    icon: streamRow.stream?.muted ? "󰖁" : "󰕾"
                    baseColor: streamRow.stream?.muted ? Config.warningColor : Config.surface2Color
                    hoverColor: streamRow.stream?.muted ? Config.warningColor : Config.surface3Color
                    textColor: streamRow.stream?.muted ? Config.textReverseColor : Config.textColor
                    hoverTextColor: streamRow.stream?.muted ? Config.textReverseColor : Config.textColor
                    onClicked: {
                        AudioService.toggleStreamMute(streamRow.stream);
                    }
                }
            }

            QsSlider {
                value: streamRow.stream?.volume ?? 0
                icon: "󰕾"
                onMoved: value => {
                    AudioService.setStreamVolume(streamRow.stream, value);
                }
                onIconClicked: {
                    AudioService.toggleStreamMute(streamRow.stream);
                }
            }

            AudioDropdown {
                id: routeSelector
                Layout.fillWidth: true
                title: "Output route"
                currentLabel: AudioService.streamRouteLabel(streamRow.stream)
                direction: "up"
                controlHeight: 36
                devices: streamRow.devices
                emptyText: "No devices available"
                routeStream: streamRow.stream
                onSelected: device => {
                    AudioService.moveOutputStream(streamRow.stream, device);
                }
            }
        }
    }

    component AudioDropdown: Item {
        id: audioDropdown

        property string title: ""
        property string currentLabel: ""
        property string emptyText: ""
        property string direction: "down"
        property int controlHeight: 40
        property var devices: []
        property var activeDevice: null
        property var routeStream: null
        property bool expanded: false

        signal selected(var device)

        Layout.fillWidth: true
        Layout.preferredHeight: controlHeight
        z: expanded ? 20 : 0

        Rectangle {
            id: dropdownHeader
            Layout.fillWidth: true
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            implicitHeight: audioDropdown.controlHeight
            height: audioDropdown.controlHeight
            radius: Config.radius
            color: dropdownMouse.containsMouse ? Config.surface3Color : Config.surface2Color

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 3
                radius: 2
                color: Config.accentColor
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: audioDropdown.title
                        font.family: Config.font
                        font.pixelSize: 10
                        font.bold: true
                        color: Config.subtextColor
                    }

                    Text {
                        text: audioDropdown.devices.length > 0 ? audioDropdown.currentLabel : audioDropdown.emptyText
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        color: Config.textColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Text {
                    text: audioDropdown.expanded ? "" : ""
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeNormal
                    color: Config.textColor
                }
            }

            MouseArea {
                id: dropdownMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: audioDropdown.devices.length > 0
                onClicked: {
                    audioDropdown.expanded = !audioDropdown.expanded;
                }
            }
        }

        Rectangle {
            id: dropdownPanel
            visible: audioDropdown.expanded
            z: 50
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.min(dropdownOptions.implicitHeight + 2, 220)
            radius: Config.radius
            color: Config.backgroundColor
            border.width: 1
            border.color: Config.surface2Color
            clip: true

            states: [
                State {
                    name: "up"
                    when: audioDropdown.direction === "up"
                    AnchorChanges {
                        target: dropdownPanel
                        anchors.top: undefined
                        anchors.bottom: dropdownHeader.top
                    }
                    PropertyChanges {
                        target: dropdownPanel
                        anchors.topMargin: 0
                        anchors.bottomMargin: 2
                    }
                },
                State {
                    name: "down"
                    when: audioDropdown.direction !== "up"
                    AnchorChanges {
                        target: dropdownPanel
                        anchors.top: dropdownHeader.bottom
                        anchors.bottom: undefined
                    }
                    PropertyChanges {
                        target: dropdownPanel
                        anchors.topMargin: 2
                        anchors.bottomMargin: 0
                    }
                }
            ]

            ColumnLayout {
                id: dropdownOptions
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 1
                spacing: 1

                Repeater {
                    model: audioDropdown.devices

                    DropdownOption {
                        required property var modelData
                        label: AudioService.audioDeviceName(modelData)
                        subLabel: AudioService.audioDeviceSubName(modelData)
                        active: AudioService.nodeMatches(modelData, audioDropdown.activeDevice) || AudioService.streamRouteMatches(audioDropdown.routeStream, modelData)
                        onClicked: {
                            audioDropdown.selected(modelData);
                            audioDropdown.expanded = false;
                        }
                    }
                }
            }
        }
    }

    component DropdownOption: Rectangle {
        id: option

        property string label: ""
        property string subLabel: ""
        property bool active: false

        signal clicked

        Layout.fillWidth: true
        implicitHeight: option.subLabel !== "" ? 42 : 34
        color: optionMouse.containsMouse ? Config.surface2Color : Config.backgroundColor

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Text {
                text: option.active ? "󰄬" : "󰄰"
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                color: option.active ? Config.accentColor : Config.subtextColor
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: option.label
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    font.bold: option.active
                    color: Config.textColor
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    visible: option.subLabel !== ""
                    text: option.subLabel
                    font.family: Config.font
                    font.pixelSize: 10
                    color: Config.subtextColor
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        MouseArea {
            id: optionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                option.clicked();
            }
        }
    }

    component EmptyRow: Rectangle {
        id: emptyRow

        property string text: ""

        Layout.fillWidth: true
        implicitHeight: 42
        radius: Config.radius
        color: Config.surface1Color

        Text {
            anchors.centerIn: parent
            text: emptyRow.text
            font.family: Config.font
            font.pixelSize: Config.fontSizeSmall
            color: Config.subtextColor
        }
    }
}

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import "../../components/"

QsPopupWindow {
    id: root

    popupWidth: 340
    popupMaxHeight: 500
    anchorSide: "center"
    moduleName: "Calendar"
    contentImplicitHeight: calendarContent.implicitHeight

    // Calendar state
    property int displayMonth: today.getMonth()
    property int displayYear: today.getFullYear()
    property date selectedDate: today
    readonly property date today: TimeService.date

    function sameDate(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate();
    }

    function selectDate(date) {
        selectedDate = date;
        displayMonth = date.getMonth();
        displayYear = date.getFullYear();
    }

    function daysBetween(a, b) {
        const dayMs = 24 * 60 * 60 * 1000;
        const startA = new Date(a.getFullYear(), a.getMonth(), a.getDate());
        const startB = new Date(b.getFullYear(), b.getMonth(), b.getDate());
        return Math.round((startA.getTime() - startB.getTime()) / dayMs);
    }

    function relativeDateText(date) {
        const diff = daysBetween(date, today);

        if (diff === 0)
            return "Today";
        if (diff === 1)
            return "Tomorrow";
        if (diff === -1)
            return "Yesterday";
        if (diff > 1)
            return "In " + diff + " days";

        return Math.abs(diff) + " days ago";
    }

    function resetToToday() {
        selectDate(today);
    }

    function previousMonth() {
        if (displayMonth === 0) {
            displayMonth = 11;
            displayYear--;
        } else {
            displayMonth--;
        }
    }

    function nextMonth() {
        if (displayMonth === 11) {
            displayMonth = 0;
            displayYear++;
        } else {
            displayMonth++;
        }
    }

    onVisibleChanged: {
        if (visible)
            resetToToday();
    }

    ColumnLayout {
        id: calendarContent
        anchors.fill: parent
        spacing: 10

        // ==================== HEADER ====================
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: Config.radius
                color: Qt.alpha(Config.accentColor, 0.15)

                Text {
                    anchors.centerIn: parent
                    text: "󰃭"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeLarge
                    color: Config.accentColor
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "Calendar"
                    font.family: Config.font
                    font.bold: true
                    font.pixelSize: Config.fontSizeLarge
                    color: Config.textColor
                    Layout.fillWidth: true
                }

                Text {
                    text: TimeService.format("dddd, MMMM dd")
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    color: Config.subtextColor
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                Layout.preferredHeight: 26
                Layout.preferredWidth: todayBadgeContent.implicitWidth + 14
                radius: Config.radius
                color: root.sameDate(root.selectedDate, root.today) ? Qt.alpha(Config.accentColor, 0.18) : Config.surface1Color

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                    }
                }

                RowLayout {
                    id: todayBadgeContent
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "󰃶"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        color: root.sameDate(root.selectedDate, root.today) ? Config.accentColor : Config.subtextColor
                    }

                    Text {
                        text: root.relativeDateText(root.selectedDate)
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        font.bold: true
                        color: root.sameDate(root.selectedDate, root.today) ? Config.accentColor : Config.subtextColor
                    }
                }
            }
        }

        // ==================== SEPARATOR ====================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Config.surface1Color
        }

        // ==================== MONTH NAVIGATION ====================
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: height / 2
                color: prevHover.hovered ? Config.surface1Color : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeNormal
                    color: Config.subtextColor
                }

                HoverHandler {
                    id: prevHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.previousMonth()
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: monthLabel.implicitHeight

                Text {
                    id: monthLabel
                    anchors.centerIn: parent
                    text: new Date(root.displayYear, root.displayMonth, 1).toLocaleDateString(Qt.locale(), "MMMM yyyy")
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeNormal
                    font.bold: true
                    font.capitalization: Font.Capitalize
                    color: Config.textColor
                }

                HoverHandler {
                    cursorShape: {
                        const now = new Date();
                        if (root.displayMonth === now.getMonth() && root.displayYear === now.getFullYear())
                            return Qt.ArrowCursor;
                        return Qt.PointingHandCursor;
                    }
                }

                TapHandler {
                    onTapped: root.resetToToday()
                }
            }

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: height / 2
                color: nextHover.hovered ? Config.surface1Color : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰅂"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeNormal
                    color: Config.subtextColor
                }

                HoverHandler {
                    id: nextHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.nextMonth()
                }
            }
        }

        // ==================== DAY OF WEEK HEADER ====================
        DayOfWeekRow {
            Layout.fillWidth: true
            locale: grid.locale

            delegate: Text {
                required property var model

                horizontalAlignment: Text.AlignHCenter
                text: model.shortName
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                font.bold: true
                color: (model.day === 0 || model.day === 6) ? Config.subtextColor : Config.textColor
            }
        }

        // ==================== MONTH GRID ====================
        Item {
            Layout.fillWidth: true
            implicitHeight: grid.implicitHeight

            MonthGrid {
                id: grid

                month: root.displayMonth
                year: root.displayYear
                anchors.fill: parent
                spacing: 2
                locale: Qt.locale()

                delegate: Item {
                    id: dayCell

                    required property var model

                    readonly property bool isToday: model.today
                    readonly property bool isSelected: root.sameDate(model.date, root.selectedDate)
                    readonly property bool isCurrentMonth: model.month === grid.month
                    readonly property bool isWeekend: {
                        const dow = model.date.getUTCDay();
                        return dow === 0 || dow === 6;
                    }

                    implicitWidth: implicitHeight
                    implicitHeight: dayText.implicitHeight + 8

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height)
                        height: width
                        radius: width / 2
                        color: {
                            if (dayCell.isToday)
                                return Config.accentColor;
                            if (dayCell.isSelected)
                                return Config.surface2Color;
                            if (dayHover.hovered)
                                return Config.surface1Color;
                            return "transparent";
                        }
                        border.width: dayCell.isSelected && !dayCell.isToday ? 1 : 0
                        border.color: Config.accentColor

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration
                            }
                        }
                    }

                    Text {
                        id: dayText
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: dayCell.model.day
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        font.bold: dayCell.isToday || dayCell.isSelected
                        color: {
                            if (dayCell.isToday)
                                return Config.textReverseColor;
                            if (dayCell.isSelected)
                                return Config.textColor;
                            if (dayCell.isWeekend)
                                return Config.subtextColor;
                            return Config.textColor;
                        }
                        opacity: dayCell.isCurrentMonth ? 1.0 : 0.3
                    }

                    HoverHandler {
                        id: dayHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: root.selectDate(dayCell.model.date)
                    }
                }
            }

            WheelHandler {
                onWheel: event => {
                    if (event.angleDelta.y > 0)
                        root.previousMonth();
                    else if (event.angleDelta.y < 0)
                        root.nextMonth();
                }
            }
        }
    }
}

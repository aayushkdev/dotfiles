pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config

PanelWindow {
    id: root

    required property var screenshot

    visible: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"

    // Monitor info
    property var hyprMonitor: Hyprland.monitorFor(modelData)
    property bool isActiveMonitor: screen === root.screenshot.activeScreen

    // =================================================================
    // FROZEN SCREEN CAPTURE - using grim captured image
    // =================================================================

    Image {
        anchors.fill: parent
        source: root.screenshot.captureTimestamp ? "file://" + root.screenshot.tempPathForScreen(root.screen.name) : ""
        fillMode: Image.PreserveAspectCrop
        z: 0
        cache: false
    }

    // =================================================================
    // DIMMING SHADER
    // =================================================================

    ShaderEffect {
        anchors.fill: parent
        z: 1
        visible: root.isActiveMonitor

        property vector4d selectionRect: Qt.vector4d(root.screenshot.selectionX, root.screenshot.selectionY, root.screenshot.selectionWidth, root.screenshot.selectionHeight)
        property real dimOpacity: 0.6
        property vector2d screenSize: Qt.vector2d(width, height)
        property real borderRadius: Config.radius
        property real outlineThickness: 2.0

        fragmentShader: Qt.resolvedUrl("dimming.frag.qsb")
    }

    // Dim inactive monitors
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        visible: !root.isActiveMonitor
        z: 1
    }

    // =================================================================
    // REGION SELECTOR
    // =================================================================

    RegionSelector {
        id: regionSelector
        anchors.fill: parent
        visible: root.isActiveMonitor && root.screenshot.mode === "region"
        screenshot: root.screenshot
        z: 2
    }

    // =================================================================
    // WINDOW SELECTOR
    // =================================================================

    WindowSelector {
        anchors.fill: parent
        visible: root.isActiveMonitor && root.screenshot.mode === "window"
        screenshot: root.screenshot
        monitorScreen: root.screen
        z: 3
    }

    // =================================================================
    // MOUSE INTERACTION
    // =================================================================

    MouseArea {
        id: mainMouse
        anchors.fill: parent
        z: 5
        hoverEnabled: true
        property real startX: 0
        property real startY: 0
        property bool dragging: false
        property bool draggingMove: false
        property bool draggingResize: false
        property string resizeHandle: ""
        property real handleMargin: 8

        function inSelection(x, y) {
            return x >= root.screenshot.selectionX && x <= root.screenshot.selectionX + root.screenshot.selectionWidth && y >= root.screenshot.selectionY && y <= root.screenshot.selectionY + root.screenshot.selectionHeight;
        }

        function hitTestHandle(x, y) {
            if (!root.screenshot.hasSelection)
                return "";
            var left = root.screenshot.selectionX;
            var right = root.screenshot.selectionX + root.screenshot.selectionWidth;
            var top = root.screenshot.selectionY;
            var bottom = root.screenshot.selectionY + root.screenshot.selectionHeight;
            var m = handleMargin;

            var nearLeft = Math.abs(x - left) <= m;
            var nearRight = Math.abs(x - right) <= m;
            var nearTop = Math.abs(y - top) <= m;
            var nearBottom = Math.abs(y - bottom) <= m;

            if (nearLeft && nearTop) return "topleft";
            if (nearRight && nearTop) return "topright";
            if (nearLeft && nearBottom) return "bottomleft";
            if (nearRight && nearBottom) return "bottomright";
            if (nearLeft && y >= top - m && y <= bottom + m) return "left";
            if (nearRight && y >= top - m && y <= bottom + m) return "right";
            if (nearTop && x >= left - m && x <= right + m) return "top";
            if (nearBottom && x >= left - m && x <= right + m) return "bottom";
            if (inSelection(x, y)) return "move";
            return "";
        }

        cursorShape: {
            if (root.screenshot.mode === "window")
                return Qt.PointingHandCursor;
            if (root.screenshot.mode === "screen")
                return Qt.ArrowCursor;
            if (root.screenshot.mode === "region" && root.screenshot.hasSelection) {
                var h = hitTestHandle(mouseX, mouseY);
                if (h === "move") return Qt.SizeAllCursor;
                if (h === "left" || h === "right") return Qt.SizeHorCursor;
                if (h === "top" || h === "bottom") return Qt.SizeVerCursor;
                if (h === "topleft" || h === "bottomright") return Qt.SizeBDiagCursor;
                if (h === "topright" || h === "bottomleft") return Qt.SizeFDiagCursor;
            }
            return root.screenshot.hasSelection ? Qt.ArrowCursor : Qt.CrossCursor;
        }

        onEntered: {
            root.screenshot.activeScreen = root.screen;
            root.screenshot.hyprlandMonitor = root.hyprMonitor;

            if (root.screenshot.mode === "screen") {
                root.screenshot.setMode("screen");
            }
        }

        onPositionChanged: mouse => {
            regionSelector.guideMouseX = mouse.x;
            regionSelector.guideMouseY = mouse.y;
            if (root.screenshot.mode === "window" && !root.screenshot.hasSelection) {
                root.screenshot.checkWindowAt(mouse.x, mouse.y, root.screen.name);
            }

            if (root.screenshot.activeScreen !== root.screen) {
                root.screenshot.activeScreen = root.screen;
                root.screenshot.hyprlandMonitor = root.hyprMonitor;
                if (root.screenshot.mode === "screen") {
                    root.screenshot.setMode("screen");
                }
            }

            if (dragging && root.screenshot.mode === "region") {
                if (!root.screenshot.hasSelection) {
                    // initial drag to create selection
                    root.screenshot.selectionX = Math.min(startX, mouse.x);
                    root.screenshot.selectionY = Math.min(startY, mouse.y);
                    root.screenshot.selectionWidth = Math.abs(mouse.x - startX);
                    root.screenshot.selectionHeight = Math.abs(mouse.y - startY);
                } else if (draggingMove) {
                    var dx = mouse.x - startX;
                    var dy = mouse.y - startY;
                    startX = mouse.x;
                    startY = mouse.y;
                    // move and clamp
                    var newX = root.screenshot.selectionX + dx;
                    var newY = root.screenshot.selectionY + dy;
                    newX = Math.max(0, Math.min(newX, width - root.screenshot.selectionWidth));
                    newY = Math.max(0, Math.min(newY, height - root.screenshot.selectionHeight));
                    root.screenshot.selectionX = newX;
                    root.screenshot.selectionY = newY;
                } else if (draggingResize) {
                    var minSize = 5;
                    var sX = root.screenshot.selectionX;
                    var sY = root.screenshot.selectionY;
                    var sW = root.screenshot.selectionWidth;
                    var sH = root.screenshot.selectionHeight;
                    var px = mouse.x;
                    var py = mouse.y;

                    if (resizeHandle.indexOf("left") !== -1) {
                        var newLeft = Math.min(px, sX + sW - minSize);
                        root.screenshot.selectionWidth = sX + sW - newLeft;
                        root.screenshot.selectionX = Math.max(0, newLeft);
                    }
                    if (resizeHandle.indexOf("right") !== -1) {
                        var newW = Math.max(minSize, px - sX);
                        root.screenshot.selectionWidth = Math.min(newW, width - sX);
                    }
                    if (resizeHandle.indexOf("top") !== -1) {
                        var newTop = Math.min(py, sY + sH - minSize);
                        root.screenshot.selectionHeight = sY + sH - newTop;
                        root.screenshot.selectionY = Math.max(0, newTop);
                    }
                    if (resizeHandle.indexOf("bottom") !== -1) {
                        var newH = Math.max(minSize, py - sY);
                        root.screenshot.selectionHeight = Math.min(newH, height - sY);
                    }
                }
            }
        }

        onPressed: mouse => {
            if (root.screenshot.mode === "region") {
                if (!root.screenshot.hasSelection) {
                    startX = mouse.x;
                    startY = mouse.y;
                    root.screenshot.selectionX = mouse.x;
                    root.screenshot.selectionY = mouse.y;
                    root.screenshot.selectionWidth = 0;
                    root.screenshot.selectionHeight = 0;
                    dragging = true;
                } else {
                    // hit test for move/resize
                    var hit = hitTestHandle(mouse.x, mouse.y);
                    if (hit === "") {
                        // click outside selection: start new selection
                        startX = mouse.x;
                        startY = mouse.y;
                        root.screenshot.selectionX = mouse.x;
                        root.screenshot.selectionY = mouse.y;
                        root.screenshot.selectionWidth = 0;
                        root.screenshot.selectionHeight = 0;
                        root.screenshot.hasSelection = false;
                        dragging = true;
                        draggingMove = false;
                        draggingResize = false;
                        resizeHandle = "";
                    } else if (hit === "move") {
                        startX = mouse.x;
                        startY = mouse.y;
                        dragging = true;
                        root.screenshot.suppressSelectionAnimations = true;
                        draggingMove = true;
                        draggingResize = false;
                        resizeHandle = "";
                    } else {
                        // resize handle
                        startX = mouse.x;
                        startY = mouse.y;
                        dragging = true;
                        draggingMove = false;
                        draggingResize = true;
                        resizeHandle = hit;
                    }
                }
            }
            else if (root.screenshot.mode === "window" && !root.screenshot.hasSelection) {
                startX = mouse.x;
                startY = mouse.y;
            }
        }

        onReleased: mouse => {
            root.screenshot.suppressSelectionAnimations = false;
            dragging = false;
            draggingMove = false;
            draggingResize = false;
            resizeHandle = "";

            if (root.screenshot.mode === "region" && !root.screenshot.hasSelection) {
                if (root.screenshot.selectionWidth > 10 && root.screenshot.selectionHeight > 10) {
                    root.screenshot.hasSelection = true;
                }
            } else if (root.screenshot.mode === "window" && !root.screenshot.hasSelection) {
                if (mouse.x >= root.screenshot.selectionX && mouse.x <= root.screenshot.selectionX + root.screenshot.selectionWidth && mouse.y >= root.screenshot.selectionY && mouse.y <= root.screenshot.selectionY + root.screenshot.selectionHeight) {
                    root.screenshot.hasSelection = true;
                }
            }
        }
    }

    // =================================================================
    // SHORTCUTS
    // =================================================================

    Shortcut {
        sequence: "Escape"
        onActivated: root.screenshot.cancelCapture()
    }

    Shortcut {
        sequence: "r"
        onActivated: root.screenshot.setMode("region")
    }

    Shortcut {
        sequence: "w"
        onActivated: root.screenshot.setMode("window")
    }

    Shortcut {
        sequence: "s"
        onActivated: root.screenshot.setMode("screen")
    }

    // =================================================================
    // CONTROL BAR
    // =================================================================

    ControlBar {
        visible: root.isActiveMonitor
        screenshot: root.screenshot
        z: 10
    }

    // =================================================================
    // DIMENSION INDICATOR
    // =================================================================

    Rectangle {
        visible: root.isActiveMonitor && root.screenshot.selectionWidth > 60 && root.screenshot.selectionHeight > 40 && root.screenshot.mode !== "screen"
        z: 6

        x: root.screenshot.selectionX + root.screenshot.selectionWidth / 2 - width / 2
        y: root.screenshot.selectionY + root.screenshot.selectionHeight / 2 - height / 2

        width: dimLabel.implicitWidth + 16
        height: dimLabel.implicitHeight + 8
        radius: Config.radiusSmall
        color: Qt.alpha(Config.surface0Color, 0.9)

        Text {
            id: dimLabel
            anchors.centerIn: parent
            text: Math.round(root.screenshot.selectionWidth) + " × " + Math.round(root.screenshot.selectionHeight)
            font.family: Config.font
            font.pixelSize: Config.fontSizeSmall
            font.bold: true
            color: Config.textColor
        }
    }

    // =================================================================
    // WINDOW/MONITOR INFO
    // =================================================================

    Rectangle {
        visible: root.isActiveMonitor && (root.screenshot.mode === "window" || root.screenshot.mode === "screen") && root.screenshot.selectedWindowTitle !== ""
        z: 6

        x: root.screenshot.selectionX + 12
        y: root.screenshot.selectionY + 12

        width: infoRow.implicitWidth + 20
        height: 40
        radius: Config.radius
        color: Qt.alpha(Config.surface0Color, 0.95)
        border.width: 2
        border.color: Config.accentColor

        Row {
            id: infoRow
            anchors.centerIn: parent
            spacing: 10

            Text {
                text: root.screenshot.mode === "screen" ? "󰍹" : "󰖯"
                font.family: Config.font
                font.pixelSize: Config.fontSizeIcon
                color: Config.accentColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: root.screenshot.selectedWindowTitle
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    font.bold: true
                    color: Config.textColor
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, 220)
                }

                Text {
                    visible: root.screenshot.selectedWindowClass !== "" && root.screenshot.selectedWindowClass !== root.screenshot.selectedWindowTitle
                    text: root.screenshot.selectedWindowClass
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    color: Config.subtextColor
                }
            }
        }
    }

    // =================================================================
    // USAGE HINT
    // =================================================================

    Rectangle {
        visible: root.isActiveMonitor && !root.screenshot.hasSelection && root.screenshot.mode === "region"
        z: 10

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 20
        anchors.bottomMargin: 40

        width: hintRow.implicitWidth + 16
        height: 32
        radius: Config.radius
        color: Qt.alpha(Config.surface0Color, 0.9)

        Row {
            id: hintRow
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                width: escLabel.implicitWidth + 8
                height: escLabel.implicitHeight + 4
                radius: 4
                color: Config.surface1Color
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: escLabel
                    anchors.centerIn: parent
                    text: "ESC"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    font.bold: true
                    color: Config.subtextColor
                }
            }

            Text {
                text: "Drag to select region"
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                color: Config.subtextColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}

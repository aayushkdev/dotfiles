pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    // ========================================================================
    // PROPERTIES
    // ========================================================================

    property bool visible: false
    property string type: "volume" // "volume", "microphone", "brightness", "idleInhibit"
    property real value: 0
    property bool muted: false

    // ========================================================================
    // HIDE TIMER
    // ========================================================================

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.visible = false
    }

    // ========================================================================
    // PUBLIC FUNCTIONS
    // ========================================================================

    function showVolume(vol: real, isMuted: bool) {
        root.type = "volume";
        root.value = vol;
        root.muted = isMuted;
        root.visible = true;
        hideTimer.restart();
    }

    function showMicrophone(vol: real, isMuted: bool) {
        root.type = "microphone";
        root.value = vol;
        root.muted = isMuted;
        root.visible = true;
        hideTimer.restart();
    }

    function showBrightness(brightness: real) {
        root.type = "brightness";
        root.value = brightness;
        root.muted = false;
        root.visible = true;
        hideTimer.restart();
    }

    function showIdleInhibit(enabled: bool) {
        root.type = "idleInhibit";
        root.value = enabled ? 1 : 0;
        root.muted = !enabled;
        root.visible = true;
        hideTimer.restart();
    }

    function hide() {
        root.visible = false;
    }
}

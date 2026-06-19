pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    // Returns true if a laptop battery was found
    readonly property bool hasBattery: mainBattery !== null

    // Percentage (0 to 100)
    readonly property int percentage: mainBattery ? Math.round(mainBattery.percentage * 100) : 0

    // State (Charging, Discharging, Full...)
    readonly property int state: mainBattery ? mainBattery.state : UPowerDeviceState.Unknown

    // Boolean helper to simplify UI bindings
    readonly property bool isCharging: state === UPowerDeviceState.Charging || state === UPowerDeviceState.PendingCharge || state === UPowerDeviceState.Full
    readonly property bool isDischarging: state === UPowerDeviceState.Discharging || state === UPowerDeviceState.PendingDischarge
    readonly property real powerWatts: mainBattery ? (mainBattery.changeRate ?? 0) : 0
    readonly property string rateText: {
        if (powerWatts <= 0)
            return isCharging || isDischarging ? "-- W" : "Idle";
        if (isCharging)
            return "+" + powerWatts.toFixed(1) + " W";
        if (isDischarging)
            return "-" + powerWatts.toFixed(1) + " W";
        return powerWatts.toFixed(1) + " W";
    }
    readonly property string statusText: {
        if (state === UPowerDeviceState.Charging || state === UPowerDeviceState.PendingCharge)
            return "Charging";
        if (state === UPowerDeviceState.Discharging || state === UPowerDeviceState.PendingDischarge)
            return "Discharging";
        if (state === UPowerDeviceState.Full)
            return "Full";
        return "Idle";
    }

    // Holds the reference to the battery object
    property var mainBattery: null

    // The Instantiator scans the device list without creating visuals
    Instantiator {
        model: UPower.devices

        delegate: QtObject {
            required property var modelData
            
            // When a device is created or changes, we check if it is the main battery
            Component.onCompleted: checkDevice()
            
            function checkDevice() {
                if (modelData && modelData.isLaptopBattery) {
                    root.mainBattery = modelData
                    root.checkBatteryNotifications()
                }
            }
        }
    }

    Connections {
        target: root.mainBattery
        enabled: root.mainBattery !== null

        function onPercentageChanged() {
            root.checkBatteryNotifications()
        }

        function onStateChanged() {
            root.checkBatteryNotifications()
        }
    }

    // Icon logic here.
    function getBatteryIcon() {
        if (state === UPowerDeviceState.Charging) return "󰂄"

        const p = percentage
        if (p >= 100) return "󰁹"
        if (p >= 90) return "󰂂"
        if (p >= 80) return "󰂁"
        if (p >= 70) return "󰂀"
        if (p >= 60) return "󰁿"
        if (p >= 50) return "󰁾"
        if (p >= 40) return "󰁽"
        if (p >= 30) return "󰁼"
        if (p >= 20) return "󰁻"
        return "󰁺"
    }

    readonly property int lowWarningLevel: 20
    readonly property int criticalWarningLevel: 10
    readonly property int hysteresis: 5
    property int lastNotifiedLevel: 0

    function notifyBattery(title, body, urgency) {
        const escapedTitle = title.replace(/'/g, "'\\''");
        const escapedBody = body.replace(/'/g, "'\\''");
        const cmd = "if command -v notify-send >/dev/null 2>&1; then " +
                    "notify-send -t 0 -u '" + urgency + "' -i battery '" + escapedTitle + "' '" + escapedBody + "'; " +
                    "else echo '[battery-notify:" + urgency + "] " + escapedTitle + " - " + escapedBody + "'; fi";

        batteryNotifyProc.command = ["bash", "-c", cmd];
        batteryNotifyProc.running = true;
    }

    function checkBatteryNotifications() {
        if (!root.hasBattery)
            return;

        const p = root.percentage;
        const isCharging = root.isCharging;

        if (isCharging) {
            if (root.lastNotifiedLevel !== 0 && p >= root.lowWarningLevel + root.hysteresis) {
                root.lastNotifiedLevel = 0;
            }
            return;
        }

        if (p <= root.criticalWarningLevel) {
            if (root.lastNotifiedLevel !== root.criticalWarningLevel) {
                notifyBattery(
                    "Battery critically low",
                    "Battery at " + p + "% — plug in now!",
                    "critical"
                );
                root.lastNotifiedLevel = root.criticalWarningLevel;
            }
        } else if (p <= root.lowWarningLevel) {
            if (root.lastNotifiedLevel !== root.lowWarningLevel) {
                notifyBattery(
                    "Battery low",
                    "Battery at " + p + "% — consider plugging in.",
                    "normal"
                );
                root.lastNotifiedLevel = root.lowWarningLevel;
            }
        } else if (root.lastNotifiedLevel !== 0 && p >= root.lowWarningLevel + root.hysteresis) {
            root.lastNotifiedLevel = 0;
        }
    }

    Process {
        id: batteryNotifyProc
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                console.warn("[BatteryService] battery notification failed:", exitCode, exitStatus);
            }
        }
    }

    Component.onCompleted: {
        // trigger an immediate check on startup
        checkBatteryNotifications();
    }
}

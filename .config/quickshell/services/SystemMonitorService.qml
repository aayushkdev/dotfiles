pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ========================================================================
    // CPU PROPERTIES
    // ========================================================================

    readonly property int cpuUsage: internal.cpuUsage
    readonly property int cpuTemp: internal.cpuTemp
    readonly property string cpuIcon: "󰻠"

    // ========================================================================
    // RAM PROPERTIES
    // ========================================================================

    readonly property int ramUsage: internal.ramUsage
    readonly property string ramUsed: internal.ramUsed   // GiB, e.g. "5.2"
    readonly property string ramTotal: internal.ramTotal  // GiB, e.g. "15.8"

    // ========================================================================
    // DISK PROPERTIES
    // ========================================================================

    readonly property int diskUsage: internal.diskUsage
    readonly property string diskUsed: internal.diskUsed   // GiB
    readonly property string diskTotal: internal.diskTotal  // GiB

    // ========================================================================
    // NETWORK PROPERTIES
    // ========================================================================

    readonly property string networkDown: internal.networkDown // e.g. "1.2 MB/s"
    readonly property string networkUp: internal.networkUp     // e.g. "340 KB/s"

    // ========================================================================
    // UPTIME
    // ========================================================================

    readonly property string uptime: internal.uptime // e.g. "2d 5h" or "3h 12m"
    property bool detailedPollingEnabled: false

    // ========================================================================
    // INTERNAL STATE
    // ========================================================================

    QtObject {
        id: internal

        // CPU
        property int cpuUsage: 0
        property int cpuTemp: 0

        // CPU calculation state
        property real prevTotal: 0
        property real prevIdle: 0

        // RAM
        property int ramUsage: 0
        property string ramUsed: "0"
        property string ramTotal: "0"

        // Disk
        property int diskUsage: 0
        property string diskUsed: "0"
        property string diskTotal: "0"

        // Network
        property string networkDown: "0 B/s"
        property string networkUp: "0 B/s"
        property real prevRx: 0
        property real prevTx: 0

        // Uptime
        property string uptime: "0m"
    }

    // ========================================================================
    // INITIALIZATION
    // ========================================================================

    Component.onCompleted: {
        updateCpuUsage.running = true;
        updateRam.running = true;
    }

    // ========================================================================
    // UPDATE TIMER
    // ========================================================================

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            updateCpuUsage.running = true;
            updateRam.running = true;
        }
    }

    Timer {
        interval: 2000
        running: root.detailedPollingEnabled
        repeat: true
        onTriggered: root.updateDetails()
    }

    // Disk updates less frequently (every 30s)
    Timer {
        interval: 30000
        running: root.detailedPollingEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: updateDisk.running = true
    }

    // ========================================================================
    // HELPER FUNCTIONS
    // ========================================================================

    function _formatBytes(bytes) {
        if (bytes >= 1073741824) {
            return (bytes / 1073741824).toFixed(1) + " GB/s";
        } else if (bytes >= 1048576) {
            return (bytes / 1048576).toFixed(1) + " MB/s";
        } else if (bytes >= 1024) {
            return (bytes / 1024).toFixed(0) + " KB/s";
        }
        return bytes.toFixed(0) + " B/s";
    }

    function _formatGiB(bytes) {
        return (bytes / 1073741824).toFixed(1);
    }

    function updateDetails() {
        updateCpuTemp.running = true;
        updateNetwork.running = true;
        updateUptime.running = true;
    }

    onDetailedPollingEnabledChanged: {
        if (detailedPollingEnabled)
            updateDetails();
    }

    // ========================================================================
    // CPU MONITORING
    // ========================================================================

    Process {
        id: updateCpuUsage
        command: ["bash", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/);
                if (parts.length >= 5) {
                    const user = parseFloat(parts[1]) || 0;
                    const nice = parseFloat(parts[2]) || 0;
                    const system = parseFloat(parts[3]) || 0;
                    const idle = parseFloat(parts[4]) || 0;
                    const iowait = parseFloat(parts[5]) || 0;
                    const irq = parseFloat(parts[6]) || 0;
                    const softirq = parseFloat(parts[7]) || 0;
                    const steal = parseFloat(parts[8]) || 0;

                    const total = user + nice + system + idle + iowait + irq + softirq + steal;
                    const idleTime = idle + iowait;

                    if (internal.prevTotal > 0) {
                        const totalDiff = total - internal.prevTotal;
                        const idleDiff = idleTime - internal.prevIdle;

                        if (totalDiff > 0) {
                            const usage = Math.round(((totalDiff - idleDiff) / totalDiff) * 100);
                            internal.cpuUsage = Math.max(0, Math.min(100, usage));
                        }
                    }

                    internal.prevTotal = total;
                    internal.prevIdle = idleTime;
                }
            }
        }
    }

    Process {
        id: updateCpuTemp
        command: ["bash", "-c", `
            for zone in /sys/class/thermal/thermal_zone*/temp; do
                type_file="\${zone%/temp}/type"
                if [ -f "$type_file" ]; then
                    type=$(cat "$type_file" 2>/dev/null)
                    if [[ "$type" == *"cpu"* ]] || [[ "$type" == *"x86_pkg"* ]] || [[ "$type" == *"coretemp"* ]]; then
                        cat "$zone" 2>/dev/null
                        exit 0
                    fi
                fi
            done
            cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "0"
        `]
        stdout: SplitParser {
            onRead: data => {
                const temp = parseInt(data.trim());
                if (!isNaN(temp)) {
                    internal.cpuTemp = Math.round(temp / 1000);
                }
            }
        }
    }

    // ========================================================================
    // RAM MONITORING
    // ========================================================================

    Process {
        id: updateRam
        command: ["bash", "-c", "free -b | awk '/Mem:/{print $2,$3}'"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/);
                if (parts.length >= 2) {
                    const total = parseFloat(parts[0]);
                    const used = parseFloat(parts[1]);
                    if (total > 0) {
                        internal.ramUsage = Math.round((used / total) * 100);
                        internal.ramUsed = root._formatGiB(used);
                        internal.ramTotal = root._formatGiB(total);
                    }
                }
            }
        }
    }

    // ========================================================================
    // DISK MONITORING
    // ========================================================================

    Process {
        id: updateDisk
        command: ["bash", "-c", "df -B1 --output=size,used,pcent / | awk 'NR==2{gsub(/%/, \"\", $3); print $1,$2,$3}'"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/);
                if (parts.length >= 3) {
                    const total = parseFloat(parts[0]);
                    const used = parseFloat(parts[1]);
                    const usage = parseInt(parts[2]);
                    if (total > 0) {
                        internal.diskUsage = isNaN(usage) ? Math.round((used / total) * 100) : usage;
                        internal.diskUsed = root._formatGiB(used);
                        internal.diskTotal = root._formatGiB(total);
                    }
                }
            }
        }
    }

    // ========================================================================
    // NETWORK MONITORING
    // ========================================================================

    Process {
        id: updateNetwork
        command: ["bash", "-c", `
            rx=0; tx=0
            for iface in /sys/class/net/*/; do
                name=$(basename "$iface")
                [ "$name" = "lo" ] && continue
                [ -f "$iface/statistics/rx_bytes" ] || continue
                rx=$((rx + $(cat "$iface/statistics/rx_bytes")))
                tx=$((tx + $(cat "$iface/statistics/tx_bytes")))
            done
            echo "$rx $tx"
        `]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/);
                if (parts.length >= 2) {
                    const rx = parseFloat(parts[0]);
                    const tx = parseFloat(parts[1]);

                    if (internal.prevRx > 0) {
                        const rxDelta = (rx - internal.prevRx) / 2; // per second (2s interval)
                        const txDelta = (tx - internal.prevTx) / 2;
                        internal.networkDown = root._formatBytes(Math.max(0, rxDelta));
                        internal.networkUp = root._formatBytes(Math.max(0, txDelta));
                    }

                    internal.prevRx = rx;
                    internal.prevTx = tx;
                }
            }
        }
    }

    // ========================================================================
    // UPTIME
    // ========================================================================

    Process {
        id: updateUptime
        command: ["bash", "-c", "awk '{print int($1)}' /proc/uptime"]
        stdout: SplitParser {
            onRead: data => {
                const totalSeconds = parseInt(data.trim());
                if (isNaN(totalSeconds)) return;

                const days = Math.floor(totalSeconds / 86400);
                const hours = Math.floor((totalSeconds % 86400) / 3600);
                const minutes = Math.floor((totalSeconds % 3600) / 60);

                if (days > 0) {
                    internal.uptime = days + "d " + hours + "h";
                } else if (hours > 0) {
                    internal.uptime = hours + "h " + minutes + "m";
                } else {
                    internal.uptime = minutes + "m";
                }
            }
        }
    }

}

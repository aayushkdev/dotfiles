pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Update the icon to its true self at startup
    Component.onCompleted: {
        findInterfaceProc.running = true;
        statusProc.running = true;
        activeConnectionProc.running = true; 
        connectivityProc.running = true;
        getSavedProc.running = true;

        Qt.callLater(()=>{
            getNetworksProc.running = true;
        });

    }

    property var accessPoints: []
    property var savedSsids: []
    property bool wifiEnabled: true
    property bool wifiConnected: false
    property string activeConnection: ""
    property string connectivityState: "unknown"
    property string wifiInterface: ""
    property string connectingSsid: ""
    readonly property bool scanning: rescanProc.running
    readonly property string systemIcon: {
        if (!wifiEnabled)
            return "󰤮";

        if (!wifiConnected)
            return "󰤯";

        if (connectivityState === "portal")
            return "󰤩";

        if (connectivityState === "none" || connectivityState === "limited")
            return "󰤫";

        const activeNetwork = accessPoints.find(ap => ap.ssid === activeConnection);

        if (!activeNetwork)
            return "󰤨";  // fallback if scan delayed

        return getWifiIcon(activeNetwork.signal);
    }

    // --- FUNCTIONS ---

    function getWifiIcon(signal) {
        if (signal > 80)
            return "󰤨";
        if (signal > 60)
            return "󰤥";
        if (signal > 40)
            return "󰤢";
        if (signal > 20)
            return "󰤟";
        return "󰤫";
    }

    // Status text
    readonly property string statusText: {
        if (!wifiEnabled)
            return "Off";

        const activeNetwork =
            accessPoints.find(ap => ap.ssid === activeConnection);

        if (!activeNetwork)
            return "On";

        if (connectivityState === "portal")
            return activeNetwork.ssid + " (Login required)";

        if (connectivityState === "limited")
            return activeNetwork.ssid + " (Limited)";

        if (connectivityState === "none")
            return activeNetwork.ssid + " (No internet)";

        return activeNetwork.ssid;
    }

    function toggleWifi() {
        const cmd = wifiEnabled ? "off" : "on";
        toggleWifiProc.command = ["nmcli", "radio", "wifi", cmd];
        toggleWifiProc.running = true;
    }

    function scan() {
        if (rescanProc.running || getNetworksProc.running)
            return;

        rescanProc.running = true;
    }

    function disconnect() {
        if (wifiInterface !== "") {
            console.log("Disconnecting interface: " + wifiInterface);
            disconnectProc.command = ["nmcli", "dev", "disconnect", wifiInterface];
            disconnectProc.running = true;
        }
    }

    function connect(ssid, password) {
        console.log("Attempting to connect to:", ssid);
        root.connectingSsid = ssid; // Mark which one we are trying

        if (password && password.length > 0) {
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid, "password", password];
        } else {
            // Try connecting using saved profile
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid];
        }
        connectProc.running = true;
    }

    function forget(ssid) {
        console.log("Forgetting network: " + ssid);
        forgetProc.command = ["nmcli", "connection", "delete", "id", ssid];
        forgetProc.running = true;
    }

    // --- PROCESSES ---

    // Connection Process
    Process {
        id: connectProc

        stdout: SplitParser {
            onRead: data => console.log("[Wifi] " + data)
        }
        stderr: SplitParser {
            onRead: data => console.error("[Wifi Error] " + data)
        }

        onExited: code => {
            // If exit code is 0, success. Otherwise, there was an error (wrong password, timeout, etc).
            if (code !== 0) {
                console.error("Failed to connect. Exit code: " + code);

            } else {
                console.log("Connected successfully!");
            }

            // Reset state and update lists
            root.connectingSsid = "";
            getSavedProc.running = true;
            getNetworksProc.running = true;
            connectivityProc.running = true;
            activeConnectionProc.running = true;
        }
    }

    // NMCLI monitor loop to detect connection/radio changes
    Process {
        id: monitorProc
        command: ["nmcli","monitor"]
        running: true

        stdout: SplitParser {
            onRead: data => {

                // Connection changes
                if (data.includes("Connectivity is now"))
                    connectivityProc.running = true;

                if (data.includes("connected") ||
                    data.includes("disconnected"))
                {
                    getNetworksProc.running = true;
                    getSavedProc.running = true;
                    activeConnectionProc.running = true;
                }

                // Wifi radio changes
                if (data.includes("wifi")) {
                    statusProc.running = true;
                }
            }
        }
    }

    // Periodically checks overall network connectivity state
    Process {
        id: connectivityProc

        command:["nmcli","-t","-f","CONNECTIVITY","general"]

        stdout: SplitParser {
            onRead: data => {

                const state = data.trim();
                root.connectivityState = state;
            }
        }
    }

    // Reads active device states and updates wifiConnected/activeConnection
    Process {
        id: activeConnectionProc

        command:["nmcli","-t","-f","DEVICE,TYPE,STATE,CONNECTION","dev"]

        stdout: StdioCollector {

            onStreamFinished: {

                const lines = text.trim().split("\n");

                root.wifiConnected = false;
                root.activeConnection = "";

                lines.forEach(line=>{

                    const parts = line.split(":");

                    if(parts.length < 4)
                        return;

                    const type = parts[1];
                    const state = parts[2];
                    const connection = parts[3];

                    if(type === "wifi" &&
                    state.startsWith("connected"))
                    {
                        root.wifiConnected = true;
                        root.activeConnection = connection;
                    }

                });
            }
        }
    }

    // Detect Wifi Interface
    Process {
        id: findInterfaceProc
        command: ["nmcli", "-g", "DEVICE,TYPE", "device"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const lines = data.trim().split("\n");
                lines.forEach(line => {
                    const parts = line.split(":");
                    if (parts.length >= 2 && parts[1] === "wifi") {
                        root.wifiInterface = parts[0];
                        activeConnectionProc.running = true;
                    }
                });
            }
        }
    }

    // Status Monitor (Enabled/Disabled)
    Process {
        id: statusProc
        command: ["nmcli", "radio", "wifi"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.wifiEnabled = (data.trim() === "enabled");

                if (root.wifiEnabled) {
                    getSavedProc.running = true;
                    Qt.callLater(() => {
                        rescanProc.running = true;
                        getNetworksProc.running = true;
                    });
                }
            }
        }
    }

    // Toggle On/Off
    Process {
        id: toggleWifiProc
        onExited: statusProc.running = true
    }

    // Rescan (Refresh)
    Process {
        id: rescanProc
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        onExited: {
            getNetworksProc.running = true;
            activeConnectionProc.running = true;
            connectivityProc.running = true;
        }
    }

    // Disconnect
    Process {
        id: disconnectProc
        onExited:{
            getNetworksProc.running = true;
            activeConnectionProc.running = true;
        }
    }

    // Forget Network
    Process {
        id: forgetProc
        // The command is defined dynamically before running
        onExited: {
            getSavedProc.running = true;
            getNetworksProc.running = true;
        }
    }

    // Automatic Update Timer
    Timer {
        interval: 30000
        running: root.wifiEnabled
        repeat: true
        onTriggered: {
            getSavedProc.running = true;
            getNetworksProc.running = true;
        }
    }

    // List Saved Networks
    Process {
        id: getSavedProc
        command: ["nmcli", "-g", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                var savedList = [];
                lines.forEach(line => {
                    const parts = line.split(":");
                    if (parts.length >= 2 && parts[1] === "802-11-wireless") {
                        savedList.push(parts[0]);
                    }
                });
                root.savedSsids = savedList;
            }
        }
    }

    // List Available Networks (Scan)
    Process {
        id: getNetworksProc
        command: ["nmcli","-t","-f","IN-USE,SIGNAL,SSID,SECURITY,BSSID,CHAN,RATE","dev","wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const seen = new Map();

                lines.forEach(line => {
                    if (line.length < 5)
                        return;
                    const parts = line.split(":", 7);
                    if (parts.length < 7)
                        return;

                    const inUse = parts[0] === "*";
                    const signal = parseInt(parts[1]) || 0;
                    const ssid = parts[2];
                    const security = parts[3];
                    const bssid = parts[4];
                    const channel = parts[5];
                    const rate = parts[6];

                    if (!ssid)
                        return;

                    const isSaved = root.savedSsids.includes(ssid);

                    if (!seen.has(ssid) || seen.get(ssid).signal < signal){

                        seen.set(ssid,{
                            ssid:ssid,
                            signal:signal,
                            active:inUse,
                            secure:security.length > 0,
                            securityType: security || "Open",
                            saved:isSaved,
                            bssid:bssid,
                            channel:channel,
                            rate:rate
                        });

                    }
                });

                let list = Array.from(seen.values());

                list.sort((a,b)=>{
                    if(a.ssid === connectingSsid)
                        return -1;

                    if(b.ssid === connectingSsid)
                        return 1;

                    if(a.ssid === activeConnection)
                        return -1;

                    if(b.ssid === activeConnection)
                        return 1;

                    if(a.saved && !b.saved)
                        return -1;

                    if(!a.saved && b.saved)
                        return 1;

                    return b.signal - a.signal;
                });
                root.accessPoints = list;
            }
        }
    }
}

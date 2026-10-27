pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool sharing: false
    property int elapsedSeconds: 0
    property string appName: ""

    readonly property string statusText: "Sharing " + formatElapsed()

    function formatElapsed(): string {
        const minutes = Math.floor(root.elapsedSeconds / 60);
        const seconds = root.elapsedSeconds % 60;
        const minuteText = minutes < 10 ? "0" + minutes : String(minutes);
        const secondText = seconds < 10 ? "0" + seconds : String(seconds);
        return minuteText + ":" + secondText;
    }

    function refresh() {
        if (!dumpProc.running)
            dumpProc.running = true;
    }

    function stop() {
        if (stopProc.running)
            return;

        stopProc.running = true;
    }

    function propsFor(object) {
        if (!object)
            return {};

        if (object.info && object.info.props)
            return object.info.props;

        return object.props || {};
    }

    function lower(value): string {
        return String(value || "").toLowerCase();
    }

    function propsText(props): string {
        let text = "";
        for (const key in props)
            text += " " + key + "=" + props[key];

        return text.toLowerCase();
    }

    function isCameraNode(props): bool {
        const role = lower(props["media.role"]);
        const api = lower(props["device.api"]);
        const factory = lower(props["factory.name"]);
        const objectPath = lower(props["object.path"]);
        const target = lower(props["target.object"]);

        return role === "camera"
            || api === "v4l2"
            || factory.indexOf("v4l2") !== -1
            || objectPath.indexOf("v4l2:") === 0
            || target.indexOf("v4l2") !== -1
            || target.indexOf("/dev/video") !== -1;
    }

    function isScreenShareNode(props, clientProps): bool {
        const mediaClass = lower(props["media.class"]);
        if (mediaClass.indexOf("video") === -1 || isCameraNode(props))
            return false;

        const text = propsText(props) + propsText(clientProps);
        const role = lower(props["media.role"]);
        const portalOwned = text.indexOf("xdg-desktop-portal") !== -1
            || text.indexOf("hyprland") !== -1
            || text.indexOf("xdpw") !== -1;
        const screenNamed = text.indexOf("screencast") !== -1
            || text.indexOf("screen-cast") !== -1
            || text.indexOf("screen cast") !== -1
            || text.indexOf("screenshare") !== -1
            || text.indexOf("screen share") !== -1
            || text.indexOf("screen_capture") !== -1
            || text.indexOf("desktop") !== -1
            || role.indexOf("screen") !== -1
            || role.indexOf("desktop") !== -1;

        return portalOwned || screenNamed;
    }

    function shareLabel(props, clientProps): string {
        return props["application.name"]
            || clientProps["application.name"]
            || props["node.description"]
            || props["media.name"]
            || "Screen";
    }

    function setSharing(active: bool, label: string) {
        if (active && !root.sharing) {
            root.elapsedSeconds = 0;
            elapsedTimer.restart();
        } else if (!active && root.sharing) {
            elapsedTimer.stop();
            root.elapsedSeconds = 0;
        }

        root.appName = active ? label : "";
        root.sharing = active;
    }

    function updateFromDump(text: string) {
        let objects = [];
        try {
            objects = JSON.parse(text);
        } catch (error) {
            console.warn("[ScreenShareService] Failed to parse pw-dump output: " + error);
            return;
        }

        const clients = {};
        for (let i = 0; i < objects.length; i++) {
            const object = objects[i];
            if (object.type === "PipeWire:Interface:Client")
                clients[String(object.id)] = propsFor(object);
        }

        for (let i = 0; i < objects.length; i++) {
            const object = objects[i];
            if (object.type !== "PipeWire:Interface:Node")
                continue;

            const props = propsFor(object);
            const clientProps = clients[String(props["client.id"])] || {};
            if (isScreenShareNode(props, clientProps)) {
                setSharing(true, shareLabel(props, clientProps));
                return;
            }
        }

        setSharing(false, "");
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: elapsedTimer
        interval: 1000
        running: root.sharing
        repeat: true
        onTriggered: root.elapsedSeconds += 1
    }

    Process {
        id: dumpProc
        command: ["pw-dump"]

        stdout: StdioCollector {
            onStreamFinished: root.updateFromDump(text)
        }
    }

    Process {
        id: stopProc
        command: ["bash", "-c", `
            set -u
            closed=0

            while IFS= read -r session_path; do
                [ -n "$session_path" ] || continue
                if busctl --user call org.freedesktop.portal.Desktop "$session_path" org.freedesktop.portal.Session Close >/dev/null 2>&1; then
                    closed=1
                fi
            done <<EOF
$(busctl --user tree org.freedesktop.portal.Desktop 2>/dev/null | awk '/\\/org\\/freedesktop\\/portal\\/desktop\\/session\\// { print $NF }')
EOF

            if [ "$closed" -eq 0 ]; then
                systemctl --user restart xdg-desktop-portal-hyprland.service xdg-desktop-portal.service >/dev/null 2>&1 || {
                    pkill -TERM -x xdg-desktop-portal-hyprland 2>/dev/null || true
                    pkill -TERM -x xdg-desktop-portal 2>/dev/null || true
                }
            fi
        `]

        onExited: root.refresh()
    }
}

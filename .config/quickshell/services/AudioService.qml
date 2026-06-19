pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property string brightnessctlPath: "/usr/sbin/brightnessctl"

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    property var selectedSink: null
    property var selectedSource: null
    readonly property var effectiveSink: selectedSink ?? sink
    readonly property var effectiveSource: selectedSource ?? source
    readonly property var outputDevices: Pipewire.nodes.values.filter(node => isAudioDevice(node, true))
    readonly property var inputDevices: Pipewire.nodes.values.filter(node => isAudioDevice(node, false))
    property var outputStreams: []
    property var pactlSinks: []
    property var streamRoutes: ({})
    property bool streamPollingEnabled: false

    // Keeps the objects alive in memory
    PwObjectTracker {
        objects: [root.sink, root.source, root.selectedSink, root.selectedSource]
    }

    Connections {
        target: Pipewire

        function onDefaultAudioSinkChanged() {
            root.selectedSink = null;
        }

        function onDefaultAudioSourceChanged() {
            root.selectedSource = null;
        }
    }

    // Check if the sink is ready to operate
    readonly property bool sinkReady: effectiveSink !== null && effectiveSink.audio !== null
    readonly property bool sourceReady: effectiveSource !== null && effectiveSource.audio !== null

    readonly property bool muted: sinkReady ? (effectiveSink.audio.muted ?? false) : false
    readonly property real volume: {
        if (!sinkReady)
            return 0;
        const vol = effectiveSink.audio.volume;
        return Math.max(0, Math.min(1, vol));
    }
    readonly property int percentage: Math.round(volume * 100)

    readonly property bool sourceMuted: sourceReady ? (effectiveSource.audio.muted ?? false) : false
    readonly property real sourceVolume: {
        if (!sourceReady)
            return 0;
        const vol = effectiveSource.audio.volume;
        return Math.max(0, Math.min(1, vol));
    }
    readonly property int sourcePercentage: Math.round(sourceVolume * 100)

    readonly property string outputName: audioDeviceName(effectiveSink)
    readonly property string inputName: audioDeviceName(effectiveSource)
    readonly property string statusText: outputName + " · " + percentage + "%"

    readonly property string systemIcon: {
        if (!sinkReady || muted || volume <= 0)
            return "";

        if (volume < 0.33)
            return "";

        if (volume < 0.67)
            return "";

        return "";
    }

    function setVolume(newVolume) {
        if (sinkReady) {
            effectiveSink.audio.muted = false;
            effectiveSink.audio.volume = Math.max(0, Math.min(1, newVolume));
            updateSinkMuteLed(false);
        }
    }

    function toggleMute() {
        if (sinkReady) {
            effectiveSink.audio.muted = !effectiveSink.audio.muted;
            updateSinkMuteLed(effectiveSink.audio.muted);
            return effectiveSink.audio.muted;
        }
        return muted;
    }

    function increaseVolume() {
        setVolume(volume + 0.05);
    }

    function decreaseVolume() {
        setVolume(volume - 0.05);
    }

    function setSourceVolume(newVolume) {
        if (sourceReady && effectiveSource.audio) {
            effectiveSource.audio.muted = false;
            effectiveSource.audio.volume = Math.max(0, Math.min(1.5, newVolume));
            updateSourceMuteLed(false);
        }
    }

    function toggleSourceMute() {
        if (sourceReady && effectiveSource.audio) {
            effectiveSource.audio.muted = !effectiveSource.audio.muted;
            updateSourceMuteLed(effectiveSource.audio.muted);
            return effectiveSource.audio.muted;
        }
        return sourceMuted;
    }

    function isAudioDevice(node, wantSink) {
        if (!node || !node.audio || node.isStream || node.isSink !== wantSink)
            return false;

        const name = node.name || "";
        const description = node.description || "";
        return name.indexOf(".monitor") === -1 && description.indexOf("Monitor of ") !== 0;
    }

    function audioDeviceName(device) {
        if (!device)
            return "Unavailable";

        return device.nickname || device.description || device.name || "Audio device";
    }

    function audioDeviceSubName(device) {
        return device?.name ?? "";
    }

    function appName(stream) {
        if (!stream)
            return "Application";

        const props = stream.properties || {};
        return props["application.name"] || props["media.name"] || stream.name || "Application";
    }

    function streamRouteLabel(stream) {
        if (!stream)
            return "Choose device";

        const routedName = root.streamRoutes[String(stream.index)];
        if (routedName)
            return routedName;

        if (stream.device === null || stream.device === undefined)
            return "Choose device";

        const routeDevice = streamRouteDevice(stream);
        if (routeDevice)
            return audioDeviceName(routeDevice);

        const pactlSink = pactlSinkByIndex(stream.device);
        if (pactlSink)
            return pactlSink.description || pactlSink.name || "Output";

        return "Current route " + stream.device;
    }

    function streamRouteMatches(stream, device) {
        if (!stream || !device)
            return false;

        const routedName = root.streamRoutes[String(stream.index)];
        if (routedName)
            return routedName === audioDeviceName(device);

        return nodeMatches(streamRouteDevice(stream), device);
    }

    function streamRouteDevice(stream) {
        if (!stream || stream.device === null || stream.device === undefined)
            return null;

        const pactlSink = pactlSinkByIndex(stream.device);
        return pactlSink ? outputDeviceByName(pactlSink.name) : null;
    }

    function pactlSinkByIndex(index) {
        const numericIndex = Number(index);
        for (let i = 0; i < root.pactlSinks.length; i++) {
            if (root.pactlSinks[i].index === numericIndex)
                return root.pactlSinks[i];
        }

        return null;
    }

    function outputDeviceByName(name) {
        for (let i = 0; i < root.outputDevices.length; i++) {
            if (root.outputDevices[i].name === name)
                return root.outputDevices[i];
        }

        return null;
    }

    function nodeMatches(a, b) {
        return !!(a && b && a.id === b.id);
    }

    function setDefaultSink(node) {
        if (node) {
            root.selectedSink = node;
            Pipewire.preferredDefaultAudioSink = node;
            setDefaultSinkProc.command = ["pactl", "set-default-sink", node.name];
            setDefaultSinkProc.running = true;

            moveAllOutputStreams(node);
        }
    }

    function setDefaultSource(node) {
        if (node) {
            root.selectedSource = node;
            Pipewire.preferredDefaultAudioSource = node;
            setDefaultSourceProc.command = ["pactl", "set-default-source", node.name];
            setDefaultSourceProc.running = true;
        }
    }

    function setNodeVolume(node, value) {
        if (node?.audio) {
            node.audio.muted = false;
            node.audio.volume = Math.max(0, Math.min(1.5, value));
        }
    }

    function toggleNodeMute(node) {
        if (node?.audio)
            node.audio.muted = !node.audio.muted;
    }

    function refreshStreams() {
        if (!root.streamPollingEnabled)
            return;

        if (!sinksProc.running)
            sinksProc.running = true;
        if (!sinkInputsProc.running)
            sinkInputsProc.running = true;
    }

    function moveOutputStream(stream, device) {
        if (!stream || !device)
            return;

        moveOutputStreamProc.command = ["pactl", "move-sink-input", String(stream.index), device.name];
        moveOutputStreamProc.running = true;
        setStreamRouteLabel(stream, device);
    }

    function moveAllOutputStreams(device) {
        if (!device || root.outputStreams.length === 0)
            return;

        const commands = [];
        for (let i = 0; i < root.outputStreams.length; i++) {
            commands.push("pactl move-sink-input " + shellEscape(String(root.outputStreams[i].index)) + " " + shellEscape(device.name));
        }

        moveAllOutputStreamsProc.command = ["bash", "-c", commands.join("; ")];
        moveAllOutputStreamsProc.running = true;
    }

    function shellEscape(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function setStreamRouteLabel(stream, device) {
        if (!stream || !device)
            return;

        const routes = Object.assign({}, root.streamRoutes);
        routes[String(stream.index)] = audioDeviceName(device);
        root.streamRoutes = routes;
    }

    function setStreamVolume(stream, value) {
        if (!stream)
            return;

        const percent = Math.round(Math.max(0, Math.min(1.5, value)) * 100) + "%";
        streamVolumeProc.command = ["pactl", "set-sink-input-volume", String(stream.index), percent];
        streamVolumeProc.running = true;
    }

    function toggleStreamMute(stream) {
        if (!stream)
            return;

        streamMuteProc.command = ["pactl", "set-sink-input-mute", String(stream.index), "toggle"];
        streamMuteProc.running = true;
    }

    function parsePactlStreams(text) {
        if (!text || text.trim() === "")
            return [];

        try {
            const parsed = JSON.parse(text);
            return Array.isArray(parsed) ? parsed.map(normalizeStream) : [];
        } catch (error) {
            console.warn("[AudioService] Failed to parse pactl stream list:", error);
            return [];
        }
    }

    function parsePactlSinks(text) {
        if (!text || text.trim() === "")
            return [];

        try {
            const parsed = JSON.parse(text);
            if (!Array.isArray(parsed))
                return [];

            return parsed.map(sink => ({
                index: Number(sink.index ?? -1),
                name: sink.name || "",
                description: sink.description || sink.name || ""
            }));
        } catch (error) {
            console.warn("[AudioService] Failed to parse pactl sink list:", error);
            return [];
        }
    }

    function normalizeStream(stream) {
        const props = stream.properties || {};
        return {
            index: stream.index ?? 0,
            name: stream.name || props["application.name"] || props["media.name"] || "Application",
            properties: props,
            device: stream.sink ?? stream.source ?? null,
            volume: streamVolume(stream),
            muted: stream.mute ?? false
        };
    }

    function streamVolume(stream) {
        const volume = stream.volume;
        if (!volume)
            return 0;

        const channels = Object.keys(volume);
        if (channels.length === 0)
            return 0;

        const first = volume[channels[0]];
        if (typeof first === "number")
            return Math.max(0, first / 65536);
        if (typeof first === "string")
            return (parseInt(first.replace("%", "")) || 0) / 100;
        if (first && typeof first.value_percent === "string")
            return (parseInt(first.value_percent.replace("%", "")) || 0) / 100;

        return 0;
    }

    function updateSinkMuteLed(isMuted: bool) {
        sinkMuteLedProc.command = [brightnessctlPath, "-d", "platform::mute", "set", isMuted ? "1" : "0", "-q"];
        sinkMuteLedProc.running = true;
    }

    function updateSourceMuteLed(isMuted: bool) {
        sourceMuteLedProc.command = [brightnessctlPath, "-d", "platform::micmute", "set", isMuted ? "1" : "0", "-q"];
        sourceMuteLedProc.running = true;
    }

    Process {
        id: sinkMuteLedProc

        stderr: SplitParser {
            onRead: data => console.error("[AudioService] Failed to set speaker mute LED:", data)
        }
    }

    Process {
        id: sourceMuteLedProc

        stderr: SplitParser {
            onRead: data => console.error("[AudioService] Failed to set microphone mute LED:", data)
        }
    }

    onStreamPollingEnabledChanged: {
        if (streamPollingEnabled)
            refreshStreams();
    }

    Timer {
        interval: 2500
        running: root.streamPollingEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshStreams()
    }

    Timer {
        id: streamRefreshDelay
        interval: 350
        repeat: false
        onTriggered: root.refreshStreams()
    }

    Process {
        id: sinksProc
        command: ["pactl", "-f", "json", "list", "sinks"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.pactlSinks = root.parsePactlSinks(text);
            }
        }

        stderr: SplitParser {
            onRead: data => console.warn("[AudioService] Failed to list outputs:", data)
        }
    }

    Process {
        id: sinkInputsProc
        command: ["pactl", "-f", "json", "list", "sink-inputs"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.outputStreams = root.parsePactlStreams(text);
            }
        }

        stderr: SplitParser {
            onRead: data => console.warn("[AudioService] Failed to list playback streams:", data)
        }
    }

    Process {
        id: moveOutputStreamProc
        onExited: {
            streamRefreshDelay.restart();
        }

        stderr: SplitParser {
            onRead: data => console.warn("[AudioService] Failed to move playback stream:", data)
        }
    }

    Process {
        id: moveAllOutputStreamsProc
        onExited: {
            streamRefreshDelay.restart();
        }

        stderr: SplitParser {
            onRead: data => console.warn("[AudioService] Failed to move playback streams:", data)
        }
    }

    Process {
        id: setDefaultSinkProc
        onExited: {
            streamRefreshDelay.restart();
        }

        stderr: SplitParser {
            onRead: data => console.warn("[AudioService] Failed to set default output:", data)
        }
    }

    Process {
        id: setDefaultSourceProc

        stderr: SplitParser {
            onRead: data => console.warn("[AudioService] Failed to set default input:", data)
        }
    }

    Process {
        id: streamVolumeProc
        onExited: {
            streamRefreshDelay.restart();
        }
    }

    Process {
        id: streamMuteProc
        onExited: {
            streamRefreshDelay.restart();
        }
    }
}

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

    // Keeps the objects alive in memory
    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    // Check if the sink is ready to operate
    readonly property bool sinkReady: sink !== null && sink.audio !== null
    readonly property bool sourceReady: source !== null && source.audio !== null

    readonly property bool muted: sinkReady ? (sink.audio.muted ?? false) : false
    readonly property real volume: {
        if (!sinkReady)
            return 0;
        const vol = sink.audio.volume;
        return Math.max(0, Math.min(1, vol));
    }
    readonly property int percentage: Math.round(volume * 100)

    readonly property bool sourceMuted: sourceReady ? (source.audio.muted ?? false) : false
    readonly property real sourceVolume: {
        if (!sourceReady)
            return 0;
        const vol = source.audio.volume;
        return Math.max(0, Math.min(1, vol));
    }
    readonly property int sourcePercentage: Math.round(sourceVolume * 100)

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
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, newVolume));
            updateSinkMuteLed(false);
        }
    }

    function toggleMute() {
        if (sinkReady) {
            sink.audio.muted = !sink.audio.muted;
            updateSinkMuteLed(sink.audio.muted);
            return sink.audio.muted;
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
        if (sourceReady && source.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(1.5, newVolume));
            updateSourceMuteLed(false);
        }
    }

    function toggleSourceMute() {
        if (sourceReady && source.audio) {
            source.audio.muted = !source.audio.muted;
            updateSourceMuteLed(source.audio.muted);
            return source.audio.muted;
        }
        return sourceMuted;
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
}

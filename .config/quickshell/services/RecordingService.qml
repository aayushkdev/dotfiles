pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool recording: false
    property int elapsedSeconds: 0
    property string outputPath: ""
    property string recorderPid: ""

    function shellEscape(value: string): string {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function formatElapsed(): string {
        const minutes = Math.floor(root.elapsedSeconds / 60);
        const seconds = root.elapsedSeconds % 60;
        const minuteText = minutes < 10 ? "0" + minutes : String(minutes);
        const secondText = seconds < 10 ? "0" + seconds : String(seconds);
        return minuteText + ":" + secondText;
    }

    function startGeometry(geometry: string) {
        const videosDir = Quickshell.env("XDG_VIDEOS_DIR") || (Quickshell.env("HOME") + "/Videos");
        const recordingsDir = videosDir + "/Recordings";
        const timestamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss");
        const path = recordingsDir + "/recording-" + timestamp + ".mp4";

        root.outputPath = path;
        root.elapsedSeconds = 0;
        root.recorderPid = "";
        root.recording = true;

        const cmd = recordingCommand(
            "wf-recorder -g " + shellEscape(geometry) + " -f " + shellEscape(path),
            recordingsDir,
            path
        );

        recorder.command = ["bash", "-c", cmd];
        recorder.running = true;
        elapsedTimer.restart();
    }

    function startOutput(output: string) {
        const videosDir = Quickshell.env("XDG_VIDEOS_DIR") || (Quickshell.env("HOME") + "/Videos");
        const recordingsDir = videosDir + "/Recordings";
        const timestamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss");
        const path = recordingsDir + "/recording-" + timestamp + ".mp4";

        root.outputPath = path;
        root.elapsedSeconds = 0;
        root.recorderPid = "";
        root.recording = true;

        const cmd = recordingCommand(
            "wf-recorder -o " + shellEscape(output) + " -f " + shellEscape(path),
            recordingsDir,
            path
        );

        recorder.command = ["bash", "-c", cmd];
        recorder.running = true;
        elapsedTimer.restart();
    }

    function stop() {
        if (!root.recording)
            return;

        if (root.recorderPid !== "") {
            stopProc.command = ["bash", "-c", "kill -INT " + root.recorderPid + " 2>/dev/null || true"];
            stopProc.running = true;
        } else {
            recorder.running = false;
        }
    }

    function recordingCommand(recordCommand: string, recordingsDir: string, path: string): string {
        const quotedDir = shellEscape(recordingsDir);
        const quotedPath = shellEscape(path);
        const savedMessage = shellEscape("Path: " + path);
        return "mkdir -p " + quotedDir
            + " || exit 1; "
            + "command -v wf-recorder >/dev/null 2>&1 || { notify-send -i dialog-error -a Recorder 'Recording Failed' 'wf-recorder is not installed'; exit 127; }; "
            + "(sleep 0.2; exec " + recordCommand + ") & echo $!; wait $!; "
            + "if [ -s " + quotedPath + " ]; then "
            + "notify-send -i media-record -a Recorder 'Recording Saved' " + savedMessage + "; "
            + "else "
            + "notify-send -i dialog-error -a Recorder 'Recording Failed' 'No recording file was created'; "
            + "fi";
    }

    Timer {
        id: elapsedTimer
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.elapsedSeconds += 1
    }

    Process {
        id: recorder

        stdout: SplitParser {
            onRead: data => {
                const pid = String(data).trim();
                if (pid.match(/^[0-9]+$/))
                    root.recorderPid = pid;
            }
        }

        onExited: {
            root.recording = false;
            root.recorderPid = "";
            elapsedTimer.stop();
        }
    }

    Process {
        id: stopProc
    }
}

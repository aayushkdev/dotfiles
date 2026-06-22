//@ pragma Env QS_NO_RELOAD_POPUP=1
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import "./modules/bar/"
import "./modules/capture/"

ShellRoot {
    id: root

    // =========================================================================
    // GLOBAL MODULE STATE
    // =========================================================================

    property bool captureActive: false
    property string captureType: "screenshot"

    // =========================================================================
    // BLUETOOTH AGENT
    // =========================================================================

    readonly property string bluetoothAgentScriptPath: Qt.resolvedUrl("./scripts/bluetooth-agent.py").toString().replace("file://", "")

    Process {
        id: bluetoothAgent
        command: ["python3", root.bluetoothAgentScriptPath]
        running: true

        stdout: SplitParser {
            onRead: data => console.log("[BluetoothAgent]: " + data)
        }
        stderr: SplitParser {
            onRead: data => console.error("[BluetoothAgent]: " + data)
        }
    }

    // =========================================================================
    // UI COMPONENTS - LAZY LOADING
    // =========================================================================

    // Bar - always active (main component)
    Bar {}

    // Notifications
    Loader {
        id: notificationLoader
        active: NotificationService.activePopupCount > 0 || NotificationService.popups.length > 0
        source: "./modules/notifications/NotificationOverlay.qml"

        onStatusChanged: {
            if (status === Loader.Ready)
                console.log("[Shell] NotificationOverlay loaded");
        }
    }

    // Power Overlay
    Loader {
        id: powerLoader
        active: PowerService.overlayVisible
        source: "./modules/power/PowerOverlay.qml"

        onStatusChanged: {
            if (status === Loader.Ready)
                console.log("[Shell] PowerOverlay loaded");
        }
    }

    // Capture Manager
    Loader {
        id: captureLoader
        active: root.captureActive
        source: "./modules/capture/CaptureManager.qml"

        onStatusChanged: {
            if (status === Loader.Ready) {
                console.log("[Shell] CaptureManager loaded");
                captureLoader.item.startCapture(root.captureType);
            }
        }

        // Deactivate when capture finishes
        Connections {
            target: captureLoader.item
            enabled: captureLoader.status === Loader.Ready

            function onActiveChanged() {
                if (captureLoader.item && !captureLoader.item.active) {
                    root.captureActive = false;
                }
            }
        }
    }

    // Launcher
    Loader {
        active: LauncherService.visible
        source: "./modules/launcher/Launcher.qml"
    }

    // OSD
    Loader {
        active: OsdService.visible
        source: "./modules/osd/OsdOverlay.qml"
    }

    // Wallpaper Picker
    Loader {
        active: WallpaperService.pickerVisible
        source: "./modules/wallpaper/WallpaperPicker.qml"
    }

    // Clipboard History
    Loader {
        active: ClipboardService.visible
        source: "./modules/clipboard/ClipboardHistory.qml"
    }

    // =========================================================================
    // GLOBAL SHORTCUTS
    // =========================================================================

    // Shortcut: Screenshot (Print)
    GlobalShortcut {
        name: "take_screenshot"
        description: "Screenshot capture"

        onPressed: {
            console.log("[Shell] Screenshot requested");
            root.captureType = "screenshot";
            root.captureActive = false;
            root.captureActive = true;
        }
    }

    // Shortcut: Power Menu
    GlobalShortcut {
        name: "power_menu"
        description: "Power menu"

        onPressed: {
            console.log("[Shell] Power menu requested");
            PowerService.showOverlay();
        }
    }

    // Shortcut: Launcher
    GlobalShortcut {
        name: "app_launcher"
        description: "App Launcher"

        onPressed: LauncherService.show()
    }

    // Shortcut: Volume Up
    GlobalShortcut {
        name: "volume_up"
        description: "Increase volume"

        onPressed: {
            AudioService.increaseVolume();
            OsdService.showVolume(AudioService.volume, AudioService.muted);
        }
    }

    // Shortcut: Volume Down
    GlobalShortcut {
        name: "volume_down"
        description: "Decrease volume"

        onPressed: {
            AudioService.decreaseVolume();
            OsdService.showVolume(AudioService.volume, AudioService.muted);
        }
    }

    // Shortcut: Volume Mute
    GlobalShortcut {
        name: "volume_mute"
        description: "Mute volume"

        onPressed: {
            const muted = AudioService.toggleMute();
            OsdService.showVolume(AudioService.volume, muted);
        }
    }

    // Shortcut: Microphone Mute
    GlobalShortcut {
        name: "mic_mute"
        description: "Mute microphone"

        onPressed: {
            const muted = AudioService.toggleSourceMute();
            OsdService.showMicrophone(AudioService.sourceVolume, muted);
        }
    }

    // Shortcut: Brightness Up
    GlobalShortcut {
        name: "brightness_up"
        description: "Increase brightness"

        onPressed: {
            BrightnessService.increaseBrightness();
            OsdService.showBrightness(BrightnessService.brightness);
        }
    }

    // Shortcut: Brightness Down
    GlobalShortcut {
        name: "brightness_down"
        description: "Decrease brightness"

        onPressed: {
            BrightnessService.decreaseBrightness();
            OsdService.showBrightness(BrightnessService.brightness);
        }
    }

    // Shortcut: Wallpaper Picker
    GlobalShortcut {
        name: "wallpaper_picker"
        description: "Wallpaper picker"

        onPressed: WallpaperService.toggle()
    }

    // Shortcut: Clipboard History
    GlobalShortcut {
        name: "clipboard_history"
        description: "Clipboard history"

        onPressed: ClipboardService.toggle()
    }

    // Shortcut: Idle Inhibit
    GlobalShortcut {
        name: "idle_inhibit"
        description: "Toggle idle inhibit"

        onPressed: IdleInhibitService.toggle()
    }
}

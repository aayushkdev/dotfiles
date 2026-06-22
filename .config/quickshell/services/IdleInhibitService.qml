pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    property bool enabled: false

    function toggle() {
        enabled = !enabled;
        OsdService.showIdleInhibit(enabled);
    }
}

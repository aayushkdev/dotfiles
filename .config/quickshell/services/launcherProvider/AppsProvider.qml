pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

QtObject {

    readonly property string id: "apps"
    readonly property string name: "Applications"
    readonly property string prefix: "a"

    function search(query) {

        let apps = DesktopEntries.applications.values;

        apps = apps.slice().sort((a,b)=>
            (a.name||"").localeCompare(b.name||"")
        );

        if (!query)
            return apps.slice(0, 50);

        query = query.toLowerCase();

        return apps.filter(app =>
            app.name.toLowerCase().includes(query) ||
            (app.comment||"").toLowerCase().includes(query)
        ).slice(0, 50);
    }

    function activate(app) {

        let cmd = app.execString
            .replace(/%[uUfFdDnNickvm]/g,"")
            .trim();

        Quickshell.execDetached(["sh","-c",cmd]);

        LauncherService.hide();
    }

}
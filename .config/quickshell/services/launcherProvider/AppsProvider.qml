pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

QtObject {

    readonly property string id: "apps"
    readonly property string name: "Applications"
    readonly property string prefix: "a"
    readonly property bool showGlobally: true
    readonly property bool showWhenPrefixEmpty: true

    function _normalize(text) {
        return (text || "").toLowerCase();
    }

    function _acronym(text) {
        return (text || "")
            .split(/[\s._-]+/)
            .filter(part => part.length > 0)
            .map(part => part[0])
            .join("")
            .toLowerCase();
    }

    function _score(app, query) {
        const name = _normalize(app.name);
        const genericName = _normalize(app.genericName);
        const comment = _normalize(app.comment);
        const exec = _normalize(app.execString);
        const acronym = _acronym(app.name);

        if (name === query)
            return 0;
        if (name.startsWith(query))
            return 1;
        if (acronym.startsWith(query))
            return 2;
        if (name.split(/[\s._-]+/).some(part => part.startsWith(query)))
            return 3;
        if (genericName.startsWith(query))
            return 4;
        if (name.includes(query))
            return 5;
        if (genericName.includes(query))
            return 6;
        if (comment.includes(query))
            return 7;
        if (exec.includes(query))
            return 8;

        return -1;
    }

    function search(query) {

        let apps = DesktopEntries.applications.values;

        apps = apps.slice().sort((a,b)=>
            (a.name||"").localeCompare(b.name||"")
        );

        if (!query)
            return apps.slice(0, 50);

        query = query.toLowerCase();

        return apps
            .map(app => ({ app: app, score: _score(app, query) }))
            .filter(result => result.score >= 0)
            .sort((a, b) => {
                if (a.score !== b.score)
                    return a.score - b.score;
                return (a.app.name || "").localeCompare(b.app.name || "");
            })
            .map(result => result.app)
            .slice(0, 50);
    }

    function activate(app) {

        let cmd = app.execString
            .replace(/%[uUfFdDnNickvm]/g,"")
            .trim();

        Quickshell.execDetached(["sh","-c",cmd]);

        LauncherService.hide();
    }

}

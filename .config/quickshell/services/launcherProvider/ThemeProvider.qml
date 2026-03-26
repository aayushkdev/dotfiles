pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import qs.services

QtObject {

    readonly property string id: "themes"
    readonly property string name: "Themes"
    readonly property string prefix: "t"
    readonly property bool showGlobally: true
    readonly property bool showWhenPrefixEmpty: true

    function search(query) {

        let themes = ThemeService.displayThemes;

        if (!query)
            return themes;

        query = query.toLowerCase();

        return themes.filter(t =>
            t.toLowerCase().includes(query)
        );
    }

    function activate(theme) {

        ThemeService.setPresetMode(theme);
        LauncherService.hide();

    }

}
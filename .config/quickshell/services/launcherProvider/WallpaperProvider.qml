pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import qs.services

QtObject {

    readonly property string id: "wallpapers"
    readonly property string name: "Wallpapers"
    readonly property string prefix: "w"

    // ============================================================
    // SEARCH
    // ============================================================

    function search(query) {

        let list = WallpaperService.wallpapers || []

        if (query)
            query = query.toLowerCase()

        return list
            .filter(path => {

                if (!query)
                    return true

                return WallpaperService.fileName(path)
                    .toLowerCase()
                    .includes(query)
            })
            .map(path => ({
                name: WallpaperService.fileName(path), 
                icon: path,                            
                path: path                             
            }))
    }

    // ============================================================
    // ACTIVATE
    // ============================================================

    function activate(item) {

        if (!item || !item.path)
            return

        WallpaperService.setWallpaper(item.path)
        LauncherService.hide()
    }

}
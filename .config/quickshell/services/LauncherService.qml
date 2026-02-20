pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import "./launcherProvider/"

Singleton {

    id: root

    // =====================================================================
    // VISIBILITY
    // =====================================================================

    property bool visible: false

    function show() {
        _refreshToken++
        query = ""
        selectedIndex = 0
        _activeProvider = null
        visible = true
    }

    function hide() {
        visible = false
        query = ""
        selectedIndex = 0
        _activeProvider = null
    }

    function toggle() {
        visible ? hide() : show()
    }

    // Show specific provider (example: themes)
    function showProvider(providerId) {

        for (let p of providers) {
            if (p.id === providerId) {
                _activeProvider = p
                query = ""
                selectedIndex = 0
                visible = true
                _refreshToken++
                return
            }
        }

        console.warn("[Launcher] Provider not found:", providerId)
    }

    // =====================================================================
    // QUERY STATE
    // =====================================================================

    property string query: ""
    property int selectedIndex: 0
    property int maxItems: 50

    property int _refreshToken: 0

    property var _activeProvider: null

    // =====================================================================
    // PROVIDERS REGISTRY
    // =====================================================================

    readonly property var providers: [

        AppsProvider,
        ThemeProvider,
        WallpaperProvider


    ]

    // =====================================================================
    // QUERY PARSING
    // =====================================================================

    function _parseQuery() {

        let text = query.trim()

        if (!text)
            return { provider: _activeProvider, query: "" }

        let parts = text.split(/\s+/)

        let prefix = parts[0].toLowerCase()

        for (let p of providers) {

            if (p.prefix === prefix) {

                // IMPORTANT: switch active provider
                _activeProvider = p

                return {
                    provider: p,
                    query: parts.slice(1).join(" ")
                }
            }
        }

        // no prefix → reset provider
        _activeProvider = null

        return {
            provider: null,
            query: text
        }
    }

    // =====================================================================
    // RESULTS
    // =====================================================================

    readonly property var results: {

        void _refreshToken

        let parsed = _parseQuery()

        let provider = parsed.provider
        let q = parsed.query

        if (provider) {

            let res = provider.search(q) || []

            return res.slice(0, maxItems).map(r => ({
                provider: provider,
                data: r
            }))
        }

        // search all providers

        let all = []

        for (let p of providers) {

            let res = p.search(q) || []

            for (let r of res) {

                all.push({
                    provider: p,
                    data: r
                })
            }
        }

        return all.slice(0, maxItems)
    }

    // =====================================================================
    // LAUNCH / ACTIVATE
    // =====================================================================

    function launchSelected() {

        if (selectedIndex < 0 || selectedIndex >= results.length)
            return

        let item = results[selectedIndex]

        if (!item)
            return

        item.provider.activate(item.data)

        hide()
    }

    function launch(entry) {

        // backward compatibility

        if (!entry)
            return

        let cmd = entry.execString
        cmd = cmd.replace(/%[uUfFdDnNickvm]/g, "").trim()
        cmd = cmd.replace(/\s+/g, " ")

        Quickshell.execDetached(["sh", "-c", cmd])

        hide()
    }

    // =====================================================================
    // NAVIGATION
    // =====================================================================

    function navigateUp() {

        if (selectedIndex > 0)
            selectedIndex--
    }

    function navigateDown() {

        if (selectedIndex < results.length - 1)
            selectedIndex++
    }

    onQueryChanged: {

        selectedIndex = 0
        _refreshToken++

        const text = query.trim()

        if (!text) {
            _activeProvider = null
            return
        }

        const parts = text.split(/\s+/)
        const prefix = parts[0].toLowerCase()

        let found = false

        for (let p of providers) {
            if (p.prefix === prefix) {
                found = true
                break
            }
        }

        if (!found)
            _activeProvider = null
    }

}
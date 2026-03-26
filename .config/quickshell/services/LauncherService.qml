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

        query = ""
        selectedIndex = 0
        _activeProvider = null

        visible = true

        _runSearch()
    }

    function hide() {

        visible = false
        query = ""
        selectedIndex = 0
        _activeProvider = null

        _resultsCache = []
    }

    function toggle() {
        visible ? hide() : show()
    }

    function showProvider(providerId) {

        for (let p of providers) {

            if (p.id === providerId) {

                _activeProvider = p
                query = ""
                selectedIndex = 0

                visible = true

                _runSearch()
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

    property var _activeProvider: null

    // =====================================================================
    // RESULTS CACHE (FIXES ASYNC ISSUE)
    // =====================================================================

    property var _resultsCache: []

    readonly property var results: _resultsCache

    // =====================================================================
    // PROVIDERS REGISTRY
    // =====================================================================

    readonly property var providers: [

        AppsProvider,
        ThemeProvider,
        WallpaperProvider,
        FileProvider

    ]

    // =====================================================================
    // QUERY PARSING
    // =====================================================================

    function _parseQuery() {

        const text = query.trim()

        if (!text)
            return { provider: _activeProvider, query: "" }

        const parts = text.split(/\s+/)
        const prefix = parts[0].toLowerCase()

        for (let p of providers) {

            if (p.prefix === prefix) {

                _activeProvider = p

                return {
                    provider: p,
                    query: parts.slice(1).join(" ")
                }
            }
        }

        _activeProvider = null

        return {
            provider: null,
            query: text
        }
    }

    // =====================================================================
    // CORE SEARCH FUNCTION (FIXED)
    // =====================================================================

    function _runSearch() {

        const parsed = _parseQuery()

        const provider = parsed.provider
        const q = parsed.query

        let newResults = []

        if (provider) {

            const res = provider.search(q) || []

            for (let r of res) {

                newResults.push({
                    provider: provider,
                    data: r
                })
            }

        } else {

            for (let p of providers) {

                if (!p.showGlobally)
                    continue

                if (!q && !p.showWhenPrefixEmpty)
                    continue

                const res = p.search(q) || []

                for (let r of res) {

                    newResults.push({
                        provider: p,
                        data: r
                    })
                }
            }
        }

        _resultsCache = newResults.slice(0, maxItems)

        // clamp selection safely

        if (selectedIndex >= _resultsCache.length)
            selectedIndex = _resultsCache.length - 1

        if (selectedIndex < 0)
            selectedIndex = 0
    }

    // =====================================================================
    // REFRESH CALLED BY PROVIDERS
    // =====================================================================

    function refresh() {

        if (!visible)
            return

        _runSearch()
    }

    // =====================================================================
    // LAUNCH / ACTIVATE
    // =====================================================================

    function launchSelected() {

        if (selectedIndex < 0 || selectedIndex >= results.length)
            return

        const item = results[selectedIndex]

        if (!item)
            return

        item.provider.activate(item.data)

        hide()
    }

    function launch(entry) {

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

    // =====================================================================
    // QUERY CHANGE HANDLER
    // =====================================================================

    onQueryChanged: {

        selectedIndex = 0

        const text = query.trim()

        if (!text) {
            _activeProvider = null
        }

        _runSearch()
    }

}
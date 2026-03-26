pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

QtObject {

    readonly property string id: "files"
    property string name: "Files"
    readonly property string prefix: "f"
    readonly property string icon: "folder"

    readonly property bool showGlobally: false
    readonly property bool showWhenPrefixEmpty: false

    property string _currentQuery: ""
    property var _results: []

    // prevents stale async results
    property int _searchToken: 0

    /* =========================
       PUBLIC SEARCH ENTRY
       ========================= */

    function search(query) {

        if (!query) {
            _currentQuery = ""
            _results.length = 0
            return _results
        }

        if (query === _currentQuery)
            return _results

        _currentQuery = query
        _searchToken++

        const token = _searchToken

        _results.length = 0

        if (searchProcess.running)
            searchProcess.running = false

        searchProcess.command = _buildCommand(query)
        searchProcess._token = token
        searchProcess.running = true

        return _results
    }

    /* =========================
       PROCESS
       ========================= */

    property var searchProcess: Process {

        id: searchProcess
        running: false
        property int _token: 0

        stdout: StdioCollector {

            onStreamFinished: {

                if (searchProcess._token !== _searchToken)
                    return

                const output = text.trim()

                if (!output) {
                    LauncherService.refresh()
                    return
                }

                const items = _parseOutput(output, _currentQuery)
                _applyResults(items)
            }
        }
    }

    /* =========================
       PARSING + RANKING
       ========================= */

    function _parseOutput(output, query) {

        const lines = output.split("\n")
        const q = query.toLowerCase()

        let items = []

        for (let path of lines) {

            if (!path)
                continue

            const isDir = path.endsWith("/")
            const cleanPath = isDir ? path.slice(0, -1) : path
            const name = cleanPath.split("/").pop()

            items.push({
                name: name,
                path: cleanPath,
                isDirectory: isDir,
                icon: isDir ? "folder" : _iconForFile(cleanPath),
                _score: _score(name, q)
            })
        }

        return _sortResults(items)
    }

    function _score(name, q) {

        const lower = name.toLowerCase()

        if (lower === q)
            return 0

        if (lower.startsWith(q))
            return 1

        if (lower.includes(q))
            return 2

        return 3
    }

    function _sortResults(items) {

        return items.sort((a, b) => {

            if (a._score !== b._score)
                return a._score - b._score

            if (a.name.length !== b.name.length)
                return a.name.length - b.name.length

            return a.name.localeCompare(b.name)
        })
    }

    function _applyResults(items) {

        _results.length = 0

        for (let item of items)
            _results.push(item)

        LauncherService.refresh()
    }

    /* =========================
       COMMAND BUILDER
       ========================= */

    function _buildCommand(query) {

        return [
            "fd",
            "--max-results", "50",
            "--ignore-case",
            "--absolute-path",
            "--full-path",
            "--regex",
            "(^|/)([^/]*" + _escapeRegex(query) + "[^/]*$)",
            Quickshell.env("HOME"),
            Quickshell.env("HOME") + "/.config"
        ]
    }

    /* =========================
       ACTIVATION
       ========================= */

    function activate(item) {

        if (!item)
            return

        Quickshell.execDetached([
            "xdg-open",
            item.path
        ])

        LauncherService.hide()
    }

    /* =========================
       HELPERS
       ========================= */

    function _escapeRegex(text) {
        return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
    }

    function _iconForFile(path) {

        const name = path.split("/").pop()

        if (!name.includes("."))
            return "text-x-generic"

        const ext = name.split(".").pop().toLowerCase()

        switch (ext) {

        case "png":
        case "jpg":
        case "jpeg":
        case "webp":
        case "gif":
            return "image-x-generic"

        case "pdf":
            return "application-pdf"

        case "mp4":
        case "mkv":
        case "webm":
            return "video-x-generic"

        case "mp3":
        case "wav":
        case "flac":
            return "audio-x-generic"

        case "zip":
        case "tar":
        case "gz":
            return "package-x-generic"

        case "js":
        case "cpp":
        case "c":
        case "h":
        case "qml":
        case "py":
            return "text-x-script"

        default:
            return "text-x-generic"
        }
    }
}
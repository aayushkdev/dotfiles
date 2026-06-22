pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

QtObject {
    readonly property string id: "calculator"
    readonly property string name: "Calculator"
    readonly property string prefix: "="
    readonly property string icon: "accessories-calculator"
    readonly property bool showGlobally: true
    readonly property bool showWhenPrefixEmpty: false

    function search(query) {
        const expression = _cleanExpression(query);

        if (!_looksLikeMath(expression))
            return [];

        const result = _calculate(expression);

        if (result === null)
            return [];

        return [{
            name: "= " + result,
            comment: expression,
            icon: icon,
            result: result
        }];
    }

    function activate(item) {
        if (!item)
            return;

        Quickshell.execDetached(["sh", "-c", "printf %s " + _shellEscape(item.result) + " | wl-copy"]);
        LauncherService.hide();
    }

    function _cleanExpression(query) {
        let expression = (query || "").trim();

        if (expression.startsWith("="))
            expression = expression.slice(1).trim();

        return expression;
    }

    function _looksLikeMath(expression) {
        if (!expression)
            return false;

        if (!/[0-9]/.test(expression))
            return false;

        return /^[0-9+\-*/^().\s]+$/.test(expression);
    }

    function _calculate(expression) {
        try {
            const jsExpression = expression.replace(/\^/g, "**");
            const result = Function("\"use strict\"; return (" + jsExpression + ")")();

            if (typeof result !== "number" || !isFinite(result))
                return null;

            return _formatResult(result);
        } catch (error) {
            return null;
        }
    }

    function _formatResult(value) {
        if (Math.abs(value - Math.round(value)) < 1e-10)
            return Math.round(value).toString();

        return parseFloat(value.toFixed(10)).toString();
    }

    function _shellEscape(text) {
        return "'" + text.replace(/'/g, "'\\''") + "'";
    }
}

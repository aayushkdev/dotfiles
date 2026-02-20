pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick

QtObject {

    // Unique ID
    property string id: ""

    // Display name
    property string name: ""

    // Prefix trigger
    property string prefix: ""

    // Icon
    property string icon: ""

    // Return results based on query
    function search(query) {
        return [];
    }

    // Launch result
    function activate(item) {
    }

}
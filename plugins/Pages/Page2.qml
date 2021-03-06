import QtQuick 2.8
import QtQuick.Controls 2.0

import "qrc:/publicComponentes/" as Components

Components.BasePage {
    id: page
    hasListView: false
    hasNetworkRequest: false
    title: qsTr("Page 2")
    absPath: Config.plugins.pages + "Page2.qml"
    toolBarButtons: [
        {
            "iconName": "search",
            "callback": function() {
                toolBarState = "search"
            }
        }
    ]

    property string searchText
    onSearchTextChanged: label.text = searchText || page.title

    Connections {
        target: App
        onEventNotify: if (eventName === Config.events.cancelSearch) toolBarState = "normal"
    }

    Label {
        id: label
        anchors.centerIn: parent
        text: page.title
    }
}

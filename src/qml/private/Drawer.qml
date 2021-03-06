import QtQuick 2.8
import QtQuick.Controls 2.1

import "qrc:/publicComponentes/" as Components

Drawer {
    id: menu
    width: window.width * 0.85; height: window.height
    dragMargin: window.userProfile && !window.userProfile.isLoggedIn ? 0 : (Qt.styleHints.startDragDistance + 10)

    Component.onCompleted: {
        // fix first open/close effect
        open()
        close()
    }

    // override default effect
    enter: Transition {
        NumberAnimation { duration: 400; easing.type: Easing.OutExpo }
    }
    exit: Transition {
        NumberAnimation { duration: 420; easing.type: Easing.OutExpo }
    }

    property color menuBackgroundColor: Config.theme.menuBackgroundColor
    property color menuItemSelectedTextColor: Qt.darker(menuBackgroundColor, 1.7)
    property color menuItemTextColor: Config.theme.textColorPrimary
    property alias userInfoBackgroundColor: userInfoRect.color
    property color userInfoTextColor: Config.theme.textColorPrimary
    property alias listViewModel: listView.listModel

    // to reduce the couplin with anothers components, the Drawer menu listener events
    // from the application. This connection handle two signals:
    //     1: a signal to open the drawer by event sent by toolbar
    //     2: a signal to add new option to list pages in menu
    Connections {
        target: App
        onEventNotify: {
            // signal signature: eventNotify(string eventName, var eventData)
            if (eventName === Config.events.openDrawer)
                open()
            else if (eventName === Config.events.appendOptionPage)
                functions.addNewMenuItem(eventData, true)
        }
    }

    // create a connection to handle the menu close after viewed page changed.
    Connections {
        target: window
        onCurrentPageChanged: close()
        onDrawerChanged: functions.setMenuItens()
    }

    // set a background color to drawer menu, but the color can be
    // customized set a string color(rgb or color name) in 'menuBackgroundColor' property.
    Rectangle {
        id: menuBackground
        clip: true
        z: 0; anchors.fill: parent; color: menuBackgroundColor
    }

    // show a menu header with user profile image, username and email
    Rectangle {
        id: userInfoRect
        clip: true
        z: 2; color: Config.theme.colorControlHighlight
        width: parent.width+1; height: 190
        anchors { top: parent.top; topMargin: 0; horizontalCenter: parent.horizontalCenter }

        Image {
            visible: Config.showDrawerImage
            source: "qrc:/drawer.jpg"
            anchors.fill: parent; z: 2
            asynchronous: true; cache: true; smooth: true
        }

        Components.RoundedImage {
            id: drawerUserImageProfile
            width: 50; height: width; z: 3
            borderColor: Config.theme.colorAccent
            imgSource: window.userProfile && "image_url" in window.userProfile ? window.userProfile.image_url : "qrc:/default_user_profile.svg"
            anchors { top: parent.top; topMargin: 70; left: parent.left; leftMargin: 20 }
        }

        Text {
            z: 3
            color: userInfoTextColor; textFormat: Text.RichText
            text: window.userProfile ? ("<b>" + window.userProfile.profile.name + "</b><br>" + window.userProfile.profile.email) : ""
            font.pointSize: Config.fontSize.normal
            anchors { top: drawerUserImageProfile.bottom; topMargin: 8; left: parent.left; leftMargin: 20 }
        }
    }

    // the model "pages" is a objects list (plugins) where "showInDrawer" is true
    // each object has the follow properties:
    // {
    //    "absPath": "a string with absolute path to qml file",
    //    "title": "the page title as string",
    //    "awesomeIcon": "the icon name as string",
    //    "roles": [the list of user roles required to access the page],
    //    "order": integer,
    //    "showInDrawer": boolean,
    //    "isHomePage": boolean,
    //    "isLoginPage": boolean
    // }
    Components.CustomListView {
        id: listView
        z: 1; clip: true; width: parent.width
        anchors { fill: undefined; top: userInfoRect.bottom; topMargin: 0; bottom: parent.bottom }
        delegate: Components.ListItem {
            showSeparator: false
            primaryIconName: awesomeIcon || "gear"
            primaryLabelText: title; height: 55
            primaryLabelColor: menuItemTextColor
            selected: window.currentPage && window.currentPage.absPath === absPath
            anchors { horizontalCenter: undefined; left: undefined; right: undefined }
            onClicked: {
                // if the clicked page already exists in the StackView, the page will be moved to top.
                // otherwise, create a new page and push in the stack.
                pageStack.pushIfNotExists(absPath, null)
                close()
            }
        }
    }
}

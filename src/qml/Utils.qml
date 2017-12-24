import QtQuick 2.8

QtObject {
    objectName: "Utils.qml"

    // this signal is used to show alert messages with a native look and feeel dialog using the Dialog object.
    // acceptCallback is a javascript function called after user accept the message, can be pass as javascript function() {}
    // rejectCallback is a javascript function called after dialog closed by cancel button, can be pass as javascript function() {}
    signal alert(string title, string message, var acceptCallback, var rejectCallback)
    onAlert: {
        dialog.title = title || ""
        dialog.text = message || ""
        if (acceptCallback)
            dialog.accepted.connect(acceptCallback)
        else
            dialog.accepted.connect(function() { }) // prevent call last connected callback
        if (rejectCallback)
            dialog.rejected.connect(rejectCallback)
        else
            dialog.rejected.connect(function() { }) // prevent call last connected callback
        dialog.open()
    }

    // buttonPressed is a signal to handle the Android back button and prevent close the app.
    // If the platform is iOS, this signal is ignored.
    // The signal is emited by Keys.onBackPressed and not exists on iOS.
    // When user click in android backButton, some rules needs to be verify:
    //
    // 1: if the alert dialog is opened, will be closed.
    // 2: if swipeView is active, and pagestack is visible in the moment,
    //    pop the current page from pageStack.
    // 3: if swipeView is active, pageStack is empty and current page is not the first page on the swipe container,
    //    paginate to previous page using the decrementIndex function from swipeview.
    // 4: if swipe view is not active and pageStack has more of one page,
    //    pop() and destroy the current page from stack.
    // 5: if swipe view is not active and pageStack has only one page, or swipeview is active and current page is
    //    the first item, minimize the app calling the java activiy moveTaskToBack() via bind with java activity from App QObject.
    // @param e Event a QML event object
    signal buttonPressed(var e)
    onButtonPressed: {
        if (Qt.platform.os !== "android") {
            e.accepted = true
            return
        } else if (dialog.visible) {
            dialog.close()
        } else if (pageStack.depth > 0 && !currentPage.lockGoBack) {
            // when uses swipe view, the pagestack is a secondary container and we need to call pagestack.clear()
            // to remove the current page to focus in swipeView. This needed when the stackView has only a one page!
            if (pageStack.depth == 1 && swipeView && swipeView.count > 0)
                pageStack.clear()
            else if (pageStack.depth == 1 && (!swipeView || swipeView.count == 0))
                App.minimize()
            else
                pageStack.pop()
        } else if (pageStack.depth === 0 && swipeView && swipeView.count && footer.currentIndex > 0) {
            swipeView.decrementCurrentIndex()
        } else {
            // App.minize call a android java to move app to background, but keep running
            App.minimize()
        }
        // setting button.accepted to false, prevent the ApplicationWindow to be closed
        e.accepted = false
    }

    // if Config.usesTabBar is true (in config.json), load all pages and add a button
    // for each page into window tabbar (window footer) using page icon and page name
    // and create a new Page and add to swipeView container.
    // The window footer in this case, keep a instance of TabBar.
    signal loadPages()
    onLoadPages: {
        var i, length = 0, pages = [], component = {}, pageJson = {}, tabBarButtonPath = Qt.resolvedUrl("TabBarButton.qml")
        // load all saved (plugins) pages
        pages = App.readSetting("pages", App.SettingTypeJsonArray)
        length = pages.length
        for (i = 0; i < length; ++i) {
            pageJson = pages[i]
            // if current user permission is not valid for this page
            // or page is not to show in TabBar, go to next visible page
            if (!pageJson.showInTabBar || (Config.hasLogin && userProfile.profileName && pageJson.roles.indexOf(userProfile.profileName) < 0))
                continue
            component = Qt.createComponent(Qt.resolvedUrl(pageJson.absPath))
            // if the page has a some error, go to next page
            if (component.status === Component.Error) {
                console.error(component.errorString())
                continue
            }
            swipeView.addItem(component.createObject(swipeView))
            footer.addItem(Qt.createComponent(tabBarButtonPath).createObject(footer,{"checked":i === 0,"text":pageJson.title,"iconName":pageJson.icon,"showTextOnPressed":true}))
        }
        footer.visible = true
        pages = undefined
        component = undefined
        pageJson = undefined
    }

    // first method called by application window to set
    // the first visible page to the user. Some rules needs to check:
    // 1: If is Config.hasLogin and user logged in, check if application is configured to use TabBar,
    //    if true clear pagestack, used by previous page like login.
    // 2: If application is not configured to use TabBar, replace current page.
    // 3: If user is not logged in, load the login page from saved settings.
    //    Login page needs to be set by some plugin and the path is saved by PluginManager.
    signal setActivePage()
    onSetActivePage: {
        if (Config.showEula && App.readSetting("app_eula_accepted") !== "1") {
            pageStack.push(Qt.resolvedUrl("EulaAgreement.qml"))
            return
        }
        if (!Config.hasLogin || Config.hasLogin && userProfile && userProfile.isLoggedIn) {
            if (Config.usesTabBar) {
                pageStack.clear()
                loadPages()
            } else {
                var homePageUrl = App.readSetting("homePageUrl", App.SettingTypeString)
                pageStack.replace(homePageUrl, {"absPath":homePageUrl})
            }
        } else {
            // get the login page url defined by some plugin
            var loginPageUrl = App.readSetting("loginPageUrl", App.SettingTypeString)
            // if pageStack has more of one item, like user logout, replace last page by login.
            if (pageStack.depth > 0)
                pageStack.replace(loginPageUrl, null)
            else
                pageStack.push(loginPageUrl, null)
            loginPageUrl = ""
        }
    }
}

import QtQuick 2.15
import QtQuick.Layouts 1.15
import SortFilterProxyModel 0.2
import "utils.js" as Utils

FocusScope {
    id: root
    focus: true

    property int currentCollectionIndex: 0
    property int currentGameIndex: 0
    property var currentCollection: api.collections.count > 0 ? api.collections.get(currentCollectionIndex) : null
    property bool isRestoringState: false
    property string focusedPanel: "collections"
    property bool detailsExpanded: false
    property string gamesViewMode: "grid"
    property color backgroundColor: "#0a0a0a"
    property color panelColor: "#1a1a1a"
    property color accentColor: "#0078d7"
    property color textColor: "#ffffff"
    property color secondaryTextColor: "#b0b0b0"
    property color borderColor: "#333333"
    property string fontFamily: global.fonts.sans
    property string condensedFontFamily: global.fonts.condensed

    property var currentGame: {
        if (sharedGamesFilter.filteredModel &&
            currentGameIndex >= 0 &&
            currentGameIndex < sharedGamesFilter.filteredModel.count) {
            var filteredGame = sharedGamesFilter.filteredModel.get(currentGameIndex)
            if (filteredGame) {
                return filteredGame
            }
            }

            return currentCollection && currentCollection.games.count > 0 ?
            currentCollection.games.get(currentGameIndex) : null
    }

    property var currentFilteredGame: {
        if (sharedGamesFilter.filteredModel &&
            currentGameIndex >= 0 &&
            currentGameIndex < sharedGamesFilter.filteredModel.count) {
            return sharedGamesFilter.filteredModel.get(currentGameIndex)
            }
            return null
    }

    signal forceGridUpdate(int collectionIndex, int gameIndex)

    GamesFilter {
        id: sharedGamesFilter
        sourceModel: root.currentCollection ? root.currentCollection.games : null
        globalSearchMode: false

        onSearchCompleted: {
            console.log("SharedGamesFilter: Search completed")
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: backgroundColor

        RowLayout {
            anchors.fill: parent
            anchors.margins: root.width * 0.01
            spacing: root.width * 0.01

            CollectionsPanel {
                id: collectionsPanel
                Layout.preferredWidth: root.width * 0.24
                Layout.fillHeight: true
                currentIndex: root.currentCollectionIndex
                focus: root.focusedPanel === "collections"

                onCurrentIndexChanged: {
                    if (!root.isRestoringState) {
                        root.currentCollectionIndex = currentIndex
                        root.saveState("collection_changed")
                    }
                }
            }

            GamesGridView {
                id: gamesGridView
                visible: gamesViewMode === "grid"
                opacity: visible ? 1.0 : 0.0
                Layout.preferredWidth: detailsExpanded ? root.width * 0.33 : root.width * 0.48
                Layout.fillHeight: true
                currentIndex: root.currentGameIndex
                focus: root.focusedPanel === "games" && visible

                sharedFilter: sharedGamesFilter

                columns: detailsExpanded ? 3 : 4
                rows: 3

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                onCurrentIndexChanged: {
                    if (!root.isRestoringState && root.currentGameIndex !== currentIndex) {
                        root.currentGameIndex = currentIndex
                        root.saveState("game_changed")
                    }
                }

                onSwitchToListView: {
                    console.log("Switching to List View")
                    root.gamesViewMode = "list"
                    api.memory.set('gamesViewMode', "list")
                    gamesListView.currentIndex = gamesGridView.currentIndex
                }
            }

            GamesListView {
                id: gamesListView
                visible: gamesViewMode === "list"
                opacity: visible ? 1.0 : 0.0
                Layout.preferredWidth: detailsExpanded ? root.width * 0.33 : root.width * 0.48
                Layout.fillHeight: true
                currentIndex: root.currentGameIndex
                focus: root.focusedPanel === "games" && visible

                sharedFilter: sharedGamesFilter

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                onCurrentIndexChanged: {
                    if (!root.isRestoringState && root.currentGameIndex !== currentIndex) {
                        root.currentGameIndex = currentIndex
                        root.saveState("game_changed")
                    }
                }

                onSwitchToGridView: {
                    console.log("Switching to Grid View")
                    root.gamesViewMode = "grid"
                    api.memory.set('gamesViewMode', "grid")
                    gamesGridView.currentIndex = gamesListView.currentIndex
                }
            }

            GameDetailsPanel {
                id: gameDetailsPanel
                property var sharedFilter: sharedGamesFilter
                Layout.preferredWidth: detailsExpanded ? root.width * 0.39 : root.width * 0.24
                Layout.fillHeight: true

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                }

                onExpansionChanged: {
                    root.detailsExpanded = expanded
                    console.log("Details panel expanded:", expanded)

                    if (expanded) {
                        root.focusedPanel = "details"
                    }
                }
            }
        }
    }

    Connections {
        target: gamesGridView
        function onFilteredGameChanged(game) {
            if (game && !root.isRestoringState) {
                root.currentGame = game
            }
        }

        function onCollapseDetailsPanel() {
            if (root.detailsExpanded) {
                gameDetailsPanel.isExpanded = false
                root.detailsExpanded = false
            }
        }
    }

    Connections {
        target: gamesListView
        function onFilteredGameChanged(game) {
            if (game && !root.isRestoringState) {
                root.currentGame = game
            }
        }

        function onCollapseDetailsPanel() {
            if (root.detailsExpanded) {
                gameDetailsPanel.isExpanded = false
                root.detailsExpanded = false
            }
        }
    }

    onForceGridUpdate: {
        if (collectionIndex >= 0 && collectionIndex < api.collections.count) {
            currentCollectionIndex = collectionIndex
        }
        if (gameIndex >= 0 && root.currentCollection && gameIndex < root.currentCollection.games.count) {
            currentGameIndex = gameIndex
            if (gamesViewMode === "grid") {
                gamesGridView.currentIndex = gameIndex
            } else {
                gamesListView.currentIndex = gameIndex
            }
        }
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            event.accepted = true

            if (detailsExpanded) {
                gameDetailsPanel.isExpanded = false
                root.detailsExpanded = false
                root.focusedPanel = "games"
            } else if (focusedPanel === "games") {
                root.switchToCollectionsPanel()
            }
        }
        else if (api.keys.isAccept(event)) {
            event.accepted = true
            if (focusedPanel === "games" && currentGame) {
                root.launchCurrentGame()
            } else if (focusedPanel === "collections") {
                root.switchToGamesPanel()
            }
        }
        else if (api.keys.isNextPage(event)) {
            event.accepted = true
            if (focusedPanel === "games") {
                if (gamesViewMode === "grid") {
                    gamesGridView.nextPage()
                } else {
                    gamesListView.nextPage()
                }
            }
        }
        else if (api.keys.isPrevPage(event)) {
            event.accepted = true
            if (focusedPanel === "games") {
                if (gamesViewMode === "grid") {
                    gamesGridView.previousPage()
                } else {
                    gamesListView.previousPage()
                }
            }
        }
        else if (api.keys.isPageUp(event)) {
            event.accepted = true
            if (focusedPanel === "collections") {
                collectionsPanel.previousItem()
            }
        }
        else if (api.keys.isPageDown(event)) {
            event.accepted = true
            if (focusedPanel === "collections") {
                collectionsPanel.nextItem()
            }
        }
        else if (event.key === Qt.Key_Right) {
            event.accepted = true
            if (focusedPanel === "collections") {
                root.switchToGamesPanel()
            }
        }
        else if (event.key === Qt.Key_Left) {
            event.accepted = true
            if (focusedPanel === "games") {
                var activeView = gamesViewMode === "grid" ? gamesGridView : gamesListView
                if (activeView.currentIndex === 0) {
                    root.switchToCollectionsPanel()
                }
            }
        }
        else if (event.key === Qt.Key_Tab || event.key === Qt.Key_D) {
            event.accepted = true
            gameDetailsPanel.isExpanded = !gameDetailsPanel.isExpanded
        }
        else if (event.key === Qt.Key_V) {
            event.accepted = true
            if (gamesViewMode === "grid") {
                gamesListView.currentIndex = gamesGridView.currentIndex
                root.gamesViewMode = "list"
            } else {
                gamesGridView.currentIndex = gamesListView.currentIndex
                root.gamesViewMode = "grid"
            }
            api.memory.set('gamesViewMode', root.gamesViewMode)
        }
    }

    Component.onCompleted: {
        var savedViewMode = api.memory.get('gamesViewMode')
        if (savedViewMode === "list" || savedViewMode === "grid") {
            root.gamesViewMode = savedViewMode
        }

        root.restoreState()
    }

    Component.onDestruction: {
        root.saveState("component_destruction")
    }

    function selectCollection(index) {
        if (index >= 0 && index < api.collections.count) {
            isRestoringState = true

            root.currentCollectionIndex = index
            root.currentGameIndex = 0

            if (gamesViewMode === "grid" && gamesGridView) {
                gamesGridView.currentIndex = 0
            } else if (gamesViewMode === "list" && gamesListView) {
                gamesListView.currentIndex = 0
            }

            isRestoringState = false
            root.saveState("collection_selected")
        }
    }

    function switchToGamesPanel() {
        focusedPanel = "games"
        if (gamesViewMode === "grid") {
            gamesGridView.forceActiveFocus()
        } else {
            gamesListView.forceActiveFocus()
        }

        if (detailsExpanded) {
            gameDetailsPanel.isExpanded = false
        }
    }

    function switchToCollectionsPanel() {
        focusedPanel = "collections"
        collectionsPanel.forceActiveFocus()

        if (detailsExpanded) {
            gameDetailsPanel.isExpanded = false
        }
    }

    function launchCurrentGame() {
        if (currentGame) {
            root.saveState("game_launched")
            currentGame.launch()
        }
    }

    function saveState(reason) {
        api.memory.set('lastCollectionIndex', currentCollectionIndex)
        api.memory.set('lastGameIndex', currentGameIndex)
        api.memory.set('gamesViewMode', gamesViewMode)

        if (currentCollection) {
            api.memory.set('lastCollectionName', currentCollection.name)
        }

        if (currentGame) {
            api.memory.set('lastGameTitle', currentGame.title)
        }

        api.memory.set('lastSaveTime', Date.now())
    }

    function restoreState() {
        root.isRestoringState = true

        try {
            var savedCollectionIndex = api.memory.get('lastCollectionIndex')
            var savedGameIndex = api.memory.get('lastGameIndex')

            var hasPreviousState = (savedCollectionIndex !== undefined &&
            savedGameIndex !== undefined)

            if (hasPreviousState) {
                if (savedCollectionIndex >= 0 && savedCollectionIndex < api.collections.count) {
                    root.currentCollectionIndex = savedCollectionIndex
                } else {
                    root.currentCollectionIndex = 0
                }

                focusedPanel = "games"
                restoreTimer.restart()

            } else {
                root.currentCollectionIndex = 0
                root.currentGameIndex = 0
                focusedPanel = "collections"
                collectionsPanel.forceActiveFocus()
                root.isRestoringState = false
            }

        } catch (error) {
            root.currentCollectionIndex = 0
            root.currentGameIndex = 0
            focusedPanel = "collections"
            collectionsPanel.forceActiveFocus()
            root.isRestoringState = false
        }
    }

    Timer {
        id: restoreTimer
        interval: 100
        onTriggered: {
            var savedGameIndex = api.memory.get('lastGameIndex')
            var savedGameTitle = api.memory.get('lastGameTitle')

            if (savedGameIndex !== undefined &&
                savedGameIndex >= 0 &&
                root.currentCollection &&
                savedGameIndex < root.currentCollection.games.count) {

                root.currentGameIndex = savedGameIndex
                if (gamesViewMode === "grid") {
                    gamesGridView.currentIndex = savedGameIndex
                } else {
                    gamesListView.currentIndex = savedGameIndex
                }

                } else if (savedGameTitle && root.currentCollection) {
                    for (var j = 0; j < root.currentCollection.games.count; j++) {
                        var game = root.currentCollection.games.get(j)
                        if (game && game.title === savedGameTitle) {
                            root.currentGameIndex = j
                            if (gamesViewMode === "grid") {
                                gamesGridView.currentIndex = j
                            } else {
                                gamesListView.currentIndex = j
                            }
                            break
                        }
                    }
                }

                if (root.currentGameIndex === undefined || root.currentGameIndex < 0) {
                    root.currentGameIndex = 0
                    if (gamesViewMode === "grid") {
                        gamesGridView.currentIndex = 0
                    } else {
                        gamesListView.currentIndex = 0
                    }
                }

                if (gamesViewMode === "grid") {
                    gamesGridView.forceActiveFocus()
                } else {
                    gamesListView.forceActiveFocus()
                }
                root.isRestoringState = false
        }
    }

    function restoreStateByName() {
        var savedCollectionName = api.memory.get('lastCollectionName')
        var savedGameTitle = api.memory.get('lastGameTitle')

        if (savedCollectionName) {
            for (var i = 0; i < api.collections.count; i++) {
                var collection = api.collections.get(i)
                if (collection && collection.name === savedCollectionName) {
                    root.currentCollectionIndex = i
                    break
                }
            }
        }

        if (root.currentCollectionIndex === undefined) {
            root.currentCollectionIndex = 0
        }
    }

    function selectCollectionWithMouse(index) {
        isRestoringState = true

        currentCollectionIndex = index
        currentGameIndex = 0

        collectionsPanel.currentIndex = index
        if (gamesViewMode === "grid" && gamesGridView) {
            gamesGridView.currentIndex = 0
        } else if (gamesViewMode === "list" && gamesListView) {
            gamesListView.currentIndex = 0
        }

        focusedPanel = "collections"
        collectionsPanel.forceActiveFocus()

        isRestoringState = false
        saveState("collection_mouse_selected")
    }

    function selectGameWithMouse(index) {
        isRestoringState = true

        currentGameIndex = index
        if (gamesViewMode === "grid" && gamesGridView) {
            gamesGridView.currentIndex = index
        } else if (gamesViewMode === "list" && gamesListView) {
            gamesListView.currentIndex = index
        }

        focusedPanel = "games"
        if (gamesViewMode === "grid") {
            gamesGridView.forceActiveFocus()
        } else {
            gamesListView.forceActiveFocus()
        }

        isRestoringState = false
        saveState("game_mouse_selected")
    }

    onCurrentGameIndexChanged: {
        if (!isRestoringState) {
            if (gamesViewMode === "grid" && gamesGridView.currentIndex !== currentGameIndex) {
                gamesGridView.currentIndex = currentGameIndex
            } else if (gamesViewMode === "list" && gamesListView.currentIndex !== currentGameIndex) {
                gamesListView.currentIndex = currentGameIndex
            }
        }
    }

    onFocusedPanelChanged: {
        Qt.callLater(function() {
            if (focusedPanel === "collections") {
                collectionsPanel.forceActiveFocus()
            } else if (focusedPanel === "games") {
                if (gamesViewMode === "grid") {
                    gamesGridView.forceActiveFocus()
                } else {
                    gamesListView.forceActiveFocus()
                }
            }
        })
    }
}

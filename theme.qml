import QtQuick 2.15
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

    signal forceGridUpdate(int collectionIndex, int gameIndex)

    property color backgroundColor: "#0a0a0a"
    property color panelColor: "#1a1a1a"
    property color accentColor: "#0078d7"
    property color textColor: "#ffffff"
    property color secondaryTextColor: "#b0b0b0"
    property color borderColor: "#333333"
    property string fontFamily: global.fonts.sans
    property string condensedFontFamily: global.fonts.condensed

    property var currentGame: {
        // Si hay filtro aplicado, usar el juego del modelo filtrado
        if (gamesGridView && gamesGridView.gamesFilter &&
            gamesGridView.gamesFilter.filteredModel &&
            currentGameIndex >= 0 &&
            currentGameIndex < gamesGridView.gamesFilter.filteredModel.count) {

            var filteredGame = gamesGridView.gamesFilter.filteredModel.get(currentGameIndex)
            if (filteredGame) {
                return filteredGame
            }
            }

            // Fallback al juego de la colección original
            return currentCollection && currentCollection.games.count > 0 ?
            currentCollection.games.get(currentGameIndex) : null
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: backgroundColor

        Item {
            anchors {
                fill: parent
                margins: vpx(20)
            }

            CollectionsPanel {
                id: collectionsPanel
                width: parent.width * 0.25 - vpx(10)
                height: parent.height
                anchors.left: parent.left
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
                width: parent.width * 0.5 - vpx(10)
                height: parent.height
                anchors.left: collectionsPanel.right
                anchors.leftMargin: vpx(20)
                currentIndex: root.currentGameIndex
                focus: root.focusedPanel === "games"

                onCurrentIndexChanged: {
                    if (!root.isRestoringState && root.currentGameIndex !== currentIndex) {
                        root.currentGameIndex = currentIndex
                        root.saveState("game_changed")
                    }
                }
            }

            GameDetailsPanel {
                id: gameDetailsPanel
                width: parent.width * 0.25 - vpx(10)
                height: parent.height
                anchors.left: gamesGridView.right
                anchors.leftMargin: vpx(20)
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
    }

    onForceGridUpdate: {
        if (collectionIndex >= 0 && collectionIndex < api.collections.count) {
            currentCollectionIndex = collectionIndex
        }
        if (gameIndex >= 0 && root.currentCollection && gameIndex < root.currentCollection.games.count) {
            currentGameIndex = gameIndex
            gamesGridView.currentIndex = gameIndex
        }
    }

    Keys.onPressed: {
        if (api.keys.isAccept(event)) {
            event.accepted = true
            if (focusedPanel === "games" && currentGame) {
                root.launchCurrentGame()
            } else if (focusedPanel === "collections") {
                root.switchToGamesPanel()
            }
        }
        else if (api.keys.isCancel(event)) {
            event.accepted = true
            if (focusedPanel === "games") {
                root.switchToCollectionsPanel()
            }
        }
        else if (api.keys.isNextPage(event)) {
            event.accepted = true
            if (focusedPanel === "games") {
                gamesGridView.nextPage()
            }
        }
        else if (api.keys.isPrevPage(event)) {
            event.accepted = true
            if (focusedPanel === "games") {
                gamesGridView.previousPage()
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
            if (focusedPanel === "games" && gamesGridView.currentIndex === 0) {
                root.switchToCollectionsPanel()
            }
        }
    }

    Component.onCompleted: {
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

            if (gamesGridView) {
                gamesGridView.currentIndex = 0
            }

            isRestoringState = false
            root.saveState("collection_selected")
        }
    }

    function switchToGamesPanel() {
        focusedPanel = "games"
        gamesGridView.forceActiveFocus()
    }

    function switchToCollectionsPanel() {
        focusedPanel = "collections"
        collectionsPanel.forceActiveFocus()
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
                gamesGridView.currentIndex = savedGameIndex

                } else if (savedGameTitle && root.currentCollection) {
                    for (var j = 0; j < root.currentCollection.games.count; j++) {
                        var game = root.currentCollection.games.get(j)
                        if (game && game.title === savedGameTitle) {
                            root.currentGameIndex = j
                            gamesGridView.currentIndex = j
                            break
                        }
                    }
                }

                if (root.currentGameIndex === undefined || root.currentGameIndex < 0) {
                    root.currentGameIndex = 0
                    gamesGridView.currentIndex = 0
                }

                gamesGridView.forceActiveFocus()

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
        if (gamesGridView) {
            gamesGridView.currentIndex = 0
        }

        focusedPanel = "collections"
        collectionsPanel.forceActiveFocus()

        isRestoringState = false
        saveState("collection_mouse_selected")
    }

    function selectGameWithMouse(index) {
        isRestoringState = true

        currentGameIndex = index
        if (gamesGridView) {
            gamesGridView.currentIndex = index
        }

        focusedPanel = "games"
        gamesGridView.forceActiveFocus()

        isRestoringState = false
        saveState("game_mouse_selected")
    }

    onCurrentGameIndexChanged: {
        if (!isRestoringState && gamesGridView.currentIndex !== currentGameIndex) {
            gamesGridView.currentIndex = currentGameIndex
        }
    }

    onFocusedPanelChanged: {
        Qt.callLater(function() {
            if (focusedPanel === "collections") {
                collectionsPanel.forceActiveFocus()
            } else if (focusedPanel === "games") {
                gamesGridView.forceActiveFocus()
            }
        })
    }
}

import QtQuick 2.15
import SortFilterProxyModel 0.2
import "utils.js" as Utils

FocusScope {
    id: root
    focus: true

    // Propiedades del tema
    property int currentCollectionIndex: 0
    property int currentGameIndex: 0
    property var currentCollection: api.collections.count > 0 ? api.collections.get(currentCollectionIndex) : null
    property var currentGame: currentCollection && currentCollection.games.count > 0 ?
    currentCollection.games.get(currentGameIndex) : null

    // Propiedad para controlar cambios
    property bool isRestoringState: false

    // Enum para controlar qué panel tiene el foco
    property string focusedPanel: "collections" // "collections" o "games"

    // Señal para forzar actualización del grid
    signal forceGridUpdate(int collectionIndex, int gameIndex)

    // Colores del tema (tipo Launchbox)
    property color backgroundColor: "#0a0a0a"
    property color panelColor: "#1a1a1a"
    property color accentColor: "#0078d7" // Azul Launchbox
    property color textColor: "#ffffff"
    property color secondaryTextColor: "#b0b0b0"
    property color borderColor: "#333333"

    // Fuentes
    property string fontFamily: global.fonts.sans
    property string condensedFontFamily: global.fonts.condensed

    Rectangle {
        id: background
        anchors.fill: parent
        color: backgroundColor

        // Layout principal con 3 paneles
        Item {
            anchors {
                fill: parent
                margins: vpx(20)
            }

            // Panel izquierdo - Colecciones (25%)
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

                // Cuando recibe foco, activarlo
                onFocusChanged: {
                    if (focus) {
                        console.log("CollectionsPanel gained focus")
                    }
                }
            }

            // Panel central - Juegos (50%)
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

                // Cuando recibe foco, activarlo
                onFocusChanged: {
                    if (focus) {
                        console.log("GamesGridView gained focus")
                    }
                }
            }

            // Panel derecho - Detalles (25%)
            GameDetailsPanel {
                id: gameDetailsPanel
                width: parent.width * 0.25 - vpx(10)
                height: parent.height
                anchors.left: gamesGridView.right
                anchors.leftMargin: vpx(20)
            }
        }
    }

    onForceGridUpdate: {
        console.log("Force grid update - Collection:", collectionIndex, "Game:", gameIndex)
        if (collectionIndex >= 0 && collectionIndex < api.collections.count) {
            currentCollectionIndex = collectionIndex
            collectionsPanel.ensureCurrentVisible()
        }
        if (gameIndex >= 0 && root.currentCollection && gameIndex < root.currentCollection.games.count) {
            currentGameIndex = gameIndex
            gamesGridView.currentIndex = gameIndex
        }
    }

    // Navegación global
    Keys.onPressed: {
        if (api.keys.isAccept(event)) {
            event.accepted = true
            if (focusedPanel === "games" && currentGame) {
                root.launchCurrentGame()
            } else if (focusedPanel === "collections") {
                // Desde collections, Accept también puede cambiar al panel de juegos
                root.switchToGamesPanel()
            }
        }
        else if (api.keys.isCancel(event)) {
            event.accepted = true
            if (focusedPanel === "games") {
                // Volver al panel de colecciones
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
                // Forzar actualización visual antes de cambiar
                collectionsPanel.forceLayout()
                root.switchToGamesPanel()
                gamesGridView.forceLayout()
            }
        }
        else if (event.key === Qt.Key_Left) {
            event.accepted = true
            if (focusedPanel === "games" && gamesGridView.currentIndex === 0) {
                // Forzar actualización visual antes de cambiar
                gamesGridView.forceLayout()
                root.switchToCollectionsPanel()
                collectionsPanel.forceLayout()
            }
        }
    }

    // Restaurar estado al cargar
    Component.onCompleted: {
        root.restoreState()
    }

    // Guardar estado al salir
    Component.onDestruction: {
        root.saveState("component_destruction")
    }

    // Función para cambiar colección
    function selectCollection(index) {
        if (index >= 0 && index < api.collections.count) {
            isRestoringState = true

            root.currentCollectionIndex = index
            root.currentGameIndex = 0

            // Forzar reset visual
            if (gamesGridView) {
                gamesGridView.currentIndex = 0
            }

            isRestoringState = false
            root.saveState("collection_selected")
        }
    }

    // Función para cambiar al panel de juegos
    function switchToGamesPanel() {
        console.log("Switching to games panel")
        focusedPanel = "games"
        gamesGridView.forceActiveFocus()
    }

    // Función para volver al panel de colecciones
    function switchToCollectionsPanel() {
        console.log("Switching to collections panel")
        focusedPanel = "collections"
        collectionsPanel.forceActiveFocus()
    }

    // Función para lanzar juego actual
    function launchCurrentGame() {
        if (currentGame) {
            root.saveState("game_launched")
            currentGame.launch()
        }
    }

    // Funciones para guardar/restaurar estado
    function saveState(reason) {
        console.log("Saving state - Reason:", reason)

        api.memory.set('lastCollectionIndex', currentCollectionIndex)
        api.memory.set('lastGameIndex', currentGameIndex)

        if (currentCollection) {
            api.memory.set('lastCollectionName', currentCollection.name)
        }

        if (currentGame) {
            api.memory.set('lastGameTitle', currentGame.title)
        }

        api.memory.set('lastSaveTime', Date.now())

        console.log("State saved - Collection:", currentCollectionIndex, "Game:", currentGameIndex)
    }

    function restoreState() {
        console.log("Restoring state...")
        root.isRestoringState = true

        try {
            var savedCollectionIndex = api.memory.get('lastCollectionIndex')
            var savedGameIndex = api.memory.get('lastGameIndex')

            console.log("Saved indices - Collection:", savedCollectionIndex, "Game:", savedGameIndex)

            // Determinar si hay estado previo guardado
            var hasPreviousState = (savedCollectionIndex !== undefined &&
            savedGameIndex !== undefined)

            if (hasPreviousState) {
                console.log("Previous state found, restoring to games panel")

                // Validar y restaurar colección
                if (savedCollectionIndex >= 0 && savedCollectionIndex < api.collections.count) {
                    root.currentCollectionIndex = savedCollectionIndex
                } else {
                    root.currentCollectionIndex = 0
                }

                // El foco irá al panel de juegos
                focusedPanel = "games"
                restoreTimer.restart()

            } else {
                console.log("No previous state, starting at collections panel")

                // Sin estado previo: empezar en colecciones, índice 0
                root.currentCollectionIndex = 0
                root.currentGameIndex = 0
                focusedPanel = "collections"

                // Dar foco inmediatamente al panel de colecciones
                collectionsPanel.forceActiveFocus()
                root.isRestoringState = false
            }

        } catch (error) {
            console.error("Error restoring state:", error)
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
            console.log("Restoring game index after collection load...")

            var savedGameIndex = api.memory.get('lastGameIndex')
            var savedGameTitle = api.memory.get('lastGameTitle')

            // Intentar restaurar por índice
            if (savedGameIndex !== undefined &&
                savedGameIndex >= 0 &&
                root.currentCollection &&
                savedGameIndex < root.currentCollection.games.count) {

                root.currentGameIndex = savedGameIndex
                gamesGridView.currentIndex = savedGameIndex
                console.log("Game index restored:", savedGameIndex)

                } else if (savedGameTitle && root.currentCollection) {
                    // Buscar por título como fallback
                    for (var j = 0; j < root.currentCollection.games.count; j++) {
                        var game = root.currentCollection.games.get(j)
                        if (game && game.title === savedGameTitle) {
                            root.currentGameIndex = j
                            gamesGridView.currentIndex = j
                            console.log("Game found by title:", savedGameTitle, "at index:", j)
                            break
                        }
                    }
                }

                // Si no se encontró, usar índice 0
                if (root.currentGameIndex === undefined || root.currentGameIndex < 0) {
                    root.currentGameIndex = 0
                    gamesGridView.currentIndex = 0
                }

                // Asegurar visibilidad
                collectionsPanel.ensureCurrentVisible()
                gamesGridView.ensureCurrentVisible()

                // Dar foco al panel de juegos (ya que restauramos estado previo)
                gamesGridView.forceActiveFocus()

                root.isRestoringState = false
                console.log("State restoration complete - Collection:", root.currentCollectionIndex,
                            "Game:", root.currentGameIndex, "Focus:", focusedPanel)
        }
    }

    function restoreStateByName() {
        var savedCollectionName = api.memory.get('lastCollectionName')
        var savedGameTitle = api.memory.get('lastGameTitle')

        console.log("Attempting to restore by name - Collection:", savedCollectionName,
                    "Game:", savedGameTitle)

        if (savedCollectionName) {
            for (var i = 0; i < api.collections.count; i++) {
                var collection = api.collections.get(i)
                if (collection && collection.name === savedCollectionName) {
                    root.currentCollectionIndex = i
                    console.log("Found collection by name:", savedCollectionName, "at index:", i)
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

        // Forzar sincronización inmediata
        collectionsPanel.currentIndex = index
        if (gamesGridView) {
            gamesGridView.currentIndex = 0
        }

        // Actualizar foco - IMPORTANTE: asegurar que el panel de colecciones tenga foco
        focusedPanel = "collections"

        // Forzar actualización visual inmediata
        collectionsPanel.forceLayout()
        if (gamesGridView) {
            gamesGridView.forceLayout()
        }

        // Dar foco al panel
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

        // Actualizar foco - IMPORTANTE: asegurar que el panel de juegos tenga foco
        focusedPanel = "games"

        // Forzar actualización visual inmediata
        collectionsPanel.forceLayout()
        if (gamesGridView) {
            gamesGridView.forceLayout()
        }

        // Dar foco al panel
        gamesGridView.forceActiveFocus()

        isRestoringState = false
        saveState("game_mouse_selected")
    }

    onCurrentGameIndexChanged: {
        if (!isRestoringState && gamesGridView.currentIndex !== currentGameIndex) {
            console.log("Syncing grid index to:", currentGameIndex)
            gamesGridView.currentIndex = currentGameIndex
        }
    }

    onFocusedPanelChanged: {
        console.log("Focused panel changed to:", focusedPanel)

        // Pequeño delay para asegurar que los paneles estén listos
        Qt.callLater(function() {
            if (collectionsPanel) {
                console.log("Forcing collections panel layout")
                collectionsPanel.forceLayout()
            }
            if (gamesGridView) {
                console.log("Forcing games grid layout")
                gamesGridView.forceLayout()
            }
        })
    }
}

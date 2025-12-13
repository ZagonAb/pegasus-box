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
                onCurrentIndexChanged: {
                    if (!root.isRestoringState) {
                        root.currentCollectionIndex = currentIndex
                        root.saveState("collection_changed")
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
                onCurrentIndexChanged: {
                    if (!root.isRestoringState && root.currentGameIndex !== currentIndex) {
                        root.currentGameIndex = currentIndex
                        root.saveState("game_changed")
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
            // Asegurar visibilidad en CollectionsPanel
            collectionsPanel.ensureCurrentVisible()
        }
        if (gameIndex >= 0 && root.currentCollection && gameIndex < root.currentCollection.games.count) {
            currentGameIndex = gameIndex
            // Forzar actualización del currentIndex en GamesGridView
            gamesGridView.currentIndex = gameIndex
        }
    }

    Keys.onPressed: {
        if (api.keys.isAccept(event)) {
            event.accepted = true
            if (currentGame) {
                root.launchCurrentGame()
            }
        }
        else if (api.keys.isCancel(event)) {
            event.accepted = true
            // Aquí podrías añadir salir o volver atrás
        }
        else if (api.keys.isNextPage(event)) {
            event.accepted = true
            gamesGridView.nextPage()
        }
        else if (api.keys.isPrevPage(event)) {
            event.accepted = true
            gamesGridView.previousPage()
        }
        else if (api.keys.isPageUp(event)) {
            event.accepted = true
            collectionsPanel.previousItem()
        }
        else if (api.keys.isPageDown(event)) {
            event.accepted = true
            collectionsPanel.nextItem()
        }
    }

    // Restaurar estado al cargar
    Component.onCompleted: {
        root.restoreState()
        // Dar foco al grid de juegos
        gamesGridView.forceActiveFocus()
    }

    // Guardar estado al salir
    Component.onDestruction: {
        root.saveState("component_destruction")
    }

    // Función para cambiar colección
    function selectCollection(index) {
        if (index >= 0 && index < api.collections.count) {
            root.currentCollectionIndex = index
            root.currentGameIndex = 0
            // Forzar reset del grid
            gamesGridView.currentIndex = 0
            root.saveState("collection_selected")
        }
    }

    // Función para lanzar juego actual
    function launchCurrentGame() {
        if (currentGame) {
            // Guardar estado antes de lanzar
            root.saveState("game_launched")
            currentGame.launch()
        }
    }

    // Funciones para guardar/restaurar estado
    function saveState(reason) {
        console.log("Saving state - Reason:", reason)

        // Guardar índices actuales
        api.memory.set('lastCollectionIndex', currentCollectionIndex)
        api.memory.set('lastGameIndex', currentGameIndex)

        // Guardar IDs para mayor precisión
        if (currentCollection) {
            api.memory.set('lastCollectionName', currentCollection.name)
        }

        if (currentGame) {
            api.memory.set('lastGameTitle', currentGame.title)
        }

        // Guardar timestamp
        api.memory.set('lastSaveTime', Date.now())

        console.log("State saved - Collection:", currentCollectionIndex, "Game:", currentGameIndex)
    }

    function restoreState() {
        console.log("Restoring state...")
        root.isRestoringState = true

        try {
            // Intentar restaurar por índice
            var savedCollectionIndex = api.memory.get('lastCollectionIndex')
            var savedGameIndex = api.memory.get('lastGameIndex')

            console.log("Saved indices - Collection:", savedCollectionIndex, "Game:", savedGameIndex)

            // Validar y restaurar colección
            if (savedCollectionIndex !== undefined &&
                savedCollectionIndex >= 0 &&
                savedCollectionIndex < api.collections.count) {

                root.currentCollectionIndex = savedCollectionIndex

                // Pequeño delay para asegurar que currentCollection se actualice
                restoreTimer.restart()

                } else {
                    // Restaurar por nombres como fallback
                    root.restoreStateByName()
                    restoreTimer.restart()
                }

        } catch (error) {
            console.error("Error restoring state:", error)
            // Valores por defecto
            root.currentCollectionIndex = 0
            root.currentGameIndex = 0
            root.isRestoringState = false
        }
    }

    Timer {
        id: restoreTimer
        interval: 100 // Pequeño delay para asegurar sincronización
        onTriggered: {
            console.log("Restoring game index after collection load...")

            var savedGameIndex = api.memory.get('lastGameIndex')
            var savedGameTitle = api.memory.get('lastGameTitle')

            // Primero intentar por índice
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

                // Asegurar que la colección actual sea visible en el panel
                collectionsPanel.ensureCurrentVisible()

                root.isRestoringState = false
                console.log("State restoration complete - Collection:", root.currentCollectionIndex,
                            "Game:", root.currentGameIndex)
        }
    }

    function restoreStateByName() {
        var savedCollectionName = api.memory.get('lastCollectionName')
        var savedGameTitle = api.memory.get('lastGameTitle')

        console.log("Attempting to restore by name - Collection:", savedCollectionName,
                    "Game:", savedGameTitle)

        // Buscar colección por nombre
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

        // Si no encontró colección, usar primera
        if (root.currentCollectionIndex === undefined) {
            root.currentCollectionIndex = 0
        }
    }

    // Cuando cambia currentGameIndex, asegurar que GamesGridView lo refleje
    onCurrentGameIndexChanged: {
        if (!isRestoringState && gamesGridView.currentIndex !== currentGameIndex) {
            console.log("Syncing grid index to:", currentGameIndex)
            gamesGridView.currentIndex = currentGameIndex
        }
    }
}

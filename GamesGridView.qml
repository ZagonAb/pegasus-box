import QtQuick 2.15
import SortFilterProxyModel 0.2
import QtGraphicalEffects 1.12
import QtQml 2.15
import QtQuick.Layouts 1.15
import "utils.js" as Utils

FocusScope {
    id: gamesGridView

    property int currentIndex: 0
    property int columns: 4
    property int rows: 3

    // Propiedad para detectar cambios en la colección
    property var currentCollection: root.currentCollection

    property var currentFilteredGame: {
        if (gamesFilter.filteredModel && currentIndex >= 0 &&
            currentIndex < gamesFilter.filteredModel.count) {
            return gamesFilter.filteredModel.get(currentIndex)
            }
            return null
    }

    signal currentGameChanged(var game)

    GamesFilter {
        id: gamesFilter
        sourceModel: root.currentCollection ? root.currentCollection.games : null
    }

    // Fondo del panel
    Rectangle {
        id: panelBackground
        anchors.fill: parent
        color: panelColor
        radius: vpx(8)
        border.width: vpx(2)
        border.color: focus ? accentColor : borderColor

        // Efecto de sombra
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: vpx(4)
            radius: vpx(12)
            samples: 25
            color: "#40000000"
        }

        // Transición suave del borde
        Behavior on border.color {
            ColorAnimation { duration: 200 }
        }
    }

    // Título del panel con nombre de colección
    Text {
        id: panelTitle
        text: root.currentCollection ? root.currentCollection.name.toUpperCase() : "GAMES"
        color: accentColor
        font.family: condensedFontFamily
        font.pixelSize: vpx(24)
        font.bold: true
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: vpx(20)
        }
    }

    // Contenedor principal con RowLayout para separar grid y scrollbar
    Item {
        anchors {
            top: panelTitle.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: vpx(20)
            topMargin: vpx(30)
        }

        RowLayout {
            id: mainLayout
            anchors.fill: parent
            spacing: vpx(8)

            // Grid de juegos (toma todo el espacio disponible)
            GridView {
                id: gamesGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: width / columns
                cellHeight: cellWidth * 1.4

                model: gamesFilter.filteredModel  // Usar el modelo filtrado
                currentIndex: gamesGridView.currentIndex

                // Forzar que el juego actual sea visible
                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < gamesFilter.filteredModel.count) {
                        positionViewAtIndex(currentIndex, GridView.Contain)
                    }
                }

                delegate: Item {
                    width: gamesGrid.cellWidth
                    height: gamesGrid.cellHeight

                    // Propiedad para determinar si este item es el actual
                    readonly property bool isCurrent: index === gamesGrid.currentIndex
                    readonly property bool panelHasFocus: {
                        if (parent) {
                            return parent.focus
                        }
                        return false
                    }

                    Rectangle {
                        id: gameItem
                        width: parent.width - vpx(10)
                        height: parent.height - vpx(10)
                        anchors.centerIn: parent

                        color: {
                            // Verificar si este item es el actual
                            if (isCurrent) {
                                // Si el panel de juegos tiene foco global, mostrar azul
                                if (root.focusedPanel === "games") {
                                    return accentColor
                                } else {
                                    // Si otro panel tiene foco, mostrar color de borde
                                    return borderColor
                                }
                            }

                            // Hover solo si el mouse está sobre y no es current
                            if (mouseArea.containsMouse && mouseArea.pressed === false) {
                                return "#333333"
                            }

                            return "transparent"
                        }

                        radius: vpx(6)

                        // Transición suave del color
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        Column {
                            width: parent.width
                            spacing: vpx(10)

                            // Imagen del juego
                            Rectangle {
                                width: parent.width
                                height: width * 0.75
                                radius: vpx(4)
                                color: "#222"

                                Image {
                                    id: gameImage
                                    anchors.fill: parent
                                    anchors.margins: vpx(2)
                                    source: modelData.assets.boxFront || modelData.assets.logo || ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true

                                    Rectangle {
                                        anchors.fill: parent
                                        color: "#333"
                                        visible: gameImage.status !== Image.Ready

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.title ? modelData.title.substring(0, 2).toUpperCase() : "??"
                                            color: textColor
                                            font.family: condensedFontFamily
                                            font.pixelSize: vpx(32)
                                            font.bold: true
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: modelData.favorite
                                    width: vpx(24)
                                    height: vpx(24)
                                    radius: width / 2
                                    color: "#ffcc00"
                                    anchors {
                                        top: parent.top
                                        right: parent.right
                                        margins: vpx(5)
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "★"
                                        color: "#000"
                                        font.pixelSize: vpx(14)
                                        font.bold: true
                                    }
                                }
                            }

                            // Título del juego
                            Text {
                                id: gameTitle
                                width: parent.width
                                text: modelData.title ? Utils.cleanGameTitle(modelData.title) : "Select a game"
                                color: isCurrent ? "#ffffff" : textColor
                                font.family: fontFamily
                                font.pixelSize: vpx(14)
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                maximumLineCount: 2
                                wrapMode: Text.WordWrap

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }
                        }

                        // Mouse/touch area
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                root.selectGameWithMouse(index)
                            }

                            onDoubleClicked: {
                                if (root.currentGame) {
                                    root.launchCurrentGame()
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: scrollBar
                Layout.preferredWidth: vpx(6)
                Layout.fillHeight: true
                radius: width / 2
                color: "#555"
                opacity: gamesGrid.moving || gamesGrid.flicking ? 0.8 : 0.3
                visible: gamesGrid.contentHeight > gamesGrid.height

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                Rectangle {
                    id: scrollHandle
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: Math.max(vpx(30), scrollBar.height * gamesGrid.visibleArea.heightRatio)

                    y: Math.min(
                        Math.max(
                            0,
                            gamesGrid.visibleArea.yPosition * scrollBar.height
                        ),
                        scrollBar.height - scrollHandle.height
                    )

                    radius: width / 2
                    color: accentColor
                }
            }
        }
    }

    // Contador de juegos
    Text {
        id: gamesCount
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: vpx(20)
        }
        text: gamesFilter.filteredModel.count + " GAMES"
        color: secondaryTextColor
        font.family: condensedFontFamily
        font.pixelSize: vpx(14)
    }

    // Navegación con teclado
    Keys.onPressed: {
        if (api.keys.isAccept(event)) {
            event.accepted = true
            if (root.currentGame) root.launchCurrentGame()
        }
        else if (api.keys.isCancel(event)) {
            event.accepted = true
            root.switchToCollectionsPanel()
        }
        else if (event.key === Qt.Key_Left) {
            event.accepted = true
            if (currentIndex % columns === 0 && currentIndex < columns) {
                root.switchToCollectionsPanel()
            } else if (currentIndex > 0) {
                currentIndex--
                root.currentGameIndex = currentIndex
                gamesGrid.forceLayout()
            }
        }
        else if (event.key === Qt.Key_Right) {
            event.accepted = true
            if (currentIndex < gamesFilter.filteredModel.count - 1) {
                currentIndex++
                root.currentGameIndex = currentIndex
                gamesGrid.forceLayout()
            }
        }
        else if (event.key === Qt.Key_Up) {
            event.accepted = true
            if (currentIndex - columns >= 0) {
                currentIndex -= columns
                root.currentGameIndex = currentIndex
                gamesGrid.forceLayout()
            }
        }
        else if (event.key === Qt.Key_Down) {
            event.accepted = true
            if (currentIndex + columns < gamesFilter.filteredModel.count) {
                currentIndex += columns
                root.currentGameIndex = currentIndex
                gamesGrid.forceLayout()
            }
        }
        else if (api.keys.isNextPage(event)) {
            event.accepted = true
            nextPage()
        }
        else if (api.keys.isPrevPage(event)) {
            event.accepted = true
            previousPage()
        }
    }

    // Detectar cuando cambia la colección
    onCurrentCollectionChanged: {
        console.log("GamesGridView: Collection changed, resetting filter")
        if (currentCollection) {
            // Resetear el filtro
            gamesFilter.resetFilter()
            currentIndex = 0
            root.currentGameIndex = 0
            gamesGrid.forceLayout()
        }
    }

    Connections {
        target: root
        enabled: !root.isRestoringState

        function onCurrentGameIndexChanged() {
            console.log("Root game index changed to:", root.currentGameIndex)

            // Actualizar root.currentGame basado en el modelo filtrado
            if (gamesFilter.filteredModel &&
                root.currentGameIndex >= 0 &&
                root.currentGameIndex < gamesFilter.filteredModel.count) {

                if (currentIndex !== root.currentGameIndex) {
                    console.log("Updating grid index to:", root.currentGameIndex)
                    currentIndex = root.currentGameIndex
                }

                // Forzar actualización del juego actual
                root.currentGame = gamesFilter.filteredModel.get(root.currentGameIndex)
                }
        }
    }

    function resetAllFilters() {
        console.log("GamesGridView: Resetting all filters")
        resetFilter()
    }

    function updateFilter(filterType) {
        console.log("GamesGridView: Updating filter to", filterType)
        gamesFilter.updateFilter(filterType)

        // Resetear índice al cambiar filtro
        currentIndex = 0
        root.currentGameIndex = 0

        // Actualizar el juego actual basado en el nuevo filtro
        if (gamesFilter.filteredModel && gamesFilter.filteredModel.count > 0) {
            root.currentGame = gamesFilter.filteredModel.get(0)
        } else {
            root.currentGame = null
        }

        // Asegurar visibilidad
        ensureCurrentVisible()
    }

    function updateSearch(searchText) {
        console.log("GamesGridView: Updating search to", searchText)
        gamesFilter.updateSearch(searchText)

        // Resetear índice al buscar
        currentIndex = 0
        root.currentGameIndex = 0

        // Asegurar visibilidad
        ensureCurrentVisible()
    }

    function resetFilter() {
        console.log("GamesGridView: Resetting filter")
        gamesFilter.resetFilter()

        // Resetear índice
        currentIndex = 0
        root.currentGameIndex = 0

        // Asegurar visibilidad
        ensureCurrentVisible()
    }

    // Función para forzar visibilidad del índice actual
    function ensureCurrentVisible() {
        if (currentIndex >= 0 && currentIndex < gamesFilter.filteredModel.count) {
            gamesGrid.positionViewAtIndex(currentIndex, GridView.Contain)
        }
    }

    // Funciones de navegación por páginas
    function nextPage() {
        var nextIndex = currentIndex + (columns * rows)
        if (nextIndex < gamesFilter.filteredModel.count) {
            currentIndex = nextIndex
            root.currentGameIndex = currentIndex
        } else {
            currentIndex = gamesFilter.filteredModel.count - 1
            root.currentGameIndex = currentIndex
        }
    }

    function previousPage() {
        var prevIndex = currentIndex - (columns * rows)
        if (prevIndex >= 0) {
            currentIndex = prevIndex
            root.currentGameIndex = currentIndex
        } else {
            currentIndex = 0
            root.currentGameIndex = currentIndex
        }
    }

    Component.onCompleted: {
        console.log("GamesGridView loaded with filter system")
    }
}

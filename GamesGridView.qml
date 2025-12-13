import QtQuick 2.15
import SortFilterProxyModel 0.2
import QtGraphicalEffects 1.12
import QtQml 2.15

FocusScope {
    id: gamesGridView

    property int currentIndex: 0
    property int columns: 4
    property int rows: 3

    // Propiedad para detectar cambios en la colección
    property var currentCollection: root.currentCollection

    // Proxy model para ordenar/filtrar
    SortFilterProxyModel {
        id: gamesProxyModel
        sourceModel: root.currentCollection ? root.currentCollection.games : null
        sorters: RoleSorter {
            roleName: "title"
            sortOrder: Qt.AscendingOrder
        }
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

    // Grid de juegos
    GridView {
        id: gamesGrid
        anchors {
            top: panelTitle.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: vpx(20)
            topMargin: vpx(30)
        }
        clip: true
        cellWidth: width / columns
        cellHeight: cellWidth * 1.4 // Para incluir texto debajo

        model: gamesProxyModel
        currentIndex: gamesGridView.currentIndex

        // Forzar que el juego actual sea visible
        onCurrentIndexChanged: {
            if (currentIndex >= 0 && currentIndex < gamesProxyModel.count) {
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
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true

                            // Placeholder si no hay imagen
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

                        // Indicador de favorito
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
                        text: modelData.title
                        // Texto blanco si es current (con o sin foco), color normal si no
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

                    // Efecto hover - solo si no es el item actual
                    onEntered: {
                        // El color se maneja en la lógica de color del Rectangle
                    }

                    onExited: {
                        // El color se maneja en la lógica de color del Rectangle
                    }

                    // Doble click para lanzar
                    onDoubleClicked: {
                        if (root.currentGame) {
                            root.launchCurrentGame()
                        }
                    }
                }
            }
        }

        // Scrollbar
        Rectangle {
            id: scrollBar
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }
            width: vpx(6)
            radius: width / 2
            color: "#555"
            opacity: gamesGrid.moving || gamesGrid.flicking ? 0.8 : 0.3
            visible: gamesGrid.contentHeight > gamesGrid.height

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: Math.max(vpx(30), gamesGrid.height * gamesGrid.visibleArea.heightRatio)
                y: gamesGrid.visibleArea.yPosition * gamesGrid.height
                radius: width / 2
                color: accentColor
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
        text: gamesProxyModel.count + " GAMES"
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
            // Volver al panel de colecciones
            root.switchToCollectionsPanel()
        }
        else if (event.key === Qt.Key_Left) {
            event.accepted = true
            // Si estamos en el índice 0 (primera columna), volver a collections
            if (currentIndex % columns === 0 && currentIndex < columns) {
                root.switchToCollectionsPanel()
            } else if (currentIndex > 0) {
                currentIndex--
                root.currentGameIndex = currentIndex
                // Forzar actualización de hover
                gamesGrid.forceLayout()
            }
        }
        else if (event.key === Qt.Key_Right) {
            event.accepted = true
            if (currentIndex < gamesProxyModel.count - 1) {
                currentIndex++
                root.currentGameIndex = currentIndex
                // Forzar actualización de hover
                gamesGrid.forceLayout()
            }
        }
        else if (event.key === Qt.Key_Up) {
            event.accepted = true
            if (currentIndex - columns >= 0) {
                currentIndex -= columns
                root.currentGameIndex = currentIndex
                // Forzar actualización de hover
                gamesGrid.forceLayout()
            }
        }
        else if (event.key === Qt.Key_Down) {
            event.accepted = true
            if (currentIndex + columns < gamesProxyModel.count) {
                currentIndex += columns
                root.currentGameIndex = currentIndex
                // Forzar actualización de hover
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

    // Detectar cuando cambia la colección - RESET a índice 0
    onCurrentCollectionChanged: {
        console.log("Collection changed in grid, resetting to index 0")
        if (currentCollection) {
            currentIndex = 0
            // Asegurar que root también se resetee
            root.currentGameIndex = 0
            // Forzar actualización visual
            gamesGrid.forceLayout()
        }
    }

    // Sincronizar con root.currentGameIndex usando Connections
    Connections {
        target: root
        enabled: !root.isRestoringState

        function onCurrentGameIndexChanged() {
            console.log("Root game index changed to:", root.currentGameIndex)

            // Validar que tenemos una colección y el índice es válido
            if (currentCollection &&
                root.currentGameIndex >= 0 &&
                root.currentGameIndex < gamesProxyModel.count) {

                // Solo actualizar si es diferente
                if (currentIndex !== root.currentGameIndex) {
                    console.log("Updating grid index to:", root.currentGameIndex)
                    currentIndex = root.currentGameIndex
                }
                }
        }

        function onIsRestoringStateChanged() {
            if (!root.isRestoringState &&
                currentCollection &&
                root.currentGameIndex >= 0 &&
                root.currentGameIndex < gamesProxyModel.count &&
                currentIndex !== root.currentGameIndex) {

                console.log("Restoration finished, syncing grid to index:", root.currentGameIndex)
                currentIndex = root.currentGameIndex
                }
        }
    }

    // Forzar visibilidad del item seleccionado cuando se carga
    Component.onCompleted: {
        console.log("GamesGridView loaded, currentIndex:", currentIndex)

        // Sincronizar con root.currentGameIndex después de cargar
        if (!root.isRestoringState &&
            currentCollection &&
            root.currentGameIndex >= 0 &&
            root.currentGameIndex < gamesProxyModel.count &&
            currentIndex !== root.currentGameIndex) {

            console.log("Component loaded, syncing to root index:", root.currentGameIndex)
            currentIndex = root.currentGameIndex
            }

            // Forzar visibilidad
            if (currentIndex >= 0 && currentIndex < gamesProxyModel.count) {
                gamesGrid.positionViewAtIndex(currentIndex, GridView.Contain)
            }
    }

    // Función para sincronizar manualmente (llamada desde theme.qml)
    function syncWithRootIndex() {
        if (!root.isRestoringState &&
            currentCollection &&
            root.currentGameIndex >= 0 &&
            root.currentGameIndex < gamesProxyModel.count &&
            currentIndex !== root.currentGameIndex) {

            console.log("Manual sync: Setting grid index to", root.currentGameIndex)
            currentIndex = root.currentGameIndex
            return true
            }
            return false
    }

    // Función para forzar visibilidad del índice actual
    function ensureCurrentVisible() {
        if (currentIndex >= 0 && currentIndex < gamesProxyModel.count) {
            gamesGrid.positionViewAtIndex(currentIndex, GridView.Contain)
        }
    }

    // Funciones de navegación por páginas
    function nextPage() {
        var nextIndex = currentIndex + (columns * rows)
        if (nextIndex < gamesProxyModel.count) {
            currentIndex = nextIndex
            root.currentGameIndex = currentIndex
        } else {
            currentIndex = gamesProxyModel.count - 1
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
}

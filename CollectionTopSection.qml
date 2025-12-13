import QtQuick 2.15
import QtQml 2.15
import QtGraphicalEffects 1.12
import "utils.js" as Utils

Item {
    id: collectionTopSection
    width: parent.width
    height: vpx(120)  // ALTURA FIJA: barra búsqueda + menú + espaciado
    z: 10

    // Propiedades públicas
    property string currentFilter: "All Games"
    property string searchText: ""

    // Nueva propiedad para controlar estado de filtros disponibles
    property bool canFilterFavorites: false
    property bool canFilterLastPlayed: false

    // Señales para comunicación
    signal filterChanged(string filterType)
    signal searchRequested(string text)

    // Lista de filtros disponibles (removido "Platforms")
    property var filterOptions: [
        "All Games",
        "Favorites",
        "Last Played",
        "Top Rating",
        "Year",
        "Categories"
    ]

    // Propiedad para controlar visibilidad del menú desplegable
    property bool dropdownVisible: false

    Column {
        anchors.fill: parent
        spacing: vpx(10)  // ESPACIADO CONSISTENTE

        // BARRA DE BÚSQUEDA
        Rectangle {
            id: searchBar
            width: parent.width
            height: vpx(50)
            radius: vpx(6)
            color: "#222"
            border.width: vpx(1)
            border.color: borderColor
            z: 30

            Row {
                anchors.fill: parent
                anchors.margins: vpx(10)
                spacing: vpx(10)

                // Icono de búsqueda
                Text {
                    text: "🔍"
                    color: secondaryTextColor
                    font.pixelSize: vpx(20)
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Campo de texto
                TextInput {
                    id: searchInput
                    width: parent.width - vpx(50)
                    anchors.verticalCenter: parent.verticalCenter
                    text: searchText
                    color: textColor
                    font.family: fontFamily
                    font.pixelSize: vpx(16)
                    clip: true
                    selectByMouse: true

                    // Placeholder
                    Text {
                        text: "Search games..."
                        color: secondaryTextColor
                        font.family: fontFamily
                        font.pixelSize: vpx(16)
                        visible: !searchInput.text && !searchInput.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    onTextChanged: {
                        collectionTopSection.searchText = text
                        searchTimer.restart()
                    }

                    onAccepted: {
                        searchTimer.stop()
                        searchRequested(text)
                    }

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Escape) {
                            text = ""
                            searchTimer.stop()
                            searchRequested("")
                            event.accepted = true
                        }
                    }
                }

                // Botón para limpiar búsqueda
                Text {
                    id: clearButton
                    text: "✕"
                    color: secondaryTextColor
                    font.pixelSize: vpx(18)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: searchInput.text.length > 0

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onEntered: clearButton.color = accentColor
                        onExited: clearButton.color = secondaryTextColor

                        onClicked: {
                            searchInput.text = ""
                            searchInput.focus = false
                            searchTimer.stop()
                            searchRequested("")
                        }
                    }
                }
            }

            // Efecto de foco
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: vpx(2)
                border.color: accentColor
                opacity: searchInput.activeFocus ? 0.5 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }
        }

        // MENU DESPLEGABLE DE FILTROS
        Rectangle {
            id: filterMenu
            width: parent.width
            height: vpx(50)
            radius: vpx(6)
            color: "#222"
            border.width: vpx(1)
            border.color: dropdownVisible ? accentColor : borderColor
            z: 40

            // Contenido visible del menú (siempre visible)
            Row {
                anchors.fill: parent
                anchors.margins: vpx(10)
                spacing: vpx(10)

                // Icono de filtro
                Text {
                    text: "⚙️"
                    color: secondaryTextColor
                    font.pixelSize: vpx(20)
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Texto del filtro seleccionado
                Text {
                    id: selectedFilterText
                    width: parent.width - vpx(80)
                    text: currentFilter
                    color: textColor
                    font.family: condensedFontFamily
                    font.pixelSize: vpx(16)
                    font.bold: true
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Flecha indicadora con animación
                Text {
                    id: arrowIcon
                    text: "▼"
                    color: secondaryTextColor
                    font.pixelSize: vpx(12)
                    anchors.verticalCenter: parent.verticalCenter

                    RotationAnimator {
                        target: arrowIcon
                        from: 0
                        to: 180
                        duration: 200
                        running: dropdownVisible
                    }

                    RotationAnimator {
                        target: arrowIcon
                        from: 180
                        to: 0
                        duration: 200
                        running: !dropdownVisible
                    }
                }
            }

            // MouseArea para abrir/cerrar el menú
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    if (!dropdownVisible) {
                        filterMenu.border.color = accentColor
                    }
                }
                onExited: {
                    if (!dropdownVisible) {
                        filterMenu.border.color = borderColor
                    }
                }

                onClicked: {
                    dropdownVisible = !dropdownVisible
                }
            }
        }
    }

    // OVERLAY Y MENÚ DESPLEGABLE - AHORA FUERA DEL COLUMN
    Item {
        id: dropdownContainer
        width: parent.width
        height: dropdownVisible ? parent.parent.height : 0
        anchors.top: parent.top
        anchors.topMargin: vpx(120)  // Altura total del CollectionTopSection
        visible: dropdownVisible
        z: 100  // Muy alto, por encima de todo

        // Fondo semitransparente para el área del menú
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.4

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    dropdownVisible = false
                }
            }
        }

        // El menú desplegable real
        Rectangle {
            id: dropdownPopup
            width: parent.width
            height: Math.min(filterList.height + vpx(20), vpx(400))
            radius: vpx(6)
            color: panelColor
            border.width: vpx(1)
            border.color: accentColor
            clip: true

            anchors {
                top: parent.top
                left: parent.left
            }

            // Sombra para el popup
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: vpx(4)
                radius: vpx(12)
                samples: 25
                color: "#80000000"
                transparentBorder: true
            }

            // Lista de opciones del menú
            ListView {
                id: filterList
                width: parent.width - vpx(2)
                height: Math.min(contentHeight, vpx(400) - vpx(20))
                anchors.centerIn: parent
                clip: true
                interactive: true
                boundsBehavior: Flickable.StopAtBounds

                model: filterOptions

                delegate: Item {
                    width: filterList.width
                    height: vpx(50)

                    readonly property bool isFavoriteFilter: modelData === "Favorites"
                    readonly property bool isLastPlayedFilter: modelData === "Last Played"
                    readonly property bool isDisabled: (isFavoriteFilter && !canFilterFavorites) ||
                    (isLastPlayedFilter && !canFilterLastPlayed)

                    Rectangle {
                        id: itemBackground
                        anchors.fill: parent
                        anchors.margins: vpx(2)
                        radius: vpx(4)
                        color: mouseArea.containsMouse && !isDisabled ? "#333" : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: vpx(15)
                            anchors.rightMargin: vpx(15)
                            spacing: vpx(15)

                            // Icono según el filtro
                            Text {
                                text: getFilterIcon(modelData)
                                color: {
                                    if (isDisabled) return "#666"
                                        if (currentFilter === modelData) return accentColor
                                            return secondaryTextColor
                                }
                                font.pixelSize: vpx(18)
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: isDisabled ? 0.5 : 1.0
                            }

                            // Texto del filtro
                            Text {
                                text: modelData
                                color: {
                                    if (isDisabled) return "#666"
                                        if (currentFilter === modelData) return accentColor
                                            return textColor
                                }
                                font.family: fontFamily
                                font.pixelSize: vpx(16)
                                font.bold: currentFilter === modelData && !isDisabled
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: isDisabled ? 0.5 : 1.0

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            // Indicador de selección actual
                            Text {
                                text: "✓"
                                color: accentColor
                                font.pixelSize: vpx(16)
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                                visible: currentFilter === modelData && !isDisabled
                            }

                            // Indicador de deshabilitado
                            Text {
                                text: "—"
                                color: "#666"
                                font.pixelSize: vpx(16)
                                anchors.verticalCenter: parent.verticalCenter
                                visible: isDisabled
                            }
                        }

                        // Separador
                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                margins: vpx(10)
                            }
                            height: 1
                            color: "#333"
                            visible: index < filterOptions.length - 1
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !isDisabled

                        onClicked: {
                            if (!isDisabled) {
                                currentFilter = modelData
                                filterChanged(modelData)
                                dropdownVisible = false
                            }
                        }

                        onEntered: {
                            if (!isDisabled) {
                                itemBackground.color = "#333"
                            }
                        }
                        onExited: {
                            itemBackground.color = "transparent"
                        }
                    }
                }

                // Scrollbar para la lista
                Rectangle {
                    id: dropdownScrollBar
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        rightMargin: vpx(2)
                    }
                    width: vpx(4)
                    radius: width / 2
                    color: "#555"
                    opacity: filterList.moving || filterList.flicking ? 0.8 : 0.3
                    visible: filterList.contentHeight > filterList.height

                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    Rectangle {
                        id: dropdownScrollHandle
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        height: Math.max(vpx(30), dropdownScrollBar.height * filterList.visibleArea.heightRatio)
                        y: filterList.visibleArea.yPosition * dropdownScrollBar.height
                        radius: width / 2
                        color: accentColor
                    }
                }
            }
        }
    }

    // Timer para búsqueda con debounce
    Timer {
        id: searchTimer
        interval: 500
        onTriggered: searchRequested(searchText)
    }

    // Función para obtener iconos según el filtro
    function getFilterIcon(filterName) {
        switch(filterName) {
            case "All Games": return "🎮"
            case "Favorites": return "⭐"
            case "Last Played": return "🕒"
            case "Top Rating": return "🏆"
            case "Year": return "📅"
            case "Categories": return "🏷️"
            default: return "⚙️"
        }
    }

    // Funciones públicas
    function setFilter(filterType) {
        if (filterOptions.includes(filterType)) {
            currentFilter = filterType
            filterChanged(filterType)
        }
    }

    function resetFilter() {
        currentFilter = "All Games"
    }

    function updateFilterAvailability(collection) {
        if (!collection || !collection.games) {
            canFilterFavorites = false
            canFilterLastPlayed = false
            return
        }

        // Verificar si hay juegos favoritos
        var hasFavorites = false
        var hasLastPlayed = false

        for (var i = 0; i < collection.games.count; i++) {
            var game = collection.games.get(i)
            if (game) {
                if (game.favorite) hasFavorites = true
                    if (game.lastPlayed && game.lastPlayed.getTime) {
                        // Si tiene fecha de última vez jugado y no es una fecha inválida
                        if (!isNaN(game.lastPlayed.getTime())) {
                            hasLastPlayed = true
                        }
                    }
            }

            // Si ya encontramos ambos, podemos salir
            if (hasFavorites && hasLastPlayed) break
        }

        canFilterFavorites = hasFavorites
        canFilterLastPlayed = hasLastPlayed

        console.log("Filter availability - Favorites:", canFilterFavorites, "Last Played:", canFilterLastPlayed)
    }

    function clearSearch() {
        searchInput.text = ""
        searchText = ""
        searchTimer.stop()
        searchRequested("")
    }

    function focusSearch() {
        searchInput.forceActiveFocus()
    }

    function toggleDropdown() {
        dropdownVisible = !dropdownVisible
    }

    // Cerrar menú desplegable cuando se hace clic fuera
    MouseArea {
        anchors.fill: parent
        enabled: dropdownVisible
        onClicked: {
            if (dropdownVisible) {
                dropdownVisible = false
            }
        }
    }

    // Manejar teclado
    Keys.onPressed: {
        if (event.key === Qt.Key_Up && dropdownVisible) {
            event.accepted = true
            navigateMenu(-1)
        } else if (event.key === Qt.Key_Down && dropdownVisible) {
            event.accepted = true
            navigateMenu(1)
        } else if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return) && dropdownVisible) {
            event.accepted = true
            selectCurrentMenuItem()
        } else if (event.key === Qt.Key_Escape) {
            if (dropdownVisible) {
                event.accepted = true
                dropdownVisible = false
            } else if (searchInput.activeFocus) {
                event.accepted = true
                clearSearch()
            }
        } else if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            event.accepted = true
            focusSearch()
        }
    }

    function navigateMenu(direction) {
        var currentIndex = filterOptions.indexOf(currentFilter)
        var newIndex = currentIndex + direction

        // Buscar el siguiente filtro disponible
        while (newIndex >= 0 && newIndex < filterOptions.length) {
            var filterName = filterOptions[newIndex]
            var isFavoriteFilter = filterName === "Favorites"
            var isLastPlayedFilter = filterName === "Last Played"

            var isDisabled = (isFavoriteFilter && !canFilterFavorites) ||
            (isLastPlayedFilter && !canFilterLastPlayed)

            if (!isDisabled) {
                currentFilter = filterName
                filterList.positionViewAtIndex(newIndex, ListView.Contain)
                return
            }

            newIndex += direction
        }
    }

    function selectCurrentMenuItem() {
        var isFavoriteFilter = currentFilter === "Favorites"
        var isLastPlayedFilter = currentFilter === "Last Played"

        var isDisabled = (isFavoriteFilter && !canFilterFavorites) ||
        (isLastPlayedFilter && !canFilterLastPlayed)

        if (!isDisabled) {
            filterChanged(currentFilter)
            dropdownVisible = false
        }
    }

    // ... añadir esta función pública ...

    function onCollectionChanged(collection) {
        console.log("CollectionTopSection: Collection changed to", collection ? collection.name : "null")

        // Actualizar disponibilidad de filtros
        updateFilterAvailability(collection)

        // Resetear siempre a "All Games" cuando cambia la colección
        resetFilter()

        // Limpiar búsqueda
        clearSearch()
    }

    // Inicializar
    Component.onCompleted: {
        console.log("CollectionTopSection loaded with", filterOptions.length, "filters")
    }
}

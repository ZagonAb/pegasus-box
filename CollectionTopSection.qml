import QtQuick 2.15
import QtQml 2.15
import QtGraphicalEffects 1.12
import "utils.js" as Utils

Item {
    id: collectionTopSection
    width: parent.width
    height: vpx(120)
    z: 10

    // Propiedades públicas
    property string currentFilter: "All Games"
    property string searchText: ""
    property string searchField: "title" // Campo de búsqueda activo

    // Estado de filtros disponibles
    property bool canFilterFavorites: false
    property bool canFilterLastPlayed: false

    // Indicador de búsqueda global
    property bool isGlobalSearch: false
    property bool isSearching: false // Nuevo: indica si está buscando

    // Señales
    signal filterChanged(string filterType)
    signal searchRequested(string text, string field)

    // Opciones de filtro (Categories eliminado)
    property var filterOptions: [
        "All Games",
        "Favorites",
        "Last Played",
        "Top Rating",
        "Year"
    ]

    // Opciones de búsqueda con imágenes SVG
    property var searchFieldOptions: [
        {name: "Title", value: "title", icon: "assets/images/icons/allgames.svg"},
        {name: "Developer", value: "developer", icon: "assets/images/icons/developer.svg"},
        {name: "Genre", value: "genre", icon: "assets/images/icons/genre.svg"},
        {name: "Publisher", value: "publisher", icon: "assets/images/icons/publisher.svg"},
        {name: "Tags", value: "tags", icon: "assets/images/icons/tag.svg"},
        {name: "Sort Name", value: "sortBy", icon: "assets/images/icons/sortby.svg"}
    ]

    property bool dropdownVisible: false
    property bool searchFieldDropdownVisible: false

    Column {
        anchors.fill: parent
        spacing: vpx(10)

        // BARRA DE BÚSQUEDA MEJORADA CON ANIMACIÓN
        Rectangle {
            id: searchBar
            width: parent.width
            height: vpx(50)
            radius: vpx(6)
            color: "#222"
            border.width: vpx(2)
            border.color: isGlobalSearch ? accentColor : borderColor
            z: 30

            // Animación de altura al expandirse
            Behavior on height {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            // Animación de borde
            Behavior on border.width {
                NumberAnimation { duration: 200 }
            }

            // Estado de foco del input
            property bool inputHasFocus: searchInput.activeFocus

            // Ajustar altura según el foco
            states: [
                State {
                    name: "focused"
                    when: searchBar.inputHasFocus
                    PropertyChanges {
                        target: searchBar
                        height: vpx(55)
                        border.width: vpx(3)
                    }
                },
                State {
                    name: "normal"
                    when: !searchBar.inputHasFocus
                    PropertyChanges {
                        target: searchBar
                        height: vpx(50)
                        border.width: vpx(2)
                    }
                }
            ]

            transitions: [
                Transition {
                    from: "normal"
                    to: "focused"
                    NumberAnimation {
                        properties: "height,border.width"
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                },
                Transition {
                    from: "focused"
                    to: "normal"
                    NumberAnimation {
                        properties: "height,border.width"
                        duration: 250
                        easing.type: Easing.InCubic
                    }
                }
            ]

            // Indicador visual de búsqueda global
            Rectangle {
                visible: isGlobalSearch
                anchors.fill: parent
                radius: parent.radius
                color: accentColor
                opacity: 0.1

                // Animación de "pulsación" para indicar búsqueda activa
                SequentialAnimation on opacity {
                    running: isGlobalSearch && isSearching
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.1; to: 0.2; duration: 1000; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.2; to: 0.1; duration: 1000; easing.type: Easing.InOutQuad }
                }
            }

            Item {
                anchors.fill: parent
                anchors.margins: vpx(10)

                Row {
                    id: searchRow
                    anchors.fill: parent
                    spacing: vpx(10)

                    // Menú desplegable de campo de búsqueda con animación
                    Rectangle {
                        id: searchFieldSelector
                        width: searchBar.inputHasFocus ? vpx(90) : vpx(120)
                        height: parent.height
                        radius: vpx(4)
                        color: searchFieldDropdownVisible ? "#333" : "#1a1a1a"
                        border.width: vpx(1)
                        border.color: searchFieldDropdownVisible ? accentColor : "#444"

                        // Animación suave al cambiar de tamaño
                        Behavior on width {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        // Animación de opacidad al achicarse
                        opacity: searchBar.inputHasFocus ? 0.7 : 1.0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: searchBar.inputHasFocus ? vpx(5) : vpx(15)

                            spacing: searchBar.inputHasFocus ? vpx(3) : vpx(6)

                            // Animación del spacing
                            Behavior on spacing {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }

                            // Icono del campo de búsqueda actual (reemplaza emoji con SVG)
                            Image {
                                id: searchFieldIcon
                                width: searchBar.inputHasFocus ? vpx(12) : vpx(14)
                                height: width
                                source: getCurrentSearchFieldIcon()
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                                anchors.verticalCenter: parent.verticalCenter

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on height {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            Text {
                                text: getCurrentSearchFieldName()
                                color: textColor
                                font.family: condensedFontFamily
                                font.pixelSize: searchBar.inputHasFocus ? vpx(11) : vpx(12)
                                font.bold: true
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                                width: searchBar.inputHasFocus ? vpx(50) : vpx(60)

                                // Animación de tamaño de fuente
                                Behavior on font.pixelSize {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                // Animación de ancho
                                Behavior on width {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            Text {
                                text: "▼"
                                color: secondaryTextColor
                                font.pixelSize: searchBar.inputHasFocus ? vpx(9) : vpx(10)
                                anchors.verticalCenter: parent.verticalCenter
                                rotation: searchFieldDropdownVisible ? 180 : 0

                                // Animación de tamaño de fuente
                                Behavior on font.pixelSize {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on rotation {
                                    NumberAnimation { duration: 200 }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: searchFieldDropdownVisible = !searchFieldDropdownVisible
                            onEntered: parent.border.color = accentColor
                            onExited: {
                                if (!searchFieldDropdownVisible) {
                                    parent.border.color = "#444"
                                }
                            }
                        }
                    }

                    // Separador vertical
                    Rectangle {
                        width: vpx(2)
                        height: parent.height * 0.6
                        color: borderColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Icono de búsqueda con animación (reemplaza emoji con SVG)
                    Image {
                        id: searchIcon
                        width: searchBar.inputHasFocus ? vpx(18) : vpx(15)
                        height: width
                        source: "assets/images/icons/search.svg"
                        fillMode: Image.PreserveAspectFit
                        anchors.verticalCenter: parent.verticalCenter
                        mipmap: true

                        // Cambiar color según modo de búsqueda
                        layer.enabled: true
                        layer.effect: ColorOverlay {
                            color: isGlobalSearch ? accentColor : secondaryTextColor
                            cached: true

                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }
                        }

                        // Animación de tamaño
                        Behavior on width {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on height {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }

                        scale: 1.0

                        // Animación al cambiar el ícono
                        Behavior on source {
                            SequentialAnimation {
                                NumberAnimation {
                                    target: searchIcon
                                    property: "scale"
                                    to: 0.7
                                    duration: 100
                                }
                                NumberAnimation {
                                    target: searchIcon
                                    property: "scale"
                                    to: 1.0
                                    duration: 100
                                }
                            }
                        }
                    }

                    // Contenedor para campo de texto y placeholder con animación de expansión
                    Item {
                        id: inputContainer
                        // Se expande cuando searchFieldSelector se achica
                        width: parent.width - searchFieldSelector.width - searchIcon.width - clearButton.width - vpx(10)
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter

                        // Animación de ancho al expandirse
                        Behavior on width {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }

                        // Campo de texto mejorado
                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            anchors.topMargin: vpx(2)
                            text: searchText
                            color: textColor
                            font.family: fontFamily
                            font.pixelSize: vpx(16)
                            clip: true
                            selectByMouse: true
                            verticalAlignment: TextInput.AlignVCenter

                            onTextChanged: {
                                collectionTopSection.searchText = text
                                isGlobalSearch = (text.trim() !== "")

                                if (text.trim() !== "") {
                                    isSearching = true
                                }

                                searchTimer.restart()
                            }

                            onAccepted: {
                                searchTimer.stop()
                                isSearching = true
                                searchRequested(text.trim(), searchField)
                            }

                            Keys.onPressed: {
                                if (event.key === Qt.Key_Escape) {
                                    text = ""
                                    searchTimer.stop()
                                    isGlobalSearch = false
                                    isSearching = false
                                    searchRequested("", searchField)
                                    event.accepted = true
                                }
                            }
                        }

                        // Placeholder dinámico con información
                        Text {
                            anchors.fill: parent
                            anchors.topMargin: vpx(2)
                            text: "Search by " + getCurrentSearchFieldName().toLowerCase()
                            color: secondaryTextColor
                            font.family: fontFamily
                            font.pixelSize: vpx(12)
                            visible: !searchInput.text && !searchInput.activeFocus
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        // Feedback visual mejorado al escribir
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: vpx(2)
                            color: accentColor
                            opacity: searchInput.activeFocus ? 0.8 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: 250 }
                            }

                            Behavior on height {
                                NumberAnimation { duration: 250 }
                            }

                            // Animación de ancho desde el centro
                            scale: searchInput.activeFocus ? 1.0 : 0.0
                            transformOrigin: Item.Center

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        // MouseArea para hacer clic en el área y dar foco
                        MouseArea {
                            anchors.fill: parent
                            onClicked: searchInput.forceActiveFocus()
                            enabled: !searchInput.activeFocus
                        }
                    }

                    // Botón para limpiar búsqueda
                    Item {
                        id: clearButton
                        width: vpx(30)
                        height: parent.height
                        visible: searchInput.text.length > 0

                        Text {
                            id: clearButtonText
                            anchors.centerIn: parent
                            text: "✕"
                            color: secondaryTextColor
                            font.pixelSize: vpx(18)

                            opacity: clearMouseArea.pressed ? 0.6 : 1.0

                            Behavior on opacity {
                                NumberAnimation { duration: 100 }
                            }

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                        MouseArea {
                            id: clearMouseArea
                            anchors.fill: parent
                            hoverEnabled: true

                            onEntered: clearButtonText.color = accentColor
                            onExited: clearButtonText.color = secondaryTextColor

                            onClicked: {
                                searchInput.text = ""
                                searchInput.focus = false
                                searchTimer.stop()
                                isGlobalSearch = false
                                isSearching = false
                                searchField = "title" // Resetear a title
                                searchRequested("", searchField)
                            }
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

            Behavior on border.color {
                ColorAnimation { duration: 200 }
            }
        }

        // MENÚ DE FILTROS
        Rectangle {
            id: filterMenu
            width: parent.width
            height: vpx(50)
            radius: vpx(6)
            color: "#222"
            border.width: vpx(1)
            border.color: dropdownVisible ? accentColor : borderColor
            z: 40
            opacity: isGlobalSearch ? 0.5 : 1.0

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            // Overlay de deshabilitado
            Rectangle {
                visible: isGlobalSearch
                anchors.fill: parent
                radius: parent.radius
                color: "#000000"
                opacity: 0.3
            }

            Row {
                anchors.fill: parent
                anchors.margins: vpx(10)
                spacing: vpx(10)

                // Icono de configuración (reemplaza emoji con SVG)
                Image {
                    id: settingsIcon
                    width: vpx(20)
                    height: width
                    source: "assets/images/icons/item.svg"
                    fillMode: Image.PreserveAspectFit
                    anchors.verticalCenter: parent.verticalCenter

                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: isGlobalSearch ? "#666" : secondaryTextColor
                        cached: true
                    }
                }

                Text {
                    id: selectedFilterText
                    width: parent.width - vpx(80)
                    text: isGlobalSearch ? "Global Search Active" : currentFilter
                    color: isGlobalSearch ? "#666" : textColor
                    font.family: condensedFontFamily
                    font.pixelSize: vpx(16)
                    font.bold: true
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: arrowIcon
                    text: "▼"
                    color: isGlobalSearch ? "#666" : secondaryTextColor
                    font.pixelSize: vpx(12)
                    anchors.verticalCenter: parent.verticalCenter

                    rotation: dropdownVisible && !isGlobalSearch ? 180 : 0

                    Behavior on rotation {
                        NumberAnimation { duration: 200 }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                enabled: !isGlobalSearch

                onEntered: {
                    if (!dropdownVisible && !isGlobalSearch) {
                        filterMenu.border.color = accentColor
                    }
                }
                onExited: {
                    if (!dropdownVisible && !isGlobalSearch) {
                        filterMenu.border.color = borderColor
                    }
                }

                onClicked: {
                    if (!isGlobalSearch) {
                        dropdownVisible = !dropdownVisible
                    }
                }
            }
        }
    }

    // MENÚ DESPLEGABLE DE CAMPO DE BÚSQUEDA
    Item {
        id: searchFieldDropdownContainer
        width: vpx(180)
        height: searchFieldDropdownVisible ? vpx(300) : 0
        anchors.top: parent.top
        anchors.topMargin: vpx(50)
        anchors.left: parent.left

        visible: searchFieldDropdownVisible
        z: 150

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0
        }

        Rectangle {
            id: searchFieldDropdownPopup
            width: parent.width
            height: Math.min(searchFieldList.contentHeight + vpx(20), vpx(300))
            radius: vpx(6)
            color: panelColor
            border.width: vpx(1)
            border.color: accentColor
            clip: true

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: vpx(4)
                radius: vpx(12)
                samples: 25
                color: "#80000000"
                transparentBorder: true
            }

            ListView {
                id: searchFieldList
                width: parent.width - vpx(2)
                height: contentHeight
                anchors.centerIn: parent
                clip: true
                interactive: false

                model: searchFieldOptions

                delegate: Item {
                    width: searchFieldList.width
                    height: vpx(45)

                    Rectangle {
                        id: itemBg
                        anchors.fill: parent
                        anchors.margins: vpx(2)
                        radius: vpx(4)
                        color: mouseArea.containsMouse ? "#333" : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: vpx(15)
                            anchors.rightMargin: vpx(15)
                            spacing: vpx(12)

                            // Icono del campo de búsqueda (reemplaza emoji con SVG)
                            Image {
                                width: vpx(16)
                                height: width
                                source: modelData.icon
                                fillMode: Image.PreserveAspectFit
                                anchors.verticalCenter: parent.verticalCenter
                                mipmap: true

                                layer.enabled: true
                                layer.effect: ColorOverlay {
                                    color: searchField === modelData.value ? accentColor : secondaryTextColor
                                    cached: true
                                }
                            }

                            Text {
                                text: modelData.name
                                color: searchField === modelData.value ? accentColor : textColor
                                font.family: fontFamily
                                font.pixelSize: vpx(14)
                                font.bold: searchField === modelData.value
                                anchors.verticalCenter: parent.verticalCenter

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            Text {
                                text: "✓"
                                color: accentColor
                                font.pixelSize: vpx(14)
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                                visible: searchField === modelData.value
                            }
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                margins: vpx(10)
                            }
                            height: 1
                            color: "#333"
                            visible: index < searchFieldOptions.length - 1
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            searchField = modelData.value
                            searchFieldDropdownVisible = false

                            // Si hay texto de búsqueda, reiniciar la búsqueda con el nuevo campo
                            if (searchText.trim() !== "") {
                                isSearching = true
                                searchTimer.restart()
                            }
                        }
                    }
                }
            }
        }
    }

    // MENÚ DESPLEGABLE DE FILTROS
    Item {
        id: dropdownContainer
        width: parent.width
        height: dropdownVisible ? parent.parent.height : 0
        anchors.top: parent.top
        anchors.topMargin: vpx(120)
        visible: dropdownVisible && !isGlobalSearch
        z: 100

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.4

            MouseArea {
                anchors.fill: parent
                onClicked: dropdownVisible = false
            }
        }

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

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: vpx(4)
                radius: vpx(12)
                samples: 25
                color: "#80000000"
                transparentBorder: true
            }

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

                            // Icono del filtro (reemplaza emoji con SVG)
                            Image {
                                id: filterIconImage
                                width: vpx(18)
                                height: width
                                source: getFilterIcon(modelData)
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                                anchors.verticalCenter: parent.verticalCenter

                                layer.enabled: true
                                layer.effect: ColorOverlay {
                                    color: {
                                        if (isDisabled) return "#666"
                                            if (currentFilter === modelData) return accentColor
                                                return secondaryTextColor
                                    }
                                    cached: true
                                }

                                opacity: isDisabled ? 0.5 : 1.0
                            }

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

                            Text {
                                text: "✓"
                                color: accentColor
                                font.pixelSize: vpx(16)
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                                visible: currentFilter === modelData && !isDisabled
                            }

                            Text {
                                text: "–"
                                color: "#666"
                                font.pixelSize: vpx(16)
                                anchors.verticalCenter: parent.verticalCenter
                                visible: isDisabled
                            }
                        }

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

    // Cerrar dropdown de campo de búsqueda al hacer clic fuera
    MouseArea {
        anchors.fill: parent
        enabled: searchFieldDropdownVisible
        z: 149
        onClicked: searchFieldDropdownVisible = false
    }

    // Timer optimizado para búsqueda con debounce
    Timer {
        id: searchTimer
        interval: 400  // Aumentado ligeramente para dar tiempo a escribir
        onTriggered: {
            searchRequested(searchText.trim(), searchField)
        }
    }

    // Funciones de utilidad
    function getFilterIcon(filterName) {
        switch(filterName) {
            case "All Games": return "assets/images/icons/allgames.svg"
            case "Favorites": return "assets/images/icons/favorite-yes.svg"
            case "Last Played": return "assets/images/icons/history.svg"
            case "Top Rating": return "assets/images/icons/rating.svg"
            case "Year": return "assets/images/icons/year.svg"
            default: return "assets/images/icons/item.svg"
        }
    }

    function getCurrentSearchFieldName() {
        for (var i = 0; i < searchFieldOptions.length; i++) {
            if (searchFieldOptions[i].value === searchField) {
                return searchFieldOptions[i].name
            }
        }
        return "Title"
    }

    function getCurrentSearchFieldIcon() {
        for (var i = 0; i < searchFieldOptions.length; i++) {
            if (searchFieldOptions[i].value === searchField) {
                return searchFieldOptions[i].icon
            }
        }
        return "assets/images/icons/allgames.svg"
    }

    // API pública
    function setFilter(filterType) {
        if (filterOptions.includes(filterType) && !isGlobalSearch) {
            currentFilter = filterType
            filterChanged(filterType)
        }
    }

    function resetFilter() {
        currentFilter = "All Games"
        isGlobalSearch = false
        isSearching = false
    }

    function updateFilterAvailability(collection) {
        if (!collection || !collection.games) {
            canFilterFavorites = false
            canFilterLastPlayed = false
            return
        }

        var hasFavorites = false
        var hasLastPlayed = false
        var checkLimit = Math.min(collection.games.count, 100)

        for (var i = 0; i < checkLimit; i++) {
            var game = collection.games.get(i)
            if (game) {
                if (!hasFavorites && game.favorite === true) {
                    hasFavorites = true
                }
                if (!hasLastPlayed && game.lastPlayed) {
                    var timestamp = game.lastPlayed.getTime()
                    if (!isNaN(timestamp) && timestamp > 0) {
                        hasLastPlayed = true
                    }
                }
            }
            if (hasFavorites && hasLastPlayed) break
        }

        canFilterFavorites = hasFavorites
        canFilterLastPlayed = hasLastPlayed

        console.log("CollectionTopSection: Filters available - Favorites:", canFilterFavorites, "Last Played:", canFilterLastPlayed)
    }

    function clearSearch() {
        searchInput.text = ""
        searchText = ""
        isGlobalSearch = false
        isSearching = false
        searchField = "title" // Resetear a title
        searchTimer.stop()
        searchRequested("", searchField)
    }

    function focusSearch() {
        searchInput.forceActiveFocus()
    }

    function toggleDropdown() {
        if (!isGlobalSearch) {
            dropdownVisible = !dropdownVisible
        }
    }

    function onCollectionChanged(collection) {
        console.log("CollectionTopSection: Collection changed to", collection ? collection.name : "null")
        updateFilterAvailability(collection)

        if (!isGlobalSearch) {
            resetFilter()
            clearSearch()
        }
    }

    function setSearching(searching) {
        isSearching = searching
    }

    // Manejo de teclado
    Keys.onPressed: {
        if (event.key === Qt.Key_Escape) {
            if (searchFieldDropdownVisible) {
                event.accepted = true
                searchFieldDropdownVisible = false
            } else if (dropdownVisible) {
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

    Component.onCompleted: {
        console.log("CollectionTopSection: Loaded with enhanced search")
        console.log("  - Total games available:", api.allGames.count)
        console.log("  - Search fields available:", searchFieldOptions.length)
        console.log("  - Default search field: title")
    }
}

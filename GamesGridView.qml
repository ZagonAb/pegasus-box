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
        globalSearchMode: false

        onSearchCompleted: {
            console.log("GamesGridView: Search completed")
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

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: vpx(4)
            radius: vpx(12)
            samples: 25
            color: "#40000000"
        }

        Behavior on border.color {
            ColorAnimation { duration: 200 }
        }
    }

    // Título del panel con información dinámica
    Row {
        id: titleRow
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: vpx(20)
        }
        height: vpx(30)
        spacing: vpx(12)

        Text {
            id: panelTitle
            text: {
                if (gamesFilter.globalSearchMode) {
                    return "GLOBAL SEARCH"
                }
                return root.currentCollection ? root.currentCollection.name.toUpperCase() : "GAMES"
            }
            color: accentColor
            font.family: condensedFontFamily
            font.pixelSize: vpx(24)
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }

        // Spinner animado durante búsqueda
        Item {
            id: spinnerContainer
            visible: gamesFilter.globalSearchMode && gamesFilter.isSearching
            width: vpx(24)
            height: vpx(24)
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: spinner
                anchors.fill: parent
                source: "assets/images/icons/spinner.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
                antialiasing: true

                // Animación de rotación continua
                RotationAnimator on rotation {
                    running: spinnerContainer.visible
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }

            // Fallback si no se encuentra la imagen
            Rectangle {
                visible: spinner.status === Image.Error
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: vpx(3)
                border.color: accentColor

                // Animación de rotación con estilo loading
                RotationAnimator on rotation {
                    running: parent.visible
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }

                // Hacer que parezca un spinner con un arco
                Rectangle {
                    width: parent.width / 2
                    height: vpx(3)
                    color: accentColor
                    anchors.centerIn: parent
                    transformOrigin: Item.Left
                }
            }
        }

        // Contador de resultados
        Text {
            id: resultsCounter
            visible: gamesFilter.globalSearchMode && !gamesFilter.isSearching
            text: {
                var count = gamesFilter.filteredModel.count
                if (count === 0) {
                    return "(no results)"
                } else if (count === 1) {
                    return "(1 result)"
                } else {
                    return "(" + count + " results)"
                }
            }
            color: secondaryTextColor
            font.family: condensedFontFamily
            font.pixelSize: vpx(18)
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
            opacity: 0.8
        }
    }

    // Indicador de modo de búsqueda global
    Text {
        id: searchModeIndicator
        visible: gamesFilter.globalSearchMode
        text: {
            var fieldName = "title"
            if (gamesFilter.searchField) {
                fieldName = gamesFilter.searchField
            }

            if (gamesFilter.isSearching) {
                return "🔍 Searching by " + fieldName + " in " + api.allGames.count + " games..."
            }

            if (gamesFilter.searchText && gamesFilter.searchText.length > 0) {
                return "🔍 Results for \"" + gamesFilter.searchText + "\" in " + fieldName
            }
            return "🔍 Searching across all " + api.allGames.count + " games"
        }
        color: secondaryTextColor
        font.family: fontFamily
        font.pixelSize: vpx(12)
        anchors {
            top: titleRow.bottom
            left: parent.left
            right: parent.right
            margins: vpx(20)
            topMargin: vpx(5)
        }
        opacity: 0.8
        elide: Text.ElideRight
    }

    // Contenedor principal
    Item {
        anchors {
            top: gamesFilter.globalSearchMode ? searchModeIndicator.bottom : titleRow.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: vpx(20)
            topMargin: gamesFilter.globalSearchMode ? vpx(10) : vpx(20)
        }

        RowLayout {
            id: mainLayout
            anchors.fill: parent
            spacing: vpx(8)

            // Grid de juegos
            GridView {
                id: gamesGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: width / columns
                cellHeight: cellWidth * 1.4

                model: gamesFilter.filteredModel
                currentIndex: gamesGridView.currentIndex

                // Ocultar durante búsqueda activa
                opacity: gamesFilter.isSearching ? 0.3 : 1.0

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < gamesFilter.filteredModel.count) {
                        positionViewAtIndex(currentIndex, GridView.Contain)
                    }
                }

                // Mensaje de búsqueda en progreso
                Item {
                    visible: gamesFilter.globalSearchMode && gamesFilter.isSearching
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    height: vpx(250)
                    z: 100

                    Column {
                        anchors.centerIn: parent
                        spacing: vpx(25)

                        // Spinner grande central
                        Item {
                            width: vpx(80)
                            height: vpx(80)
                            anchors.horizontalCenter: parent.horizontalCenter

                            Image {
                                id: bigSpinner
                                anchors.fill: parent
                                source: "assets/images/icons/spinner.png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                antialiasing: true

                                RotationAnimator on rotation {
                                    running: parent.parent.parent.visible
                                    from: 0
                                    to: 360
                                    duration: 1200
                                    loops: Animation.Infinite
                                }
                            }

                            // Fallback spinner
                            Rectangle {
                                visible: bigSpinner.status === Image.Error
                                anchors.fill: parent
                                radius: width / 2
                                color: "transparent"
                                border.width: vpx(6)
                                border.color: accentColor

                                RotationAnimator on rotation {
                                    running: parent.visible
                                    from: 0
                                    to: 360
                                    duration: 1200
                                    loops: Animation.Infinite
                                }

                                Rectangle {
                                    width: parent.width / 2
                                    height: vpx(6)
                                    color: accentColor
                                    anchors.centerIn: parent
                                    transformOrigin: Item.Left
                                }
                            }
                        }

                        Text {
                            text: "Searching..."
                            color: textColor
                            font.family: condensedFontFamily
                            font.pixelSize: vpx(24)
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: {
                                var fieldName = gamesFilter.searchField || "title"
                                return "Looking for \"" + gamesFilter.searchText + "\" in " + fieldName
                            }
                            color: secondaryTextColor
                            font.family: fontFamily
                            font.pixelSize: vpx(16)
                            anchors.horizontalCenter: parent.horizontalCenter
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width * 0.8
                        }
                    }
                }

                // Mensaje cuando no hay resultados en búsqueda global
                Item {
                    visible: gamesFilter.globalSearchMode && !gamesFilter.isSearching && gamesFilter.filteredModel.count === 0
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    height: vpx(250)
                    z: 100

                    Column {
                        anchors.centerIn: parent
                        spacing: vpx(20)

                        Text {
                            text: "🔎"
                            font.pixelSize: vpx(64)
                            color: secondaryTextColor
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: 0.5

                            // Animación de escala pulsante
                            SequentialAnimation on scale {
                                running: parent.parent.visible
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 1.1; duration: 1000; easing.type: Easing.InOutQuad }
                                NumberAnimation { from: 1.1; to: 1.0; duration: 1000; easing.type: Easing.InOutQuad }
                            }
                        }

                        Text {
                            text: "No games found"
                            color: textColor
                            font.family: condensedFontFamily
                            font.pixelSize: vpx(24)
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: {
                                var fieldName = gamesFilter.searchField || "title"
                                if (gamesFilter.searchText) {
                                    return "No matches for \"" + gamesFilter.searchText + "\" in " + fieldName
                                }
                                return "Try a different search term or field"
                            }
                            color: secondaryTextColor
                            font.family: fontFamily
                            font.pixelSize: vpx(16)
                            anchors.horizontalCenter: parent.horizontalCenter
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }

                        Rectangle {
                            width: vpx(200)
                            height: vpx(40)
                            radius: vpx(6)
                            color: "#333"
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "Clear Search (ESC)"
                                color: secondaryTextColor
                                font.family: fontFamily
                                font.pixelSize: vpx(14)
                            }
                        }
                    }
                }

                delegate: Item {
                    width: gamesGrid.cellWidth
                    height: gamesGrid.cellHeight

                    readonly property bool isCurrent: index === gamesGrid.currentIndex

                    Rectangle {
                        id: gameItem
                        width: parent.width - vpx(10)
                        height: parent.height - vpx(10)
                        anchors.centerIn: parent

                        color: {
                            if (isCurrent) {
                                if (root.focusedPanel === "games") {
                                    return accentColor
                                } else {
                                    return borderColor
                                }
                            }

                            if (mouseArea.containsMouse && mouseArea.pressed === false) {
                                return "#333333"
                            }

                            return "transparent"
                        }

                        radius: vpx(6)

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
                                    cache: true

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

                                // Indicador de colección en búsqueda global
                                Rectangle {
                                    visible: gamesFilter.globalSearchMode &&
                                    modelData.collections &&
                                    modelData.collections.count > 0
                                    width: parent.width - vpx(10)
                                    height: vpx(22)
                                    radius: vpx(4)
                                    color: "#1a1a1a"
                                    opacity: 0.95
                                    anchors {
                                        bottom: parent.bottom
                                        horizontalCenter: parent.horizontalCenter
                                        margins: vpx(5)
                                    }

                                    border.width: vpx(1)
                                    border.color: accentColor

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: vpx(5)

                                        Text {
                                            text: "📁"
                                            font.pixelSize: vpx(10)
                                            color: accentColor
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: modelData.collections.get(0).shortName ||
                                            modelData.collections.get(0).name
                                            color: accentColor
                                            font.family: condensedFontFamily
                                            font.pixelSize: vpx(11)
                                            font.bold: true
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                // Indicador de juego jugado recientemente
                                Rectangle {
                                    visible: !gamesFilter.globalSearchMode &&
                                    modelData.playCount > 0
                                    width: vpx(26)
                                    height: vpx(26)
                                    radius: width / 2
                                    color: "#2a2a2a"
                                    opacity: 0.9
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        margins: vpx(5)
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "▶"
                                        color: accentColor
                                        font.pixelSize: vpx(12)
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

                            // Información adicional en búsqueda global
                            Text {
                                visible: gamesFilter.globalSearchMode &&
                                (modelData.developer || modelData.releaseYear > 0)
                                width: parent.width
                                text: {
                                    var info = []
                                    if (modelData.releaseYear > 0) {
                                        info.push(modelData.releaseYear.toString())
                                    }
                                    if (modelData.developer) {
                                        var dev = modelData.developer.split(',')[0].trim()
                                        if (dev.length > 15) dev = dev.substring(0, 15) + "..."
                                            info.push(dev)
                                    }
                                    return info.join(" • ")
                                }
                                color: secondaryTextColor
                                font.family: fontFamily
                                font.pixelSize: vpx(11)
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                opacity: 0.7
                            }
                        }

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

            // Scrollbar
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

    Keys.onPressed: {
        if (api.keys.isAccept(event)) {
            event.accepted = true
            if (root.currentGame) root.launchCurrentGame()
        }
        else if (api.keys.isCancel(event)) {
            event.accepted = true
            // Si estamos en búsqueda global, limpiarla primero
            if (gamesFilter.globalSearchMode) {
                gamesFilter.updateSearch("", "title")
            } else {
                root.switchToCollectionsPanel()
            }
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
        console.log("GamesGridView: Collection changed")
        if (currentCollection && !gamesFilter.globalSearchMode) {
            console.log("GamesGridView: Resetting filter (not in global search)")
            gamesFilter.resetFilter()
            currentIndex = 0
            root.currentGameIndex = 0
            gamesGrid.forceLayout()
        } else if (gamesFilter.globalSearchMode) {
            console.log("GamesGridView: Collection changed but maintaining global search")
        }
    }

    Connections {
        target: root
        enabled: !root.isRestoringState

        function onCurrentGameIndexChanged() {
            if (gamesFilter.filteredModel &&
                root.currentGameIndex >= 0 &&
                root.currentGameIndex < gamesFilter.filteredModel.count) {

                if (currentIndex !== root.currentGameIndex) {
                    currentIndex = root.currentGameIndex
                }

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

        currentIndex = 0
        root.currentGameIndex = 0

        if (gamesFilter.filteredModel && gamesFilter.filteredModel.count > 0) {
            root.currentGame = gamesFilter.filteredModel.get(0)
        } else {
            root.currentGame = null
        }

        ensureCurrentVisible()
    }

    function updateSearch(searchText, searchField) {
        console.log("GamesGridView: Updating search")
        console.log("  - Text:", searchText)
        console.log("  - Field:", searchField)

        gamesFilter.updateSearch(searchText, searchField)

        currentIndex = 0
        root.currentGameIndex = 0

        if (gamesFilter.filteredModel && gamesFilter.filteredModel.count > 0) {
            root.currentGame = gamesFilter.filteredModel.get(0)
            console.log("GamesGridView: First result:", root.currentGame.title)
        } else {
            root.currentGame = null
            console.log("GamesGridView: No results")
        }

        ensureCurrentVisible()
    }

    function resetFilter() {
        console.log("GamesGridView: Resetting filter")
        gamesFilter.resetFilter()

        currentIndex = 0
        root.currentGameIndex = 0

        ensureCurrentVisible()
    }

    function ensureCurrentVisible() {
        if (currentIndex >= 0 && currentIndex < gamesFilter.filteredModel.count) {
            gamesGrid.positionViewAtIndex(currentIndex, GridView.Contain)
        }
    }

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
        console.log("=".repeat(60))
        console.log("GamesGridView: Loaded with field-specific search and spinner")
        console.log("  - Total games available:", api.allGames.count)
        console.log("  - Grid layout:", columns, "x", rows)
        console.log("  - Search fields: title, developer, genre, publisher, tags, sortBy")
        console.log("=".repeat(60))
    }
}

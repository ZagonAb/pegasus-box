import QtQuick 2.15
import SortFilterProxyModel 0.2
import QtGraphicalEffects 1.12
import QtQml 2.15
import QtQuick.Layouts 1.15
import "utils.js" as Utils

FocusScope {
    id: gamesListView

    property int currentIndex: 0
    property var currentCollection: root.currentCollection
    property var currentFilteredGame: {
        if (gamesFilter.filteredModel && currentIndex >= 0 &&
            currentIndex < gamesFilter.filteredModel.count) {
            return gamesFilter.filteredModel.get(currentIndex)
            }
            return null
    }

    signal currentGameChanged(var game)
    signal collapseDetailsPanel()

    GamesFilter {
        id: gamesFilter
        sourceModel: root.currentCollection ? root.currentCollection.games : null
        globalSearchMode: false

        onSearchCompleted: {
            console.log("GamesListView: Search completed")
        }
    }

    // MouseArea global para colapsar el panel de detalles
    MouseArea {
        anchors.fill: parent
        onClicked: gamesListView.collapseDetailsPanel()
        propagateComposedEvents: true
        z: -10
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

    // Contenedor principal
    Item {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: vpx(20)
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

        // Mensaje cuando no hay resultados
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
            }
        }

        // Lista de juegos (estilo lista)
        ListView {
            id: gamesList
            anchors.fill: parent
            clip: true
            model: gamesFilter.filteredModel
            currentIndex: gamesListView.currentIndex

            opacity: gamesFilter.isSearching ? 0.3 : 1.0

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            onCurrentIndexChanged: {
                if (currentIndex >= 0 && currentIndex < gamesFilter.filteredModel.count) {
                    positionViewAtIndex(currentIndex, ListView.Contain)
                }
            }

            delegate: Item {
                width: gamesList.width
                height: vpx(120)

                readonly property bool isCurrent: index === gamesList.currentIndex

                Rectangle {
                    id: listItem
                    width: parent.width
                    height: parent.height - vpx(5)
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

                    Row {
                        anchors.fill: parent
                        anchors.margins: vpx(10)
                        spacing: vpx(15)

                        // Imagen del juego
                        Rectangle {
                            id: gameImageContainer
                            width: vpx(80)
                            height: vpx(80)
                            radius: vpx(4)
                            color: "#222"
                            anchors.verticalCenter: parent.verticalCenter

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
                        }

                        // Información del juego
                        Column {
                            width: parent.width - vpx(200)
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: vpx(5)

                            Text {
                                id: gameTitle
                                width: parent.width
                                text: modelData.title ? Utils.cleanGameTitle(modelData.title) : "Select a game"
                                color: isCurrent ? "#ffffff" : textColor
                                font.family: fontFamily
                                font.pixelSize: vpx(16)
                                font.bold: true
                                elide: Text.ElideRight

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            Row {
                                spacing: vpx(15)
                                visible: modelData.developer || modelData.releaseYear > 0

                                Text {
                                    text: modelData.developer ? modelData.developer : "Unknown Developer"
                                    color: isCurrent ? "#dddddd" : secondaryTextColor
                                    font.family: condensedFontFamily
                                    font.pixelSize: vpx(12)
                                    elide: Text.ElideRight
                                    width: vpx(200)
                                }

                                Text {
                                    visible: modelData.releaseYear > 0
                                    text: "(" + modelData.releaseYear + ")"
                                    color: isCurrent ? "#dddddd" : secondaryTextColor
                                    font.family: condensedFontFamily
                                    font.pixelSize: vpx(12)
                                }
                            }

                            Text {
                                visible: modelData.genre
                                text: modelData.genre ? modelData.genre : "Unknown Genre"
                                color: isCurrent ? "#dddddd" : secondaryTextColor
                                font.family: condensedFontFamily
                                font.pixelSize: vpx(12)
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // Controles interactivos (mismo que GridView)
                        Row {
                            id: itemIco
                            spacing: vpx(10)
                            anchors.verticalCenter: parent.verticalCenter

                            // History icon
                            Item {
                                id: historyItem
                                width: vpx(26)
                                height: vpx(26)
                                visible: modelData.lastPlayed && modelData.lastPlayed.toString() !== "Invalid Date"

                                Image {
                                    anchors.fill: parent
                                    source: "assets/images/icons/history.svg"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    antialiasing: true
                                    opacity: 0.8
                                }
                            }

                            // Favorite icon
                            Item {
                                id: favoriteItem
                                width: vpx(26)
                                height: vpx(26)

                                Image {
                                    id: favoriteIcon
                                    anchors.fill: parent
                                    source: modelData.favorite ?
                                    "assets/images/icons/favorite-yes.svg" :
                                    "assets/images/icons/favorite-no.svg"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    antialiasing: true
                                    opacity: favoriteMouseArea.containsMouse ? 1.0 : 0.8

                                    Behavior on opacity {
                                        NumberAnimation { duration: 150 }
                                    }

                                    Behavior on scale {
                                        NumberAnimation { duration: 100 }
                                    }
                                }

                                MouseArea {
                                    id: favoriteMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        modelData.favorite = !modelData.favorite
                                        favoriteIcon.scale = 0.8
                                        scaleBackTimer.restart()
                                    }

                                    onPressed: {
                                        favoriteIcon.scale = 0.9
                                    }

                                    onReleased: {
                                        favoriteIcon.scale = 1.0
                                    }

                                    Timer {
                                        id: scaleBackTimer
                                        interval: 100
                                        onTriggered: favoriteIcon.scale = 1.0
                                    }
                                }
                            }

                            // Play icon
                            Item {
                                id: playItem
                                width: vpx(26)
                                height: vpx(26)

                                Image {
                                    id: playIcon
                                    anchors.fill: parent
                                    source: "assets/images/icons/play.svg"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    antialiasing: true
                                    opacity: playMouseArea.containsMouse ? 1.0 : 0.8

                                    Behavior on opacity {
                                        NumberAnimation { duration: 150 }
                                    }

                                    Behavior on scale {
                                        NumberAnimation { duration: 100 }
                                    }
                                }

                                MouseArea {
                                    id: playMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        modelData.launch()
                                        playIcon.scale = 0.8
                                        playScaleBackTimer.restart()
                                    }

                                    onPressed: {
                                        playIcon.scale = 0.9
                                    }

                                    onReleased: {
                                        playIcon.scale = 1.0
                                    }

                                    Timer {
                                        id: playScaleBackTimer
                                        interval: 100
                                        onTriggered: playIcon.scale = 1.0
                                    }
                                }
                            }
                        }

                        // Información adicional a la derecha
                        Column {
                            width: vpx(100)
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: vpx(3)

                            Text {
                                visible: modelData.rating > 0
                                text: "Rating: " + Math.round(modelData.rating * 100) + "%"
                                color: isCurrent ? "#dddddd" : secondaryTextColor
                                font.family: condensedFontFamily
                                font.pixelSize: vpx(11)
                                horizontalAlignment: Text.AlignRight
                                width: parent.width
                            }

                            Text {
                                visible: modelData.playCount > 0
                                text: "Plays: " + modelData.playCount
                                color: isCurrent ? "#dddddd" : secondaryTextColor
                                font.family: condensedFontFamily
                                font.pixelSize: vpx(11)
                                horizontalAlignment: Text.AlignRight
                                width: parent.width
                            }

                            Text {
                                visible: modelData.playTime > 0
                                text: "Time: " + Utils.formatPlayTime(modelData.playTime)
                                color: isCurrent ? "#dddddd" : secondaryTextColor
                                font.family: condensedFontFamily
                                font.pixelSize: vpx(11)
                                horizontalAlignment: Text.AlignRight
                                width: parent.width
                            }
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        z: -1

                        onClicked: {
                            root.selectGameWithMouse(index)
                            gamesListView.collapseDetailsPanel()
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
    }

    // Scrollbar
    Rectangle {
        id: scrollBar
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            rightMargin: vpx(6)
        }
        width: vpx(6)
        radius: width / 2
        color: "#555"
        opacity: gamesList.moving || gamesList.flicking ? 0.8 : 0.3
        visible: gamesList.contentHeight > gamesList.height

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        Rectangle {
            id: scrollHandle
            anchors {
                left: parent.left
                right: parent.right
            }
            height: Math.max(vpx(30), scrollBar.height * gamesList.visibleArea.heightRatio)

            y: Math.min(
                Math.max(0, gamesList.visibleArea.yPosition * scrollBar.height),
                        scrollBar.height - scrollHandle.height
            )

            radius: width / 2
            color: accentColor
        }
    }

    // Navegación con teclado
    Keys.onPressed: {
        if (api.keys.isAccept(event)) {
            event.accepted = true
            if (root.currentGame) root.launchCurrentGame()
        }
        else if (api.keys.isCancel(event)) {
            event.accepted = true
            if (gamesFilter.globalSearchMode) {
                gamesFilter.updateSearch("", "title")
            } else {
                root.switchToCollectionsPanel()
            }
        }
        else if (event.key === Qt.Key_Left) {
            event.accepted = true
            root.switchToCollectionsPanel()
        }
        else if (event.key === Qt.Key_Right) {
            event.accepted = true
            // Permanece en la lista
        }
        else if (event.key === Qt.Key_Up) {
            event.accepted = true
            if (currentIndex > 0) {
                currentIndex--
                root.currentGameIndex = currentIndex
                gamesList.forceLayout()
            }
        }
        else if (event.key === Qt.Key_Down) {
            event.accepted = true
            if (currentIndex < gamesFilter.filteredModel.count - 1) {
                currentIndex++
                root.currentGameIndex = currentIndex
                gamesList.forceLayout()
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

    function resetAllFilters() {
        console.log("GamesListView: Resetting all filters")
        resetFilter()
    }

    function updateFilter(filterType) {
        console.log("GamesListView: Updating filter to", filterType)
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
        console.log("GamesListView: Updating search")
        gamesFilter.updateSearch(searchText, searchField)

        currentIndex = 0
        root.currentGameIndex = 0

        if (gamesFilter.filteredModel && gamesFilter.filteredModel.count > 0) {
            root.currentGame = gamesFilter.filteredModel.get(0)
        } else {
            root.currentGame = null
        }

        ensureCurrentVisible()
    }

    function resetFilter() {
        console.log("GamesListView: Resetting filter")
        gamesFilter.resetFilter()

        currentIndex = 0
        root.currentGameIndex = 0

        ensureCurrentVisible()
    }

    function ensureCurrentVisible() {
        if (currentIndex >= 0 && currentIndex < gamesFilter.filteredModel.count) {
            gamesList.positionViewAtIndex(currentIndex, ListView.Contain)
        }
    }

    function nextPage() {
        var nextIndex = currentIndex + 10 // 10 items por página
        if (nextIndex < gamesFilter.filteredModel.count) {
            currentIndex = nextIndex
            root.currentGameIndex = currentIndex
        } else {
            currentIndex = gamesFilter.filteredModel.count - 1
            root.currentGameIndex = currentIndex
        }
    }

    function previousPage() {
        var prevIndex = currentIndex - 10 // 10 items por página
        if (prevIndex >= 0) {
            currentIndex = prevIndex
            root.currentGameIndex = currentIndex
        } else {
            currentIndex = 0
            root.currentGameIndex = currentIndex
        }
    }

    Component.onCompleted: {
        console.log("GamesListView: Component loaded")
    }
}

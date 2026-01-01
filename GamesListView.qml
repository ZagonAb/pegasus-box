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
    property var sharedFilter: null
    property alias gamesFilter: filterAlias

    QtObject {
        id: filterAlias
        property var filteredModel: sharedFilter ? sharedFilter.filteredModel : null
        property bool globalSearchMode: sharedFilter ? sharedFilter.globalSearchMode : false
        property bool isSearching: sharedFilter ? sharedFilter.isSearching : false
        property string searchText: sharedFilter ? sharedFilter.searchText : ""
        property string searchField: sharedFilter ? sharedFilter.searchField : "title"
    }

    property var currentFilteredGame: {
        if (gamesFilter.filteredModel && currentIndex >= 0 &&
            currentIndex < gamesFilter.filteredModel.count) {
            return gamesFilter.filteredModel.get(currentIndex)
            }
            return null
    }

    signal currentGameChanged(var game)
    signal collapseDetailsPanel()
    signal switchToGridView()

    MouseArea {
        anchors.fill: parent
        onClicked: {
            gamesListView.collapseDetailsPanel()
        }
        propagateComposedEvents: true
        z: -10
    }

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
            font.pixelSize: root.detailsExpanded ? vpx(14) : vpx(24)
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight

            Behavior on font.pixelSize {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }

        Item {
            width: vpx(28)
            height: vpx(28)
            anchors.verticalCenter: parent.verticalCenter
            visible: root.gamesViewMode === "list"

            Image {
                id: gridViewIcon
                anchors.fill: parent
                source: "assets/images/icons/listview.svg"
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }

            MouseArea {
                id: gridViewMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    gamesListView.switchToGridView()
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width + vpx(8)
                height: parent.height + vpx(8)
                radius: vpx(4)
                color: "transparent"
                border.color: accentColor
                border.width: vpx(1)
                opacity: gridViewMouseArea.containsMouse ? 0.3 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }
        }

        Item {
            width: vpx(28)
            height: vpx(28)
            anchors.verticalCenter: parent.verticalCenter
            visible: root.detailsExpanded

            Image {
                id: closePanelIcon
                anchors.fill: parent
                source: "assets/images/icons/panel-right-close.svg"
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }

            MouseArea {
                id: closePanelMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.detailsExpanded) {
                        gameDetailsPanel.isExpanded = false
                        root.detailsExpanded = false
                        root.focusedPanel = "games"
                        gamesListView.forceActiveFocus()
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width + vpx(8)
                height: parent.height + vpx(8)
                radius: vpx(4)
                color: "transparent"
                border.color: accentColor
                border.width: vpx(1)
                opacity: closePanelMouseArea.containsMouse ? 0.3 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }
        }

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

                RotationAnimator on rotation {
                    running: spinnerContainer.visible
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }

            Rectangle {
                visible: spinner.status === Image.Error
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: vpx(3)
                border.color: accentColor

                RotationAnimator on rotation {
                    running: parent.visible
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }

                Rectangle {
                    width: parent.width / 2
                    height: vpx(3)
                    color: accentColor
                    anchors.centerIn: parent
                    transformOrigin: Item.Left
                }
            }
        }

        Text {
            id: resultsCounter
            visible: gamesFilter.globalSearchMode && !gamesFilter.isSearching
            text: {
                var count = gamesFilter.filteredModel ? gamesFilter.filteredModel.count : 0
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

    Item {
        anchors {
            top: gamesFilter.globalSearchMode ? searchModeIndicator.bottom : titleRow.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: vpx(20)
            topMargin: gamesFilter.globalSearchMode ? vpx(10) : vpx(20)
        }

        ListView {
            id: gamesList
            anchors.fill: parent
            anchors.rightMargin: vpx(20)
            clip: true
            spacing: vpx(10)

            model: gamesFilter.filteredModel
            currentIndex: gamesListView.currentIndex

            opacity: gamesFilter.isSearching ? 0.3 : 1.0

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            onCurrentIndexChanged: {
                if (currentIndex >= 0 && currentIndex < count) {
                    positionViewAtIndex(currentIndex, ListView.Contain)
                }
            }

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

            Item {
                visible: gamesFilter.globalSearchMode && !gamesFilter.isSearching &&
                gamesFilter.filteredModel && gamesFilter.filteredModel.count === 0
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
                width: gamesList.width
                height: vpx(80)

                readonly property bool isCurrent: index === gamesList.currentIndex

                Rectangle {
                    id: listItem
                    anchors.fill: parent
                    anchors.margins: vpx(2)
                    radius: vpx(6)
                    color: {
                        if (isCurrent) {
                            if (root.focusedPanel === "games") {
                                return Qt.rgba(
                                    accentColor.r,
                                    accentColor.g,
                                    accentColor.b,
                                    0.2
                                )
                            } else {
                                return Qt.rgba(
                                    borderColor.r,
                                    borderColor.g,
                                    borderColor.b,
                                    0.2
                                )
                            }
                        }

                        if (mouseArea.containsMouse && !mouseArea.pressed) {
                            return "#1a1a1a"
                        }

                        return "transparent"
                    }

                    border.width: isCurrent ? vpx(2) : vpx(1)
                    border.color: isCurrent ? accentColor : "#333"

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: vpx(10)
                        spacing: vpx(15)

                        Rectangle {
                            id: gameImageContainer
                            width: vpx(60)
                            height: parent.height
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
                                        font.pixelSize: vpx(18)
                                        font.bold: true
                                    }
                                }
                            }
                        }

                        Text {
                            id: gameTitle
                            width: parent.width - gameImageContainer.width - itemIco.width - vpx(30)
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.title ? Utils.cleanGameTitle(modelData.title) : "Select a game"
                            color: isCurrent ? accentColor : textColor
                            font.family: fontFamily
                            font.pixelSize: vpx(16)
                            font.bold: true
                            elide: Text.ElideRight

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                        Row {
                            id: itemIco
                            height: parent.height
                            spacing: vpx(12)
                            visible: isCurrent
                            anchors.verticalCenter: parent.verticalCenter

                            Item {
                                id: historyItem
                                width: vpx(28)
                                height: vpx(28)
                                visible: modelData.lastPlayed && modelData.lastPlayed.toString() !== "Invalid Date"
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    anchors.fill: parent
                                    source: "assets/images/icons/history.svg"
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
                                    opacity: 0.8
                                }
                            }

                            Item {
                                id: favoriteItem
                                width: vpx(28)
                                height: vpx(28)
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    id: favoriteIcon
                                    anchors.fill: parent
                                    source: modelData.favorite ?
                                    "assets/images/icons/favorite-yes.svg" :
                                    "assets/images/icons/favorite-no.svg"
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
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

                            Item {
                                id: playItem
                                width: vpx(28)
                                height: vpx(28)
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    id: playIcon
                                    anchors.fill: parent
                                    source: "assets/images/icons/play.svg"
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
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

                MouseArea {
                    id: gameMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    z: -1

                    onClicked: {
                        root.selectGameWithMouse(index)
                        gamesList.collapseDetailsPanel()
                    }

                    onDoubleClicked: {
                        if (root.currentGame) {
                            root.launchCurrentGame()
                        }
                    }
                }


            }
        }

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
                    Math.max(
                        0,
                        gamesList.visibleArea.yPosition * scrollBar.height
                    ),
                    scrollBar.height - scrollHandle.height
                )

                radius: width / 2
                color: accentColor
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
            if (gamesFilter.globalSearchMode) {
                if (sharedFilter) sharedFilter.updateSearch("", "title")
            } else {
                root.switchToCollectionsPanel()
            }
        }
        else if (event.key === Qt.Key_Left) {
            event.accepted = true
            if (currentIndex === 0) {
                root.switchToCollectionsPanel()
            }
        }
        else if (event.key === Qt.Key_Up) {
            event.accepted = true
            if (currentIndex > 0) {
                currentIndex--
                root.currentGameIndex = currentIndex
            }
        }
        else if (event.key === Qt.Key_Down) {
            event.accepted = true
            if (gamesFilter.filteredModel && currentIndex < gamesFilter.filteredModel.count - 1) {
                currentIndex++
                root.currentGameIndex = currentIndex
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

    onCurrentCollectionChanged: {
        //console.log("GamesListView: Collection changed")
        if (currentCollection && !gamesFilter.globalSearchMode) {
            //console.log("GamesListView: Resetting current index (not in global search)")
            currentIndex = 0
            root.currentGameIndex = 0
        } else if (gamesFilter.globalSearchMode) {
            //console.log("GamesListView: Collection changed but maintaining global search")
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
        //console.log("GamesListView: Resetting all filters")
        if (sharedFilter) sharedFilter.resetFilter()
    }

    function updateFilter(filterType) {
        //console.log("GamesListView: Updating filter to", filterType)
        if (sharedFilter) sharedFilter.updateFilter(filterType)

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
        //console.log("GamesListView: Updating search")
        //console.log("  - Text:", searchText)
        //console.log("  - Field:", searchField)

        if (sharedFilter) sharedFilter.updateSearch(searchText, searchField)

            currentIndex = 0
            root.currentGameIndex = 0

            if (gamesFilter.filteredModel && gamesFilter.filteredModel.count > 0) {
                root.currentGame = gamesFilter.filteredModel.get(0)
                //console.log("GamesListView: First result:", root.currentGame.title)
            } else {
                root.currentGame = null
                //console.log("GamesListView: No results")
            }

            ensureCurrentVisible()
    }

    function resetFilter() {
        //console.log("GamesListView: Resetting filter")
        if (sharedFilter) sharedFilter.resetFilter()

            currentIndex = 0
            root.currentGameIndex = 0

            ensureCurrentVisible()
    }

    function ensureCurrentVisible() {
        if (gamesFilter.filteredModel && currentIndex >= 0 && currentIndex < gamesFilter.filteredModel.count) {
            gamesList.positionViewAtIndex(currentIndex, ListView.Contain)
        }
    }

    function nextPage() {
        if (!gamesFilter.filteredModel) return

            var itemsPerPage = Math.floor(gamesList.height / vpx(80))
            var nextIndex = currentIndex + itemsPerPage
            if (nextIndex < gamesFilter.filteredModel.count) {
                currentIndex = nextIndex
                root.currentGameIndex = currentIndex
            } else {
                currentIndex = gamesFilter.filteredModel.count - 1
                root.currentGameIndex = currentIndex
            }
    }

    function previousPage() {
        var itemsPerPage = Math.floor(gamesList.height / vpx(80))
        var prevIndex = currentIndex - itemsPerPage
        if (prevIndex >= 0) {
            currentIndex = prevIndex
            root.currentGameIndex = currentIndex
        } else {
            currentIndex = 0
            root.currentGameIndex = currentIndex
        }
    }

    Component.onCompleted: {
        //console.log("=".repeat(60))
        //console.log("GamesListView: Loaded with SHARED filter")
        //console.log("  - Total games available:", api.allGames.count)
        //console.log("  - List layout (simplified)")
        //console.log("  - Using centralized GamesFilter from theme.qml")
        //console.log("=".repeat(60))
    }
}

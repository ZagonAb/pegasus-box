import QtQuick 2.15
import QtQml 2.15
import SortFilterProxyModel 0.2
import QtGraphicalEffects 1.12
import QtQuick.Layouts 1.15

FocusScope {
    id: collectionsPanel

    property int currentIndex: 0
    property bool isRestoring: false

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

    RowLayout {
        id: titleRow
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: vpx(20)
        }
        height: vpx(30)
        spacing: vpx(5)

        Item {
            Layout.preferredWidth: vpx(30)
            Layout.preferredHeight: vpx(30)
            Layout.alignment: Qt.AlignVCenter

            Image {
                id: panelIcon
                anchors.fill: parent
                source: "assets/images/icons/pegasusbox.svg"
                fillMode: Image.PreserveAspectFit
                mipmap: true
                sourceSize: Qt.size(vpx(30), vpx(30))
                visible: false
            }

            ColorOverlay {
                anchors.fill: panelIcon
                source: panelIcon
                color: accentColor
                cached: true
            }
        }

        Text {
            id: panelTitle
            text: "PEGASUS BOX"
            color: accentColor
            font.family: condensedFontFamily
            font.pixelSize: vpx(24)
            font.bold: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.fillWidth: true
            verticalAlignment: Text.AlignVCenter
            height: implicitHeight
        }
    }

    CollectionTopSection {
        id: topSection
        objectName: "topSection"
        anchors {
            top: titleRow.bottom
            left: parent.left
            right: parent.right
            margins: vpx(15)
            topMargin: vpx(15)
        }
        height: vpx(120)
        z: 2

        onFilterChanged: function(filterType) {
            //console.log("CollectionsPanel: Filter changed to:", filterType)

            if (gamesGridView && typeof gamesGridView.updateFilter === "function") {
                gamesGridView.updateFilter(filterType)
            }
        }

        onSearchRequested: function(text, field) {
            /*console.log("CollectionsPanel: Search requested")
            console.log("  - Text:", text)
            console.log("  - Field:", field)*/

            if (gamesGridView && typeof gamesGridView.updateSearch === "function") {
                gamesGridView.updateSearch(text, field)
            }
        }
    }

    Rectangle {
        id: gameLibraryButton
        anchors {
            top: topSection.bottom
            left: parent.left
            right: parent.right
            margins: vpx(15)
            topMargin: vpx(10)
        }
        height: vpx(45)
        radius: vpx(6)
        color: {
            if (root.currentCollectionIndex === -1) {
                return accentColor
            }
            if (libraryMouseArea.containsMouse && !libraryMouseArea.pressed) {
                return "#333333"
            }
            return "#222222"
        }
        border.width: vpx(2)
        border.color: root.currentCollectionIndex === -1 ? accentColor : borderColor

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
            anchors.centerIn: parent
            spacing: vpx(10)

            Item {
                width: vpx(24)
                height: vpx(24)
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: libraryIcon
                    anchors.fill: parent
                    source: "assets/images/icons/collection.svg"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    visible: false
                }

                ColorOverlay {
                    anchors.fill: libraryIcon
                    source: libraryIcon
                    color: root.currentCollectionIndex === -1 ? "#ffffff" : textColor
                    cached: true
                    visible: libraryIcon.status === Image.Ready

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "📚"
                    font.pixelSize: vpx(20)
                    visible: libraryIcon.status !== Image.Ready
                }
            }

            Text {
                text: "GAME LIBRARY"
                color: root.currentCollectionIndex === -1 ? "#ffffff" : textColor
                font.family: condensedFontFamily
                font.pixelSize: vpx(18)
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        MouseArea {
            id: libraryMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                root.activateGameLibrary()
            }
        }
    }

    Rectangle {
        id: middleSeparator
        anchors {
            top: gameLibraryButton.bottom
            left: parent.left
            right: parent.right
            margins: vpx(20)
            topMargin: vpx(10)
        }
        height: 1
        color: borderColor
        z: 1
    }

    Item {
        id: bottomSection
        anchors {
            top: middleSeparator.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: vpx(15)
            topMargin: vpx(10)
            bottomMargin: vpx(15)
        }
        z: 0

        RowLayout {
            id: mainLayout
            anchors.fill: parent
            spacing: vpx(8)

            ListView {
                id: collectionsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                model: api.collections
                currentIndex: collectionsPanel.currentIndex

                delegate: Item {
                    width: collectionsList.width
                    height: vpx(40)

                    readonly property bool isCurrent: index === collectionsList.currentIndex
                    readonly property bool panelHasFocus: parent ? parent.focus : false
                    readonly property string systemImagePath: "assets/images/systems/" +
                    (modelData.shortName ? modelData.shortName.toLowerCase() : "") + ".png"

                    Rectangle {
                        id: itemBackground
                        anchors.fill: parent
                        anchors.margins: vpx(1)

                        color: {
                            if (isCurrent) {
                                return root.focusedPanel === "collections" ? accentColor : borderColor
                            }
                            if (mouseArea.containsMouse && mouseArea.pressed === false) {
                                return "#333333"
                            }
                            return "transparent"
                        }

                        radius: vpx(3)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.fill: parent
                            anchors.margins: vpx(8)
                            spacing: vpx(10)

                            Rectangle {
                                width: vpx(24)
                                height: vpx(24)
                                radius: vpx(3)
                                color: "#333"
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    id: systemImage
                                    anchors.fill: parent
                                    anchors.margins: vpx(2)
                                    source: systemImagePath
                                    fillMode: Image.PreserveAspectFit
                                    visible: status === Image.Ready
                                    asynchronous: true
                                    mipmap: true
                                }

                                Text {
                                    id: shrtNameCollection
                                    anchors.centerIn: parent
                                    text: modelData.shortName ?
                                    modelData.shortName.substring(0, 2).toUpperCase() : "??"
                                    color: textColor
                                    font.family: condensedFontFamily
                                    font.pixelSize: vpx(10)
                                    font.bold: true
                                    visible: systemImage.status !== Image.Ready
                                }
                            }

                            Column {
                                width: parent.width - vpx(40)
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: vpx(2)

                                Text {
                                    width: parent.width
                                    text: modelData.name
                                    color: isCurrent ? "#ffffff" : textColor
                                    font.family: condensedFontFamily
                                    font.pixelSize: vpx(12)
                                    elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Text {
                                    width: parent.width
                                    text: modelData.games.count + " games"
                                    color: isCurrent ? "#dddddd" : secondaryTextColor
                                    font.family: condensedFontFamily
                                    font.pixelSize: vpx(10)
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.selectCollectionWithMouse(index)
                        }
                    }
                }

                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < api.collections.count) {
                        positionViewAtIndex(currentIndex, ListView.Contain)
                    }
                }

                Component.onCompleted: {
                    if (currentIndex >= 0 && currentIndex < api.collections.count) {
                        positionViewAtIndex(currentIndex, ListView.Contain)
                    }
                }
            }

            Rectangle {
                id: scrollBar
                Layout.preferredWidth: vpx(4)
                Layout.fillHeight: true
                radius: width / 2
                color: "#555"
                opacity: collectionsList.moving || collectionsList.flicking ? 0.8 : 0.3
                visible: collectionsList.contentHeight > collectionsList.height

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                Rectangle {
                    id: scrollHandle
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: Math.max(vpx(20), scrollBar.height * collectionsList.visibleArea.heightRatio)

                    y: Math.min(
                        Math.max(0, collectionsList.visibleArea.yPosition * scrollBar.height),
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
            root.selectCollection(currentIndex)
            root.switchToGamesPanel()
        }
        else if (event.key === Qt.Key_Up) {
            event.accepted = true
            if (currentIndex > 0) {
                currentIndex--
                root.currentCollectionIndex = currentIndex
                collectionsList.forceLayout()
            }
        }
        else if (event.key === Qt.Key_Down) {
            event.accepted = true
            if (currentIndex < api.collections.count - 1) {
                currentIndex++
                root.currentCollectionIndex = currentIndex
                collectionsList.forceLayout()
            }
        }
        else if (event.key === Qt.Key_Right) {
            event.accepted = true
            root.switchToGamesPanel()
        }
        else if (api.keys.isPageUp(event)) {
            event.accepted = true
            previousItem()
        }
        else if (api.keys.isPageDown(event)) {
            event.accepted = true
            nextItem()
        }
    }

    Binding {
        target: collectionsPanel
        property: "currentIndex"
        value: root.currentCollectionIndex
        when: !root.isRestoringState
        restoreMode: Binding.RestoreBindingOrValue
    }

    Timer {
        id: ensureVisibleTimer
        interval: 100
        running: false
        repeat: false
        onTriggered: {
            if (collectionsPanel.currentIndex >= 0 && collectionsPanel.currentIndex < api.collections.count) {
                collectionsList.positionViewAtIndex(collectionsPanel.currentIndex, ListView.Contain)
            }
        }
    }

    onCurrentIndexChanged: {
        if (!isRestoring && currentIndex >= 0 && currentIndex < api.collections.count) {
            ensureVisibleTimer.restart()
        }
    }

    function nextItem() {
        if (currentIndex < api.collections.count - 1) {
            currentIndex++
            root.currentCollectionIndex = currentIndex
            collectionsList.positionViewAtIndex(currentIndex, ListView.Contain)
        }
    }

    function previousItem() {
        if (currentIndex > 0) {
            currentIndex--
            root.currentCollectionIndex = currentIndex
            collectionsList.positionViewAtIndex(currentIndex, ListView.Contain)
        }
    }

    function ensureCurrentVisible() {
        if (currentIndex >= 0 && currentIndex < api.collections.count) {
            collectionsList.positionViewAtIndex(currentIndex, ListView.Contain)
        }
    }

    Connections {
        target: root
        function onCurrentCollectionChanged() {
            /*console.log("CollectionsPanel: Current collection changed to",
                        root.currentCollection ? root.currentCollection.name : "null")*/

            if (topSection && typeof topSection.onCollectionChanged === "function") {
                topSection.onCollectionChanged(root.currentCollection)
            }

            if (gamesGridView && typeof gamesGridView.resetFilter === "function") {
                Qt.callLater(function() {
                    gamesGridView.resetFilter()
                })
            }
        }
    }

    Component.onCompleted: {
        //console.log("CollectionsPanel loaded with field-specific search")

        if (topSection && typeof topSection.updateFilterAvailability === "function") {
            Qt.callLater(function() {
                topSection.updateFilterAvailability(root.currentCollection)
            })
        }
    }
}

import QtQuick 2.15
import SortFilterProxyModel 0.2
import QtGraphicalEffects 1.12

Item {
    id: collectionsPanel

    property int currentIndex: 0
    property bool isRestoring: false

    // Fondo del panel
    Rectangle {
        id: panelBackground
        anchors.fill: parent
        color: panelColor
        radius: vpx(8)
        border.width: vpx(2)
        border.color: borderColor

        // Efecto de sombra
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: vpx(4)
            radius: vpx(12)
            samples: 25
            color: "#40000000"
        }
    }

    // Título del panel
    Text {
        id: panelTitle
        text: "COLLECTIONS"
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

    // Lista de colecciones
    ListView {
        id: collectionsList
        anchors {
            top: panelTitle.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: vpx(15)
            topMargin: vpx(25)
        }
        clip: true

        model: api.collections
        currentIndex: collectionsPanel.currentIndex

        onCurrentIndexChanged: {
            if (currentIndex >= 0 && currentIndex < api.collections.count) {
                positionViewAtIndex(currentIndex, ListView.Contain)
            }
        }

        Component.onCompleted: {
            console.log("CollectionsPanel loaded, currentIndex:", currentIndex)
            if (currentIndex >= 0 && currentIndex < api.collections.count) {
                positionViewAtIndex(currentIndex, ListView.Contain)
            }
        }

        delegate: Item {
            width: collectionsList.width
            height: vpx(60)

            Rectangle {
                anchors.fill: parent
                anchors.margins: vpx(2)
                color: index === collectionsList.currentIndex ? accentColor : "transparent"
                radius: vpx(4)

                // Imagen de la colección
                Image {
                    id: collectionImage
                    width: vpx(48)
                    height: vpx(48)
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        margins: vpx(10)
                    }
                    source: modelData.assets.tile || modelData.assets.logo || ""
                    fillMode: Image.PreserveAspectFit
                    visible: source.toString() !== ""

                    // Placeholder si no hay imagen
                    Rectangle {
                        anchors.fill: parent
                        color: "#333"
                        radius: vpx(4)
                        visible: !collectionImage.visible

                        Text {
                            anchors.centerIn: parent
                            text: modelData.shortName ? modelData.shortName.substring(0, 2).toUpperCase() : "??"
                            color: textColor
                            font.family: condensedFontFamily
                            font.pixelSize: vpx(16)
                            font.bold: true
                        }
                    }
                }

                // Nombre de la colección
                Text {
                    anchors {
                        left: collectionImage.visible ? collectionImage.right : parent.left
                        right: gameCount.left
                        verticalCenter: parent.verticalCenter
                        margins: vpx(15)
                    }
                    text: modelData.name
                    color: index === collectionsList.currentIndex ? "#ffffff" : textColor
                    font.family: fontFamily
                    font.pixelSize: vpx(16)
                    elide: Text.ElideRight
                }

                // Contador de juegos
                Text {
                    id: gameCount
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: vpx(15)
                    }
                    text: modelData.games.count
                    color: index === collectionsList.currentIndex ? "#ffffff" : secondaryTextColor
                    font.family: condensedFontFamily
                    font.pixelSize: vpx(14)
                }

                // Mouse/touch area
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        collectionsList.currentIndex = index
                        collectionsPanel.currentIndex = index
                        root.selectCollection(index)
                    }

                    // Efecto hover
                    onEntered: {
                        if (index !== collectionsList.currentIndex) {
                            parent.color = "#333333"
                        }
                    }
                    onExited: {
                        if (index !== collectionsList.currentIndex) {
                            parent.color = "transparent"
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
            opacity: collectionsList.moving || collectionsList.flicking ? 0.8 : 0.3
            visible: collectionsList.contentHeight > collectionsList.height

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: Math.max(vpx(30), collectionsList.height * collectionsList.visibleArea.heightRatio)
                y: collectionsList.visibleArea.yPosition * collectionsList.height
                radius: width / 2
                color: accentColor
            }
        }
    }

    // Navegación con teclado
    Keys.onPressed: {
        if (api.keys.isAccept(event)) {
            event.accepted = true
            root.selectCollection(currentIndex)
        }
        else if (event.key === Qt.Key_Up) {
            event.accepted = true
            if (currentIndex > 0) currentIndex--
        }
        else if (event.key === Qt.Key_Down) {
            event.accepted = true
            if (currentIndex < api.collections.count - 1) currentIndex++
        }
    }

    // Sincronizar con root.currentCollectionIndex
    Binding {
        target: collectionsPanel
        property: "currentIndex"
        value: root.currentCollectionIndex
        when: !root.isRestoringState
    }

    // Timer para forzar visibilidad después de la restauración
    Timer {
        id: ensureVisibleTimer
        interval: 100 // Pequeño delay después de la restauración
        running: false
        repeat: false
        onTriggered: {
            if (collectionsPanel.currentIndex >= 0 && collectionsPanel.currentIndex < api.collections.count) {
                console.log("Ensuring collection visibility at index:", collectionsPanel.currentIndex)
                collectionsList.positionViewAtIndex(collectionsPanel.currentIndex, ListView.Contain)
            }
        }
    }

    // Cuando cambia currentIndex (desde root), asegurar visibilidad
    onCurrentIndexChanged: {
        if (!isRestoring && currentIndex >= 0 && currentIndex < api.collections.count) {
            console.log("Collection index changed to:", currentIndex)
            // Pequeño delay para asegurar que el ListView esté listo
            ensureVisibleTimer.restart()
        }
    }

    // Funciones de navegación
    function nextItem() {
        if (currentIndex < api.collections.count - 1) {
            currentIndex++
            collectionsList.positionViewAtIndex(currentIndex, ListView.Contain)
        }
    }

    function previousItem() {
        if (currentIndex > 0) {
            currentIndex--
            collectionsList.positionViewAtIndex(currentIndex, ListView.Contain)
        }
    }

    // Función para forzar visibilidad (llamada desde root)
    function ensureCurrentVisible() {
        if (currentIndex >= 0 && currentIndex < api.collections.count) {
            collectionsList.positionViewAtIndex(currentIndex, ListView.Contain)
        }
    }
}

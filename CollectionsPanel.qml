import QtQuick 2.15
import QtQml 2.15
import SortFilterProxyModel 0.2
import QtGraphicalEffects 1.12
import QtQuick.Layouts 1.15  // AÑADIDO

FocusScope {
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

    // Título del panel
    Text {
        id: panelTitle
        text: "PegasusBox"
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

    // Contenedor principal con RowLayout para separar lista y scrollbar
    Item {
        anchors {
            top: panelTitle.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: vpx(15)
            topMargin: vpx(25)
        }

        RowLayout {
            id: mainLayout
            anchors.fill: parent
            spacing: vpx(8)  // ESPACIO ENTRE LISTA Y SCROLLBAR

            // Lista de colecciones (toma todo el espacio disponible)
            ListView {
                id: collectionsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                model: api.collections
                currentIndex: collectionsPanel.currentIndex

                // Asegurar que el item actual sea visible cuando cambia el índice
                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < api.collections.count) {
                        positionViewAtIndex(currentIndex, ListView.Contain)
                    }
                }

                // Forzar visibilidad cuando se completa la carga
                Component.onCompleted: {
                    console.log("CollectionsPanel loaded, currentIndex:", currentIndex)
                    if (currentIndex >= 0 && currentIndex < api.collections.count) {
                        positionViewAtIndex(currentIndex, ListView.Contain)
                    }
                }

                delegate: Item {
                    width: collectionsList.width
                    height: vpx(60)

                    // Propiedad para determinar si este item es el actual
                    readonly property bool isCurrent: index === collectionsList.currentIndex
                    readonly property bool panelHasFocus: {
                        if (parent) {
                            return parent.focus
                        }
                        return false
                    }

                    Rectangle {
                        id: itemBackground
                        anchors.fill: parent
                        anchors.margins: vpx(2)

                        color: {
                            // Verificar si este item es el actual
                            if (isCurrent) {
                                // Si el panel de colecciones tiene foco global, mostrar azul
                                if (root.focusedPanel === "collections") {
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

                        radius: vpx(4)

                        // Transición suave del color
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

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
                            id: collectionName
                            anchors {
                                left: collectionImage.visible ? collectionImage.right : parent.left
                                right: gameCount.left
                                verticalCenter: parent.verticalCenter
                                margins: vpx(15)
                            }
                            text: modelData.name
                            // Texto blanco si es current (con o sin foco), color normal si no
                            color: isCurrent ? "#ffffff" : textColor
                            font.family: fontFamily
                            font.pixelSize: vpx(16)
                            elide: Text.ElideRight

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
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
                            color: isCurrent ? "#ffffff" : secondaryTextColor
                            font.family: condensedFontFamily
                            font.pixelSize: vpx(14)

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                        // Mouse/touch area
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                root.selectCollectionWithMouse(index)
                            }

                            // El hover se maneja directamente en la lógica de color del Rectangle
                        }
                    }
                }
            }

            // Scrollbar (ancho fijo, se mantiene a la derecha)
            Rectangle {
                id: scrollBar
                Layout.preferredWidth: vpx(6)
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
                    height: Math.max(vpx(30), scrollBar.height * collectionsList.visibleArea.heightRatio)

                    // LIMITAR LA POSICIÓN Y PARA QUE NO SE SALGA DEL PADRE
                    y: Math.min(
                        Math.max(
                            0, // Límite superior
                            collectionsList.visibleArea.yPosition * scrollBar.height
                        ),
                        scrollBar.height - scrollHandle.height // Límite inferior
                    )

                    radius: width / 2
                    color: accentColor
                }
            }
        }
    }

    // Navegación con teclado
    Keys.onPressed: {
        if (api.keys.isAccept(event)) {
            event.accepted = true
            // Cambiar a la colección y pasar al panel de juegos
            root.selectCollection(currentIndex)
            root.switchToGamesPanel()
        }
        else if (event.key === Qt.Key_Up) {
            event.accepted = true
            if (currentIndex > 0) {
                currentIndex--
                root.currentCollectionIndex = currentIndex
                // Forzar actualización de hover
                collectionsList.forceLayout()
            }
        }
        else if (event.key === Qt.Key_Down) {
            event.accepted = true
            if (currentIndex < api.collections.count - 1) {
                currentIndex++
                root.currentCollectionIndex = currentIndex
                // Forzar actualización de hover
                collectionsList.forceLayout()
            }
        }
        else if (event.key === Qt.Key_Right) {
            event.accepted = true
            // Pasar al panel de juegos
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

    // Timer para forzar visibilidad después de la restauración
    Timer {
        id: ensureVisibleTimer
        interval: 100
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
            ensureVisibleTimer.restart()
        }
    }

    // Funciones de navegación
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

    // Función para forzar visibilidad (llamada desde root)
    function ensureCurrentVisible() {
        if (currentIndex >= 0 && currentIndex < api.collections.count) {
            collectionsList.positionViewAtIndex(currentIndex, ListView.Contain)
        }
    }
}

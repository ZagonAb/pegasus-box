import QtQuick 2.15
import QtGraphicalEffects 1.12
import "qrc:/qmlutils" as PegasusUtils
import "utils.js" as Utils

Item {
    id: gameDetailsPanel

    property var displayGame: {
        // Prioridad: juego del grid filtrado
        if (gamesGridView && gamesGridView.currentFilteredGame) {
            return gamesGridView.currentFilteredGame
        }
        // Fallback: juego actual de root
        return displayGame
    }

    Rectangle {
        id: panelBackground
        anchors.fill: parent
        color: panelColor
        radius: vpx(8)
        border.width: vpx(2)
        border.color: borderColor

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: vpx(4)
            radius: vpx(12)
            samples: 25
            color: "#40000000"
        }
    }

    Text {
        id: panelTitle
        text: "DETAILS"
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

    Flickable {
        id: detailsFlickable
        anchors {
            top: panelTitle.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: vpx(20)
            topMargin: vpx(30)
        }
        clip: true
        contentWidth: width
        contentHeight: detailsColumn.height
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: detailsColumn
            width: parent.width
            spacing: vpx(20)

            Rectangle {
                width: parent.width
                height: width * 0.75
                radius: vpx(6)
                color: "#222"

                Image {
                    id: gameImage
                    anchors.fill: parent
                    source: displayGame ? displayGame.assets.screenshot || displayGame.assets.logo || "" : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true

                    Rectangle {
                        anchors.fill: parent
                        color: "#333"
                        radius: vpx(4)
                        visible: gameImage.status !== Image.Ready || !gameImage.source.toString()

                        Text {
                            anchors.centerIn: parent
                            text: "NO IMAGE"
                            color: secondaryTextColor
                            font.family: condensedFontFamily
                            font.pixelSize: vpx(18)
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: displayGame ? Utils.cleanGameTitle(displayGame.title) : "Select a game"
                color: textColor
                font.family: fontFamily
                font.pixelSize: vpx(22)
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Text {
                id: filterIndicator
                anchors {
                    top: panelTitle.bottom
                    left: parent.left
                    right: parent.right
                    margins: vpx(20)
                    topMargin: vpx(5)
                }
                text: gamesGridView && gamesGridView.gamesFilter &&
                gamesGridView.gamesFilter.currentFilter !== "All Games" ?
                "Filter: " + gamesGridView.gamesFilter.currentFilter : ""
                color: accentColor
                font.family: condensedFontFamily
                font.pixelSize: vpx(14)
                visible: text !== ""
            }

            Column {
                id: basicInfoColumn
                width: parent.width
                spacing: vpx(12)
                visible: displayGame

                Text {
                    text: "BASIC INFO"
                    color: accentColor
                    font.family: condensedFontFamily
                    font.pixelSize: vpx(16)
                    font.bold: true
                }

                DetailRow {
                    label: "Year:"
                    value: displayGame && displayGame.releaseYear > 0 ?
                    displayGame.releaseYear.toString() : "Unknown"
                    labelColor: secondaryTextColor
                    valueColor: textColor
                }

                DetailRow {
                    label: "Developer:"
                    value: displayGame && displayGame.developer ?
                    displayGame.developer : "Unknown"
                    labelColor: secondaryTextColor
                    valueColor: textColor
                }

                DetailRow {
                    label: "Publisher:"
                    value: displayGame && displayGame.publisher ?
                    displayGame.publisher : "Unknown"
                    labelColor: secondaryTextColor
                    valueColor: textColor
                }

                DetailRow {
                    label: "Genre:"
                    value: displayGame && displayGame.genre ?
                    Utils.getFirstGenre(displayGame) : "Unknown"
                    labelColor: secondaryTextColor
                    valueColor: textColor
                }

                DetailRow {
                    label: "Players:"
                    value: displayGame ? displayGame.players + "P" : "1P"
                    labelColor: secondaryTextColor
                    valueColor: textColor
                }

                DetailRow {
                    label: "Rating:"
                    value: displayGame ? Math.round(displayGame.rating * 100) + "%" : "0%"
                    labelColor: secondaryTextColor
                    valueColor: textColor
                    showDivider: true
                }
            }

            Column {
                width: parent.width
                spacing: vpx(8)
                visible: displayGame && displayGame.description

                Text {
                    text: "DESCRIPTION"
                    color: accentColor
                    font.family: condensedFontFamily
                    font.pixelSize: vpx(16)
                    font.bold: true
                }

                Item {
                    id: scrollContainer
                    width: parent.width
                    height: width * 0.5
                    clip: true

                    PegasusUtils.AutoScroll {
                        id: autoscroll
                        anchors.fill: parent
                        pixelsPerSecond: 15
                        scrollWaitDuration: 3000

                        Item {
                            width: autoscroll.width
                            height: descripText.height

                            Text {
                                id: descripText
                                width: parent.width
                                text: displayGame ? displayGame.description : ""
                                wrapMode: Text.WordWrap
                                lineHeight: 1.4
                                font {
                                    family: global.fonts.sans
                                    pixelSize: vpx(14)
                                }
                                color: "white"
                            }
                        }
                    }
                }
            }

            Column {
                id: statsColumn
                width: parent.width
                spacing: vpx(12)
                visible: displayGame && (displayGame.playCount > 0 || displayGame.playTime > 0)

                Text {
                    text: "STATISTICS"
                    color: accentColor
                    font.family: condensedFontFamily
                    font.pixelSize: vpx(16)
                    font.bold: true
                }

                DetailRow {
                    label: "Play Count:"
                    value: displayGame ? displayGame.playCount.toString() : "0"
                    labelColor: secondaryTextColor
                    valueColor: textColor
                }

                DetailRow {
                    label: "Play Time:"
                    value: displayGame ? Utils.formatPlayTime(displayGame.playTime) : "0h 0m"
                    labelColor: secondaryTextColor
                    valueColor: textColor
                }

                DetailRow {
                    label: "Last Played:"
                    value: displayGame && displayGame.lastPlayed ?
                    Utils.formatDate(displayGame.lastPlayed) : "Never"
                    labelColor: secondaryTextColor
                    valueColor: textColor
                    showDivider: true
                }
            }

            Rectangle {
                id: launchButton
                width: parent.width
                height: vpx(50)
                radius: vpx(6)
                color: accentColor
                visible: displayGame

                Text {
                    anchors.centerIn: parent
                    text: "LAUNCH GAME"
                    color: "#ffffff"
                    font.family: condensedFontFamily
                    font.pixelSize: vpx(18)
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (displayGame) {
                            root.launchCurrentGame()
                        }
                    }

                    onEntered: launchButton.opacity = 0.8
                    onExited: launchButton.opacity = 1
                    onPressed: launchButton.opacity = 0.6
                    onReleased: launchButton.opacity = 0.8
                }
            }

            Item {
                width: parent.width
                height: vpx(20)
            }
        }
    }

    Rectangle {
        id: scrollBar
        anchors {
            right: parent.right
            top: detailsFlickable.top
            bottom: detailsFlickable.bottom
            rightMargin: vpx(6)
        }
        width: vpx(6)
        radius: width / 2
        color: "#555"
        opacity: detailsFlickable.moving || detailsFlickable.flicking ? 0.8 : 0.3
        visible: detailsFlickable.contentHeight > detailsFlickable.height

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        Rectangle {
            id: scrollHandle
            anchors {
                left: parent.left
                right: parent.right
            }
            height: Math.max(vpx(30), scrollBar.height * detailsFlickable.visibleArea.heightRatio)

            // LIMITAR LA POSICIÓN Y PARA QUE NO SE SALGA DEL PADRE
            y: Math.min(
                Math.max(
                    0, // Límite superior
                    detailsFlickable.visibleArea.yPosition * scrollBar.height
                ),
                scrollBar.height - scrollHandle.height // Límite inferior
            )

            radius: width / 2
            color: accentColor
        }
    }
}

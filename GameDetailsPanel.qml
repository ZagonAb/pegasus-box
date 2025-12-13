import QtQuick 2.15
import QtGraphicalEffects 1.12
import "qrc:/qmlutils" as PegasusUtils
import "utils.js" as Utils

Item {
    id: gameDetailsPanel

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
                    source: root.currentGame ? root.currentGame.assets.screenshot || root.currentGame.assets.logo || "" : ""
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
                text: root.currentGame ? Utils.cleanGameTitle(root.currentGame.title) : "Select a game"
                color: textColor
                font.family: fontFamily
                font.pixelSize: vpx(22)
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Column {
                id: basicInfoColumn
                width: parent.width
                spacing: vpx(12)
                visible: root.currentGame

                Text {
                    text: "BASIC INFO"
                    color: accentColor
                    font.family: condensedFontFamily
                    font.pixelSize: vpx(16)
                    font.bold: true
                }

                DetailRow {
                    label: "Year:"
                    value: root.currentGame && root.currentGame.releaseYear > 0 ?
                    root.currentGame.releaseYear.toString() : "Unknown"
                    labelColor: secondaryTextColor
                    valueColor: textColor
                }

                DetailRow {
                    label: "Developer:"
                    value: root.currentGame && root.currentGame.developer ?
                    root.currentGame.developer : "Unknown"
                    labelColor: secondaryTextColor
                    valueColor: textColor
                }

                DetailRow {
                    label: "Publisher:"
                    value: root.currentGame && root.currentGame.publisher ?
                    root.currentGame.publisher : "Unknown"
                    labelColor: secondaryTextColor
                    valueColor: textColor
                }

                DetailRow {
                    label: "Genre:"
                    value: root.currentGame && root.currentGame.genre ?
                    root.currentGame.genre : "Unknown"
                    labelColor: secondaryTextColor
                    valueColor: textColor
                }

                DetailRow {
                    label: "Players:"
                    value: root.currentGame ? root.currentGame.players + "P" : "1P"
                    labelColor: secondaryTextColor
                    valueColor: textColor
                }

                DetailRow {
                    label: "Rating:"
                    value: root.currentGame ? Math.round(root.currentGame.rating * 100) + "%" : "0%"
                    labelColor: secondaryTextColor
                    valueColor: textColor
                    showDivider: true
                }
            }

            Column {
                width: parent.width
                spacing: vpx(8)
                visible: root.currentGame && root.currentGame.description

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
                                text: root.currentGame ? root.currentGame.description : ""
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
                visible: root.currentGame && (root.currentGame.playCount > 0 || root.currentGame.playTime > 0)

                Text {
                    text: "STATISTICS"
                    color: accentColor
                    font.family: condensedFontFamily
                    font.pixelSize: vpx(16)
                    font.bold: true
                }

                DetailRow {
                    label: "Play Count:"
                    value: root.currentGame ? root.currentGame.playCount.toString() : "0"
                    labelColor: secondaryTextColor
                    valueColor: textColor
                }

                DetailRow {
                    label: "Play Time:"
                    value: root.currentGame ? Utils.formatPlayTime(root.currentGame.playTime) : "0h 0m"
                    labelColor: secondaryTextColor
                    valueColor: textColor
                }

                DetailRow {
                    label: "Last Played:"
                    value: root.currentGame && root.currentGame.lastPlayed ?
                    Utils.formatDate(root.currentGame.lastPlayed) : "Never"
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
                visible: root.currentGame

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
                        if (root.currentGame) {
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

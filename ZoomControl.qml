import QtQuick 2.15

Item {
    id: zoomControl

    property real zoomLevel: 1.0
    property color accentColor: "#0078d7"
    property color borderColor: "#333333"
    property color secondaryTextColor: "#b0b0b0"
    property string condensedFontFamily: "Arial"

    signal zoomChanged(real level)

    implicitWidth: 220
    implicitHeight: 50

    readonly property var zoomLevels: [0.5, 0.8, 1.1, 1.5, 2.0]

    function vpx(value) {
        return Math.round(value * (height / 50))
    }

    function calculateHandlePosition(level) {
        var closestIndex = 0
        var minDiff = Math.abs(level - zoomLevels[0])

        for (var i = 1; i < zoomLevels.length; i++) {
            var diff = Math.abs(level - zoomLevels[i])
            if (diff < minDiff) {
                minDiff = diff
                closestIndex = i
            }
        }

        var trackStart = sliderTrack.x
        var trackWidth = sliderTrack.width
        var pointPosition = trackStart + (trackWidth * (closestIndex / (zoomLevels.length - 1)))

        return pointPosition - (sliderHandle.width / 2)
    }

    onZoomLevelChanged: {
        if (sliderTrack.width > 0) {
            sliderHandle.x = calculateHandlePosition(zoomLevel)
        }
    }

    Rectangle {
        id: sliderTrackContainer
        anchors.fill: parent
        color: "transparent"
        radius: vpx(8)
        border.color: borderColor
        border.width: vpx(1)

        Item {
            id: contentContainer
            anchors.fill: parent
            anchors.margins: vpx(5)

            Column {
                anchors.centerIn: parent
                spacing: vpx(2)
                width: parent.width

                Item {
                    id: sliderContainer
                    width: parent.width
                    height: vpx(28)

                    Rectangle {
                        id: sliderTrack
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: vpx(15)
                        anchors.rightMargin: vpx(15)
                        height: vpx(4)
                        color: borderColor
                        radius: height / 2

                        Rectangle {
                            id: progressBar
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: {
                                var handleCenter = sliderHandle.x + sliderHandle.width/2
                                var trackStart = sliderTrack.x
                                var relativeCenter = handleCenter - trackStart
                                var progress = relativeCenter / parent.width
                                return Math.max(0, Math.min(parent.width, parent.width * progress))
                            }
                            height: parent.height
                            color: accentColor
                            radius: height / 2
                            opacity: 0.6
                        }

                        Repeater {
                            model: zoomLevels.length

                            Rectangle {
                                id: dotPoint
                                width: vpx(6)
                                height: vpx(6)
                                radius: width / 2
                                anchors.verticalCenter: parent.verticalCenter

                                x: parent.width * (index / (zoomLevels.length - 1)) - width/2

                                color: zoomLevels[index] <= zoomControl.zoomLevel ? accentColor : "#555"
                                border.color: "#ffffff"
                                border.width: vpx(1)

                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }

                                Behavior on scale {
                                    NumberAnimation { duration: 150 }
                                }

                                Text {
                                    text: zoomLevels[index].toFixed(1) + "×"
                                    color: parent.color === accentColor ? accentColor : secondaryTextColor
                                    font.family: condensedFontFamily
                                    font.pixelSize: vpx(9)
                                    font.bold: parent.color === accentColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.bottom
                                    anchors.topMargin: vpx(5)

                                    Behavior on color {
                                        ColorAnimation { duration: 200 }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: vpx(-7)
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onEntered: {
                                        parent.scale = 1.3
                                    }

                                    onExited: {
                                        parent.scale = 1.0
                                    }

                                    onClicked: {
                                        zoomControl.zoomLevel = zoomLevels[index]
                                        zoomControl.zoomChanged(zoomControl.zoomLevel)
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: sliderHandle
                        width: vpx(18)
                        height: vpx(18)
                        radius: width / 2
                        color: accentColor
                        border.color: "#ffffff"
                        border.width: vpx(2)
                        anchors.verticalCenter: sliderTrack.verticalCenter

                        Component.onCompleted: {
                            x = calculateHandlePosition(zoomControl.zoomLevel)
                        }

                        Behavior on x {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.4
                            height: parent.height * 0.4
                            radius: width / 2
                            color: "#ffffff"
                            opacity: 0.3
                        }

                        /*MouseArea {
                            id: sliderMouseArea
                            anchors.fill: parent
                            anchors.margins: vpx(-10)
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true

                            property bool dragging: false
                            property real startX: 0
                            property real startHandleX: 0

                            onPressed: {
                                dragging = true
                                startX = mouseX
                                startHandleX = sliderHandle.x
                            }

                            onReleased: {
                                dragging = false
                                snapToNearest()
                            }

                            onPositionChanged: {
                                if (dragging && mouse.buttons & Qt.LeftButton) {
                                    var deltaX = mouseX - startX
                                    var newX = startHandleX + deltaX
                                    var minX = sliderTrack.x - sliderHandle.width/2
                                    var maxX = sliderTrack.x + sliderTrack.width - sliderHandle.width/2
                                    newX = Math.max(minX, Math.min(maxX, newX))

                                    sliderHandle.x = newX
                                    updateZoomLevelFromPosition()
                                }
                            }

                            function updateZoomLevelFromPosition() {
                                var handleCenter = sliderHandle.x + sliderHandle.width/2
                                var relativePos = (handleCenter - sliderTrack.x) / sliderTrack.width
                                var rawIndex = relativePos * (zoomLevels.length - 1)
                                var index = Math.round(rawIndex)
                                index = Math.max(0, Math.min(zoomLevels.length - 1, index))

                                zoomControl.zoomLevel = zoomLevels[index]
                            }

                            function snapToNearest() {
                                updateZoomLevelFromPosition()
                                zoomControl.zoomChanged(zoomControl.zoomLevel)
                            }
                        }*/

                        Rectangle {
                            width: vpx(28)
                            height: vpx(15)
                            radius: vpx(4)
                            color: accentColor
                            anchors.bottom: parent.top
                            anchors.bottomMargin: vpx(6)
                            anchors.horizontalCenter: parent.horizontalCenter
                            //visible: sliderMouseArea.containsMouse || sliderMouseArea.dragging
                            visible: true
                            opacity: visible ? 1.0 : 0.0

                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }

                            Canvas {
                                width: vpx(8)
                                height: vpx(4)
                                anchors.top: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                contextType: "2d"

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.fillStyle = accentColor
                                    ctx.beginPath()
                                    ctx.moveTo(0, 0)
                                    ctx.lineTo(width, 0)
                                    ctx.lineTo(width / 2, height)
                                    ctx.closePath()
                                    ctx.fill()
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: zoomControl.zoomLevel.toFixed(1) + "×"
                                color: "#ffffff"
                                font.family: condensedFontFamily
                                font.pixelSize: vpx(11)
                                font.bold: true
                            }
                        }

                        scale: 1.0  //sliderMouseArea.containsMouse || sliderMouseArea.dragging ? 1.3 : 1.0

                        Behavior on scale {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }
}

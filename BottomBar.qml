import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.12

Rectangle {
    id: bottomBar
    color: root.panelColor
    border.color: root.borderColor
    border.width: vpx(1)
    radius: vpx(8)

    property bool videoIsPlaying: false

    function vpx(value) {
        return Math.round(value * root.height / 1080)
    }

    Canvas {
        id: audioVisualization
        anchors.fill: parent
        opacity: {
            var musicPlaying = musicPlayerLoader.item && musicPlayerLoader.item.isPlaying
            var videoPlaying = bottomBar.videoIsPlaying
            return (musicPlaying || videoPlaying) ? 0.15 : 0
        }
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
        }

        property int barCount: 250
        property var barHeights: []
        property real time: 0
        property real beatIntensity: 0
        property int beatCounter: 0

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var barWidth = width / barCount
            var actualBarWidth = barWidth * 0.8
            var gradient = ctx.createLinearGradient(0, 0, width, 0)
            gradient.addColorStop(0, Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.6))
            gradient.addColorStop(0.5, Qt.rgba(root.accentColor.r * 1.2, root.accentColor.g * 1.2, root.accentColor.b * 1.5, 0.8))
            gradient.addColorStop(1, Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.6))

            ctx.fillStyle = gradient

            for (var i = 0; i < barCount; i++) {
                var barHeight = barHeights[i] || 0
                var x = i * barWidth + (barWidth - actualBarWidth) / 2
                var y = height - barHeight

                ctx.fillRect(x, y, actualBarWidth, barHeight)
            }
        }

        Timer {
            interval: 50
            running: {
                var musicPlaying = musicPlayerLoader.item && musicPlayerLoader.item.isPlaying
                var videoPlaying = bottomBar.videoIsPlaying
                return musicPlaying || videoPlaying
            }
            repeat: true
            onTriggered: {
                parent.time += 0.1
                parent.beatCounter++

                if (parent.beatCounter % 12 === 0) {
                    parent.beatIntensity = 0.8 + Math.random() * 0.4
                } else if (parent.beatCounter % 6 === 0) {
                    parent.beatIntensity = 0.4 + Math.random() * 0.3
                } else {
                    parent.beatIntensity *= 0.85
                }

                for (var i = 0; i < parent.barCount; i++) {
                    var freq1 = Math.sin(parent.time * 2 + i * 0.3) * 0.5 + 0.5
                    var freq2 = Math.sin(parent.time * 3.5 + i * 0.15) * 0.5 + 0.5
                    var freq3 = Math.sin(parent.time * 1.2 + i * 0.5) * 0.5 + 0.5

                    var randomSpike = 0
                    if (parent.beatIntensity > 0.3) {
                        var spikeChance = Math.random()
                        if (spikeChance > 0.85) {
                            randomSpike = parent.beatIntensity * (0.5 + Math.random() * 0.5)
                        }
                    }

                    var baseIntensity = (freq1 * 0.3 + freq2 * 0.25 + freq3 * 0.25)
                    var beatBoost = parent.beatIntensity * 0.3
                    var intensity = Math.min(1.0, baseIntensity + beatBoost + randomSpike)
                    var baseHeight = parent.height * 0.08
                    var maxHeight = parent.height * 0.35
                    var targetHeight = baseHeight + (maxHeight - baseHeight) * intensity

                    var smoothFactor = parent.beatIntensity > 0.4 ? 0.5 : 0.7
                    if (!parent.barHeights[i]) {
                        parent.barHeights[i] = targetHeight
                    } else {
                        parent.barHeights[i] = parent.barHeights[i] * smoothFactor + targetHeight * (1 - smoothFactor)
                    }
                }

                parent.requestPaint()
            }
        }

        NumberAnimation {
            id: fadeInAnimation
            target: audioVisualization
            property: "time"
            from: 0
            to: 100
            duration: 2000
            running: {
                var musicPlaying = musicPlayerLoader.item && musicPlayerLoader.item.isPlaying
                var videoPlaying = bottomBar.videoIsPlaying
                return musicPlaying || videoPlaying
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: vpx(1)
        border.color: root.accentColor
        radius: parent.radius
        opacity: {
            var musicPlaying = musicPlayerLoader.item && musicPlayerLoader.item.isPlaying
            var videoPlaying = bottomBar.videoIsPlaying
            return (musicPlaying || videoPlaying) ? 0.1 : 0
        }

        Behavior on opacity {
            NumberAnimation { duration: 500 }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: vpx(8)
        spacing: vpx(20)
        z: 10

        Loader {
            id: musicPlayerLoader
            Layout.fillHeight: true
            Layout.preferredWidth: vpx(500)
            Layout.maximumWidth: vpx(500)
            sourceComponent: Component {
                MusicPlayer {
                    id: musicPlayerInstance
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: vpx(10)
        }

        RecentActivityPanel {
            id: recentActivityPanel
            Layout.fillHeight: true
            Layout.preferredWidth: vpx(450)
            Layout.maximumWidth: vpx(450)
            Layout.minimumWidth: vpx(350)
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: vpx(20)
        }

        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: vpx(250)

            RowLayout {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: vpx(15)

                Row {
                    spacing: vpx(8)

                    Rectangle {
                        width: vpx(30)
                        height: vpx(18)
                        color: "transparent"
                        border.color: root.secondaryTextColor
                        border.width: vpx(1)
                        radius: vpx(3)
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !isNaN(api.device.batteryPercent)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: vpx(2)
                            width: (parent.width - vpx(4)) * api.device.batteryPercent
                            color: api.device.batteryPercent > 0.2 ? "#4caf50" : "#f44336"
                            radius: vpx(2)
                        }

                        Rectangle {
                            width: vpx(3)
                            height: vpx(8)
                            color: root.secondaryTextColor
                            anchors.left: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            radius: vpx(1)
                        }
                    }

                    Text {
                        text: Math.round(api.device.batteryPercent * 100) + "%"
                        font.family: root.fontFamily
                        font.pixelSize: vpx(24)
                        font.bold: true
                        color: root.textColor
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !isNaN(api.device.batteryPercent)
                    }

                    Image {
                        width: vpx(50)
                        height: vpx(50)
                        source: "assets/images/icons/no_battery.svg"
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                        anchors.verticalCenter: parent.verticalCenter
                        visible: isNaN(api.device.batteryPercent)
                    }
                }

                Rectangle {
                    Layout.preferredWidth: vpx(1)
                    Layout.preferredHeight: vpx(70)
                    color: root.borderColor
                }

                Column {
                    spacing: vpx(2)
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        spacing: vpx(8)

                        Text {
                            id: timeText
                            text: Qt.formatTime(new Date(), "hh:mm")
                            font.family: root.condensedFontFamily
                            font.pixelSize: vpx(28)
                            font.bold: true
                            color: root.textColor
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Image {
                            id: hourIcon
                            width: vpx(28)
                            height: vpx(28)
                            anchors.verticalCenter: parent.verticalCenter
                            source: {
                                var currentDate = new Date()
                                var hour24 = currentDate.getHours()
                                var hour12 = hour24 % 12
                                if (hour12 === 0) hour12 = 12
                                    return "assets/images/icons/CLOCK/hour_" + hour12 + ".svg"
                            }
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }
                    }

                    Text {
                        id: dateText
                        text: Qt.formatDate(new Date(), "dd/MM/yy")
                        font.family: root.fontFamily
                        font.pixelSize: vpx(25)
                        color: root.secondaryTextColor
                    }
                }
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            var currentDate = new Date()
            timeText.text = Qt.formatTime(currentDate, "hh:mm")
            dateText.text = Qt.formatDate(currentDate, "dd/MM/yy")

            var hour24 = currentDate.getHours()
            var hour12 = hour24 % 12
            if (hour12 === 0) hour12 = 12
                hourIcon.source = "assets/images/icons/CLOCK/hour_" + hour12 + ".svg"
        }
    }
}

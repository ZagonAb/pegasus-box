import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: bottomBar
    color: root.panelColor
    border.color: root.borderColor
    border.width: vpx(1)
    radius: vpx(8)

    function vpx(value) {
        return Math.round(value * root.height / 1080)
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: vpx(12)
        spacing: vpx(20)

        MusicPlayer {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumWidth: vpx(600)
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Item {
            Layout.fillHeight: true

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
                        text: !isNaN(api.device.batteryPercent) ?
                        Math.round(api.device.batteryPercent * 100) + "%" :
                        "N/A"
                        font.family: root.fontFamily
                        font.pixelSize: vpx(24)
                        font.bold: !isNaN(api.device.batteryPercent)
                        color: !isNaN(api.device.batteryPercent) ? root.textColor : root.secondaryTextColor
                        anchors.verticalCenter: parent.verticalCenter
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

                    Text {
                        id: timeText
                        text: Qt.formatTime(new Date(), "hh:mm")
                        font.family: root.condensedFontFamily
                        font.pixelSize: vpx(28)
                        font.bold: true
                        color: root.textColor
                    }

                    Text {
                        text: Qt.formatDate(new Date(), "ddd, MMM dd")
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
            timeText.text = Qt.formatTime(new Date(), "hh:mm")
        }
    }
}

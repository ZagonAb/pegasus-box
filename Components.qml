import QtQuick 2.15

// Botón reutilizable
Item {
    id: button

    property string text: ""
    property color color: "#0078d7"
    property color textColor: "#ffffff"
    property alias radius: background.radius

    signal clicked()

    Rectangle {
        id: background
        anchors.fill: parent
        color: button.color
        radius: vpx(4)

        Text {
            anchors.centerIn: parent
            text: button.text
            color: button.textColor
            font.family: global.fonts.condensed
            font.pixelSize: vpx(16)
            font.bold: true
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.clicked()

        onEntered: background.opacity = 0.8
        onExited: background.opacity = 1
        onPressed: background.opacity = 0.6
        onReleased: background.opacity = 0.8
    }
}

// Barra de progreso
Item {
    id: progressBar

    property real value: 0 // 0.0 - 1.0
    property color backgroundColor: "#333"
    property color fillColor: "#0078d7"

    Rectangle {
        id: track
        anchors.fill: parent
        color: progressBar.backgroundColor
        radius: height / 2
    }

    Rectangle {
        id: fill
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: parent.width * Math.max(0, Math.min(1, progressBar.value))
        color: progressBar.fillColor
        radius: height / 2
    }
}

// Componente para filas de detalle
Item {
    id: detailRow

    property string label: ""
    property string value: ""

    width: parent ? parent.width : 0
    height: vpx(20)

    Text {
        id: labelText
        text: label
        color: "#b0b0b0"
        font.family: global.fonts.condensed
        font.pixelSize: vpx(14)
    }

    Text {
        anchors {
            left: labelText.right
            leftMargin: vpx(10)
            right: parent.right
            verticalCenter: labelText.verticalCenter
        }
        text: value
        color: "#ffffff"
        font.family: global.fonts.sans
        font.pixelSize: vpx(14)
        elide: Text.ElideRight
    }
}

import QtQuick 2.15

Item {
    id: detailRow

    property string label: ""
    property string value: ""
    property color labelColor: "#b0b0b0"
    property color valueColor: "#ffffff"
    property int labelFontSize: vpx(14)
    property int valueFontSize: vpx(14)
    property bool showDivider: false

    width: parent ? parent.width : 0
    height: vpx(20)

    Text {
        id: labelText
        text: detailRow.label
        color: detailRow.labelColor
        font.family: condensedFontFamily
        font.pixelSize: detailRow.labelFontSize
    }

    Text {
        anchors {
            left: labelText.right
            leftMargin: vpx(10)
            right: parent.right
            verticalCenter: labelText.verticalCenter
        }
        text: detailRow.value
        color: detailRow.valueColor
        font.family: fontFamily
        font.pixelSize: detailRow.valueFontSize
        elide: Text.ElideRight
        wrapMode: Text.WrapAnywhere
        maximumLineCount: 2
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 1
        color: "#333"
        visible: detailRow.showDivider
    }
}

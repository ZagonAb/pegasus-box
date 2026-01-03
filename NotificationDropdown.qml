import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.12

Rectangle {
    id: notificationDropdown
    visible: false
    width: vpx(550)
    height: vpx(500)
    color: root.panelColor
    border.color: root.accentColor
    border.width: vpx(2)
    radius: vpx(12)

    property real targetY: 0
    property real initialY: vpx(50)
    property bool animationRunning: false
    property int currentCollectionProgressIndex: 0

    transform: Translate {
        id: translateTransform
        y: initialY
    }

    opacity: visible ? 1.0 : 0.0

    property int notificationCount: 0
    property var allNotifications: []
    property color accentColor: "#0078d7"
    property color panelColor: "#1a1a1a"
    property color textColor: "#ffffff"
    property color secondaryTextColor: "#b0b0b0"
    property string fontFamily: "sans-serif"
    property string condensedFontFamily: "sans-serif"

    signal notificationClicked(var game)

    function vpx(value) {
        return Math.round(value * 1080 / 1080)
    }

    function loadNotifications(notifications) {
        notificationListModel.clear()
        notificationCount = 0

        if (!notifications || notifications.length === 0) {
            return
        }

        for (var i = 0; i < notifications.length; i++) {
            var notif = notifications[i]
            var safeColor = notif.color || accentColor
            var colorObj = {
                r: safeColor.r !== undefined ? safeColor.r : 0.1,
                g: safeColor.g !== undefined ? safeColor.g : 0.5,
                b: safeColor.b !== undefined ? safeColor.b : 0.8
            }

            var hasGameValue = (notif.game !== null && notif.game !== undefined)

            if (hasGameValue) {
                notificationListModel.append({
                    title: notif.title || "",
                    message: notif.message || "",
                    icon: notif.icon || "",
                    notificationColor: colorObj,
                    hasGame: true,
                    gameData: notif.game,
                    notificationType: notif.type || "",
                    collectionShortName: notif.collectionShortName || ""
                })
            } else {
                notificationListModel.append({
                    title: notif.title || "",
                    message: notif.message || "",
                    icon: notif.icon || "",
                    notificationColor: colorObj,
                    hasGame: false,
                    notificationType: notif.type || "",
                    collectionShortName: notif.collectionShortName || ""
                })
            }
        }

        notificationCount = notifications.length

        if (visible) {
            showAnimation.start()
        }
    }

    function showWithAnimation() {
        if (animationRunning) return

            animationRunning = true
            visible = true
            showAnimation.start()
    }

    function hideWithAnimation() {
        if (animationRunning) return

            animationRunning = true
            hideAnimation.start()
    }

    function updateCollectionProgress() {
        if (!visible) return

            currentCollectionProgressIndex++
            var collectionItems = []

            for (var i = 0; i < notificationListModel.count; i++) {
                var item = notificationListModel.get(i)
                if (item && item.notificationType === "collection_progress") {
                    collectionItems.push({
                        index: i,
                        item: item
                    })
                }
            }

            if (collectionItems.length > 0) {
                var currentItem = collectionItems[currentCollectionProgressIndex % collectionItems.length]
                var collectionIndex = currentItem.index

                var tempPanel = recentActivityPanelComponent.createObject(notificationDropdown, {
                    gameModel: api.allGames,
                    visible: false,
                    dropdownVisible: true
                })

                if (tempPanel) {
                    tempPanel.allCollectionProgress = tempPanel.calculateCollectionProgress()
                    if (tempPanel.allCollectionProgress.length > 0) {
                        var newProgress = tempPanel.allCollectionProgress[currentCollectionProgressIndex % tempPanel.allCollectionProgress.length]

                        notificationListModel.setProperty(collectionIndex, "title", newProgress.name + " Progress")
                        notificationListModel.setProperty(collectionIndex, "message", "Played " + newProgress.played + " of " + newProgress.total + " games (" + newProgress.percent + "%)")
                        notificationListModel.setProperty(collectionIndex, "collectionShortName", newProgress.shortName)

                        var notifItem = notificationListView.itemAtIndex(collectionIndex)
                        if (notifItem && notifItem.horizontalSlideAnimation) {
                            notifItem.horizontalSlideAnimation.start()
                        }
                    }
                    tempPanel.destroy()
                }
            }
    }

    layer.enabled: true
    layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: vpx(-8)
        radius: vpx(20)
        samples: 40
        color: Qt.rgba(0, 0, 0, 0.5)
    }

    Rectangle {
        id: dropdownHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: vpx(50)
        color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.1)
        radius: vpx(12)

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.radius
            color: parent.color
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: vpx(15)
            anchors.rightMargin: vpx(15)

            Text {
                Layout.fillWidth: true
                text: "All Notifications"
                font.family: condensedFontFamily
                font.pixelSize: vpx(22)
                font.bold: true
                color: textColor
            }

            Rectangle {
                Layout.preferredWidth: vpx(30)
                Layout.preferredHeight: vpx(30)
                radius: vpx(15)
                color: accentColor
                visible: notificationCount > 0

                Text {
                    anchors.centerIn: parent
                    text: Math.min(notificationCount, 99)
                    font.family: condensedFontFamily
                    font.pixelSize: vpx(14)
                    font.bold: true
                    color: "white"
                }
            }
        }
    }

    Rectangle {
        id: scrollBar
        anchors.right: parent.right
        anchors.top: dropdownHeader.bottom
        anchors.bottom: parent.bottom
        anchors.margins: vpx(5)
        width: vpx(8)
        radius: vpx(4)
        color: Qt.rgba(secondaryTextColor.r, secondaryTextColor.g, secondaryTextColor.b, 0.1)
        visible: notificationListView.contentHeight > notificationListView.height

        Rectangle {
            id: scrollHandle
            width: parent.width
            height: Math.max(vpx(30), parent.height * (notificationListView.height / notificationListView.contentHeight))
            radius: parent.radius
            color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.5)
            y: {
                var maxY = scrollBar.height - height
                var ratio = notificationListView.contentY / (notificationListView.contentHeight - notificationListView.height)
                return maxY * ratio
            }

            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }
    }

    ListView {
        id: notificationListView
        anchors.top: dropdownHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: vpx(10)
        anchors.rightMargin: vpx(20)
        clip: true
        spacing: vpx(8)

        model: ListModel {
            id: notificationListModel
        }

        delegate: Rectangle {
            id: notificationDelegate
            width: notificationListView.width
            height: vpx(80)
            color: {
                var nc = model.notificationColor
                if (!nc) {
                    return Qt.rgba(0.1, 0.5, 0.8, 0.05)
                }
                if (typeof nc === "string") {
                    return Qt.rgba(0.1, 0.5, 0.8, 0.05)
                }
                return Qt.rgba(nc.r || 0.1, nc.g || 0.5, nc.b || 0.8, 0.05)
            }
            border.width: vpx(1)
            border.color: {
                var nc = model.notificationColor
                if (!nc) {
                    return Qt.rgba(0.1, 0.5, 0.8, 0.2)
                }
                if (typeof nc === "string") {
                    return Qt.rgba(0.1, 0.5, 0.8, 0.2)
                }
                return Qt.rgba(nc.r || 0.1, nc.g || 0.5, nc.b || 0.8, 0.2)
            }
            radius: vpx(8)

            property color itemColor: {
                var nc = model.notificationColor
                if (!nc) {
                    return notificationDropdown.accentColor
                }
                if (typeof nc === "string") {
                    return notificationDropdown.accentColor
                }
                return Qt.rgba(nc.r || 0.1, nc.g || 0.5, nc.b || 0.8, 1.0)
            }

            property bool isCollectionProgress: model.notificationType === "collection_progress"

            SequentialAnimation {
                id: horizontalSlideAnimation

                PropertyAnimation {
                    target: notificationDelegate
                    property: "x"
                    to: notificationDelegate.width
                    duration: 300
                    easing.type: Easing.InCubic
                }

                ScriptAction {
                    script: {
                        notificationDelegate.x = -notificationDelegate.width
                    }
                }

                PropertyAnimation {
                    target: notificationDelegate
                    property: "x"
                    to: 0
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation { duration: 200 }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: vpx(10)
                spacing: vpx(12)

                Rectangle {
                    Layout.preferredWidth: vpx(50)
                    Layout.preferredHeight: vpx(50)
                    Layout.alignment: Qt.AlignVCenter
                    color: "transparent"

                    Image {
                        anchors.fill: parent
                        source: model.icon || ""
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                        opacity: 0.8
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: vpx(4)

                    Text {
                        Layout.fillWidth: true
                        text: model.title || ""
                        font.family: notificationDropdown.condensedFontFamily
                        font.pixelSize: vpx(16)
                        font.bold: true
                        color: parent.parent.parent.itemColor
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: model.message || ""
                        font.family: notificationDropdown.fontFamily
                        font.pixelSize: vpx(14)
                        color: notificationDropdown.textColor
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    visible: model.hasGame === true
                    Layout.preferredWidth: vpx(35)
                    Layout.preferredHeight: vpx(35)
                    Layout.alignment: Qt.AlignVCenter
                    radius: vpx(18)
                    color: {
                        var nc = model.notificationColor
                        if (typeof nc === "string") {
                            return Qt.rgba(0.1, 0.5, 0.8, 0.2)
                        }
                        return Qt.rgba(nc.r || 0.1, nc.g || 0.5, nc.b || 0.8, 0.2)
                    }

                    Image {
                        anchors.centerIn: parent
                        width: parent.width * 0.5
                        height: parent.height * 0.5
                        source: "assets/images/icons/play.svg"
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: {
                            var gameIndex = index
                            var gameItem = notificationListModel.get(gameIndex)
                            if (gameItem && gameItem.gameData) {
                                notificationDropdown.notificationClicked(gameItem.gameData)
                            }
                        }

                        onEntered: {
                            parent.scale = 1.1
                        }

                        onExited: {
                            parent.scale = 1.0
                        }
                    }

                    Behavior on scale {
                        NumberAnimation { duration: 150 }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                z: -1

                onEntered: {
                    var nc = model.notificationColor
                    if (!nc) {
                        parent.color = Qt.rgba(0.1, 0.5, 0.8, 0.1)
                        return
                    }
                    if (typeof nc === "string") {
                        parent.color = Qt.rgba(0.1, 0.5, 0.8, 0.1)
                    } else {
                        parent.color = Qt.rgba(nc.r || 0.1, nc.g || 0.5, nc.b || 0.8, 0.1)
                    }
                }

                onExited: {
                    var nc = model.notificationColor
                    if (!nc) {
                        parent.color = Qt.rgba(0.1, 0.5, 0.8, 0.05)
                        return
                    }
                    if (typeof nc === "string") {
                        parent.color = Qt.rgba(0.1, 0.5, 0.8, 0.05)
                    } else {
                        parent.color = Qt.rgba(nc.r || 0.1, nc.g || 0.5, nc.b || 0.8, 0.05)
                    }
                }
            }
        }

        Text {
            visible: notificationListModel.count === 0
            anchors.centerIn: parent
            text: "No notifications available"
            font.family: notificationDropdown.fontFamily
            font.pixelSize: vpx(16)
            color: notificationDropdown.secondaryTextColor
        }
    }

    Component {
        id: recentActivityPanelComponent
        RecentActivityPanel {}
    }

    Timer {
        id: collectionProgressTimer
        interval: 5000
        running: notificationDropdown.visible
        repeat: true
        onTriggered: {
            notificationDropdown.updateCollectionProgress()
        }
    }

    SequentialAnimation {
        id: showAnimation

        PropertyAction {
            target: translateTransform
            property: "y"
            value: initialY
        }
        PropertyAction {
            target: notificationDropdown
            property: "opacity"
            value: 0
        }

        PropertyAction {
            target: notificationDropdown
            property: "visible"
            value: true
        }

        ParallelAnimation {
            NumberAnimation {
                target: translateTransform
                property: "y"
                from: initialY
                to: targetY
                duration: 300
                easing.type: Easing.OutBack
                easing.overshoot: 0.7
            }
            NumberAnimation {
                target: notificationDropdown
                property: "opacity"
                from: 0
                to: 1
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        ScriptAction {
            script: {
                notificationDropdown.animationRunning = false
            }
        }
    }

    SequentialAnimation {
        id: hideAnimation

        ParallelAnimation {
            NumberAnimation {
                target: translateTransform
                property: "y"
                from: targetY
                to: initialY
                duration: 250
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: notificationDropdown
                property: "opacity"
                from: 1
                to: 0
                duration: 200
                easing.type: Easing.InCubic
            }
        }

        PropertyAction {
            target: notificationDropdown
            property: "visible"
            value: false
        }

        ScriptAction {
            script: {
                notificationDropdown.animationRunning = false
                collectionProgressTimer.stop()
            }
        }
    }

    Behavior on opacity {
        enabled: !animationRunning
        NumberAnimation { duration: 200 }
    }

}

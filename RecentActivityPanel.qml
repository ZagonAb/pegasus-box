import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.12
import "utils.js" as Utils

Item {
    id: recentActivityPanel

    property var gameModel: api.allGames
    property var currentNotification: notifications[currentNotificationIndex]
    property int currentNotificationIndex: 0
    property int autoAdvanceInterval: 5000
    property var notifications: []
    property color infoColor: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.9)
    property color successColor: "#4CAF50"
    property color warningColor: "#FF9800"
    property color highlightColor: "#E91E63"
    property color achievementColor: "#9C27B0"

    function getSystemImagePath(game) {
        if (!game || !game.collections || game.collections.count === 0) {
            return "";
        }

        var gameCollection = game.collections.get(0);
        if (!gameCollection || !gameCollection.shortName) {
            return "";
        }

        return "assets/images/systems/" + gameCollection.shortName.toLowerCase() + ".png";
    }

    function getCollectionShortName(game) {
        if (!game || !game.collections || game.collections.count === 0) {
            return "??";
        }

        var gameCollection = game.collections.get(0);
        if (!gameCollection || !gameCollection.shortName) {
            return "??";
        }

        return gameCollection.shortName.substring(0, 2).toUpperCase();
    }

    function updateNotifications() {
        var newNotifications = []
        var lastPlayedGame = findLastPlayedGame()

        if (lastPlayedGame) {
            var hoursAgo = Math.floor((new Date() - lastPlayedGame.lastPlayed) / (1000 * 60 * 60))
            var daysAgo = Math.floor(hoursAgo / 24)

            newNotifications.push({
                type: "last_played",
                game: lastPlayedGame,
                title: "Continue Playing",
                message: formatLastPlayedMessage(lastPlayedGame, hoursAgo, daysAgo),
                                  color: highlightColor,
                                  icon: "assets/images/icons/history.svg"
            })

            newNotifications.push({
                type: "stats",
                game: lastPlayedGame,
                title: "Your Stats",
                message: formatStatsMessage(lastPlayedGame),
                                  color: infoColor,
                                  icon: "assets/images/icons/stats.svg"
            })
        }

        var favoriteCount = countFavorites()
        if (favoriteCount > 0) {
            newNotifications.push({
                type: "favorites",
                game: null,
                title: "Favorites",
                message: favoriteCount + " game" + (favoriteCount > 1 ? "s" : "") + " marked as favorite",
                                  color: warningColor,
                                  icon: "assets/images/icons/favorite-yes.svg"
            })
        }

        var mostPlayedGame = findMostPlayedGame()
        if (mostPlayedGame && mostPlayedGame.playTime > 3600) {
            newNotifications.push({
                type: "most_played",
                game: mostPlayedGame,
                title: "Most Played",
                message: "You've spent " + formatPlayTime(mostPlayedGame.playTime) + " playing " +
                Utils.cleanGameTitle(mostPlayedGame.title),
                                  color: successColor,
                                  icon: "assets/images/icons/time.svg"
            })
        }

        var playedGamesCount = countPlayedGames()
        if (playedGamesCount > 0) {
            newNotifications.push({
                type: "total_played",
                game: null,
                title: "Your Collection",
                message: "You've played " + playedGamesCount + " of " + gameModel.count + " games",
                color: achievementColor,
                icon: "assets/images/icons/play.svg"
            })
        }

        var recentGames = findRecentlyPlayedGames(7)
        if (recentGames.length > 1) {
            newNotifications.push({
                type: "recent_games",
                game: null,
                title: "Recent Activity",
                message: recentGames.length + " games played this week",
                color: infoColor,
                icon: "assets/images/icons/history.svg"
            })
        }

        if (newNotifications.length === 0) {
            newNotifications.push({
                type: "welcome",
                game: null,
                title: "Welcome to Pegasus Box",
                message: "Launch a game to start your journey!",
                color: infoColor,
                icon: "assets/images/icons/play.svg"
            })
        }

        notifications = newNotifications

        if (notifications.length > 1) {
            notificationTimer.restart()
        }
    }

    function findLastPlayedGame() {
        var lastPlayed = null
        var lastTime = null

        for (var i = 0; i < gameModel.count; i++) {
            var game = gameModel.get(i)
            if (game.lastPlayed && game.lastPlayed.toString() !== "Invalid Date") {
                if (!lastTime || game.lastPlayed > lastTime) {
                    lastTime = game.lastPlayed
                    lastPlayed = game
                }
            }
        }

        return lastPlayed
    }

    function findMostPlayedGame() {
        var mostPlayed = null
        var maxTime = 0

        for (var i = 0; i < gameModel.count; i++) {
            var game = gameModel.get(i)
            if (game.playTime && game.playTime > maxTime) {
                maxTime = game.playTime
                mostPlayed = game
            }
        }

        return mostPlayed
    }

    function countFavorites() {
        var count = 0
        for (var i = 0; i < gameModel.count; i++) {
            if (gameModel.get(i).favorite) {
                count++
            }
        }
        return count
    }

    function countPlayedGames() {
        var count = 0
        for (var i = 0; i < gameModel.count; i++) {
            if (gameModel.get(i).playCount > 0) {
                count++
            }
        }
        return count
    }

    function findRecentlyPlayedGames(days) {
        var recentGames = []
        var cutoffDate = new Date()
        cutoffDate.setDate(cutoffDate.getDate() - days)

        for (var i = 0; i < gameModel.count; i++) {
            var game = gameModel.get(i)
            if (game.lastPlayed && game.lastPlayed.toString() !== "Invalid Date" && game.lastPlayed > cutoffDate) {
                recentGames.push(game)
            }
        }

        return recentGames
    }

    function formatLastPlayedMessage(game, hoursAgo, daysAgo) {
        if (daysAgo === 0) {
            if (hoursAgo === 0) return "Just played " + Utils.cleanGameTitle(game.title)
                if (hoursAgo === 1) return "Played " + Utils.cleanGameTitle(game.title) + " 1 hour ago"
                    return "Played " + Utils.cleanGameTitle(game.title) + " " + hoursAgo + " hours ago"
        } else if (daysAgo === 1) {
            return "Played " + Utils.cleanGameTitle(game.title) + " yesterday"
        } else {
            return "Played " + Utils.cleanGameTitle(game.title) + " " + daysAgo + " days ago"
        }
    }

    function formatStatsMessage(game) {
        var messages = [
            "Ready for another session?",
            "Let's beat your high score!",
            "Continue your adventure",
            "Unfinished business awaits",
            "Jump back into the action"
        ]

        if (game.playTime && game.playTime > 0) {
            return messages[Math.floor(Math.random() * messages.length)] +
            " • " + formatPlayTime(game.playTime) + " total"
        }

        return messages[Math.floor(Math.random() * messages.length)]
    }

    function formatPlayTime(seconds) {
        var hours = Math.floor(seconds / 3600)
        var minutes = Math.floor((seconds % 3600) / 60)

        if (hours > 0) {
            return hours + "h" + (minutes > 0 ? " " + minutes + "m" : "")
        }
        return minutes + "m"
    }

    Component.onCompleted: {
        updateNotifications()
    }

    Timer {
        id: notificationTimer
        interval: autoAdvanceInterval
        running: notifications.length > 1
        repeat: true
        onTriggered: {
            slideOutAnimation.start()
        }
    }

    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            id: currentCard
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height
            y: 0
            color: "transparent"

            Rectangle {
                id: cardContent
                anchors.fill: parent
                anchors.margins: vpx(4)
                color: "transparent"

                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: vpx(4)
                    radius: vpx(12)
                    samples: 24
                    color: Qt.rgba(currentNotification.color.r, currentNotification.color.g, currentNotification.color.b, 0.3)
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: vpx(18)

                    Item {
                        Layout.preferredWidth: vpx(100)
                        Layout.preferredHeight: vpx(60)
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            id: imageContainer
                            anchors.fill: parent
                            radius: vpx(6)
                            color: "transparent"

                            Item {
                                id: gameContent
                                anchors.fill: parent
                                anchors.margins: vpx(2)
                                visible: currentNotification.game

                                Image {
                                    id: gameImage
                                    anchors.fill: parent
                                    source: currentNotification.game && currentNotification.game.assets ?
                                    currentNotification.game.assets.screenshot : ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: true
                                    mipmap: true
                                    visible: status === Image.Ready

                                    Behavior on opacity {
                                        NumberAnimation { duration: 300 }
                                    }
                                }

                                Rectangle {
                                    id: systemIconContainer
                                    anchors.centerIn: parent
                                    anchors.fill: parent
                                    radius: vpx(6)
                                    color: "transparent"
                                    visible: !gameImage.visible

                                    Image {
                                        id: systemImage
                                        anchors.centerIn: parent
                                        width: vpx(80)
                                        height: vpx(80)
                                        anchors.margins: vpx(5)
                                        source: currentNotification.game ?
                                        recentActivityPanel.getSystemImagePath(currentNotification.game) : ""
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        mipmap: true
                                        visible: status === Image.Ready && source !== ""
                                    }

                                    Text {
                                        id: shrtNameCollection
                                        anchors.centerIn: parent
                                        text: currentNotification.game ?
                                        recentActivityPanel.getCollectionShortName(currentNotification.game) : "??"
                                        color: root.textColor
                                        font.family: root.condensedFontFamily
                                        font.pixelSize: vpx(32)
                                        font.bold: true
                                        visible: !systemImage.visible || systemImage.status !== Image.Ready
                                    }
                                }
                            }

                            Item {
                                id: notificationContent
                                anchors.fill: parent
                                anchors.margins: vpx(2)
                                visible: !currentNotification.game

                                Image {
                                    id: backupIcon
                                    anchors.centerIn: parent
                                    width: vpx(60)
                                    height: vpx(60)
                                    source: currentNotification.icon
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
                                    opacity: 0.9

                                    Behavior on opacity {
                                        NumberAnimation { duration: 300 }
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: vpx(8)

                        Text {
                            Layout.fillWidth: true
                            text: currentNotification.title
                            color: currentNotification.color
                            font.family: root.condensedFontFamily
                            font.pixelSize: vpx(20)
                            font.bold: true
                            elide: Text.ElideRight

                            Behavior on color {
                                ColorAnimation { duration: 300 }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: currentNotification.message
                            color: root.textColor
                            font.family: root.fontFamily
                            font.pixelSize: vpx(16)
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }

                        Row {
                            Layout.fillWidth: true
                            spacing: vpx(5)
                            visible: notifications.length > 1

                            Repeater {
                                model: notifications.length

                                Rectangle {
                                    width: vpx(24)
                                    height: vpx(5)
                                    radius: vpx(2.5)
                                    color: index === currentNotificationIndex ?
                                    currentNotification.color :
                                    Qt.rgba(root.secondaryTextColor.r, root.secondaryTextColor.g, root.secondaryTextColor.b, 0.3)

                                    Behavior on color {
                                        ColorAnimation { duration: 300 }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        id: actionButton
                        Layout.preferredWidth: vpx(50)
                        Layout.preferredHeight: vpx(50)
                        Layout.alignment: Qt.AlignVCenter
                        visible: currentNotification.game && currentNotification.type === "last_played"

                        Rectangle {
                            id: buttonBackground
                            anchors.fill: parent
                            radius: width / 2
                            color: Qt.rgba(currentNotification.color.r, currentNotification.color.g, currentNotification.color.b, 0.2)

                            SequentialAnimation on scale {
                                running: actionButton.visible
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 1.15; duration: 800; easing.type: Easing.InOutQuad }
                                NumberAnimation { from: 1.15; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                            }
                        }

                        Image {
                            id: playIcon
                            anchors.centerIn: parent
                            width: parent.width * 0.5
                            height: parent.height * 0.5
                            source: "assets/images/icons/play.svg"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                if (currentNotification.game) {
                                    currentNotification.game.launch()
                                }
                            }

                            onPressed: {
                                buttonBackground.scale = 0.85
                                playIcon.scale = 0.85
                            }

                            onReleased: {
                                buttonBackground.scale = 1.0
                                playIcon.scale = 1.0
                            }

                            onEntered: {
                                playIcon.scale = 1.2
                            }

                            onExited: {
                                playIcon.scale = 1.0
                            }
                        }
                    }
                }
            }

            NumberAnimation {
                id: slideOutAnimation
                target: currentCard
                property: "y"
                from: 0
                to: currentCard.height + vpx(20)
                duration: 400
                easing.type: Easing.InBack
                onStopped: {
                    currentNotificationIndex = (currentNotificationIndex + 1) % notifications.length
                    slideInAnimation.start()
                }
            }

            NumberAnimation {
                id: slideInAnimation
                target: currentCard
                property: "y"
                from: currentCard.height + vpx(20)
                to: 0
                duration: 500
                easing.type: Easing.OutBack
            }
        }
    }

    Connections {
        target: root
        function onCurrentGameChanged() {
            if (root.currentGame) {
                Qt.callLater(function() {
                    updateNotifications()
                })
            }
        }
    }

    function nextNotification() {
        if (notifications.length > 1) {
            slideOutAnimation.start()
            notificationTimer.restart()
        }
    }

    function previousNotification() {
        if (notifications.length > 1) {
            currentNotificationIndex = (currentNotificationIndex - 1 + notifications.length) % notifications.length
            notificationTimer.restart()
        }
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_N) {
            nextNotification()
            event.accepted = true
        } else if (event.key === Qt.Key_P) {
            previousNotification()
            event.accepted = true
        }
    }
}

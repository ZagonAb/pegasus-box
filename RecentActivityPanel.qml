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
    property var allCollectionProgress: []
    property int currentCollectionProgressIndex: 0
    property color successColor: "#4CAF50"
    property color warningColor: "#FF9800"
    property color highlightColor: "#E91E63"
    property color achievementColor: "#9C27B0"
    property color streakColor: "#FF5722"
    property color milestoneColor: "#FFC107"
    property color multiplayerColor: "#00BCD4"
    property color infoColor: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.9)


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

    function getSystemImagePathFromShortName(shortName) {
        if (!shortName) {
            return "";
        }
        return "assets/images/systems/" + shortName.toLowerCase() + ".png";
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

    function getCollectionShortNameFromString(shortName) {
        if (!shortName) {
            return "??";
        }
        return shortName.substring(0, 2).toUpperCase();
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

        var streak = calculateGamingStreak()
        if (streak >= 2) {
            newNotifications.push({
                type: "streak",
                game: null,
                title: "🔥 Gaming Streak",
                message: streak + " days in a row! Keep the momentum going!",
                color: streakColor,
                icon: "assets/images/icons/Streak.svg"
            })
        }

        var unplayedGem = findUnplayedGem()
        if (unplayedGem) {
            var ratingPercent = Math.round(unplayedGem.rating * 100)
            newNotifications.push({
                type: "unplayed",
                game: unplayedGem,
                title: "Hidden Gem",
                message: "You haven't tried " + Utils.cleanGameTitle(unplayedGem.title) +
                (ratingPercent > 0 ? " yet • Rating: " + ratingPercent + "%" : " yet"),
                                  color: multiplayerColor,
                                  icon: "assets/images/icons/star.svg"
            })
        }

        var anniversaryGame = findGameAnniversary()
        if (anniversaryGame) {
            var yearsAgo = new Date().getFullYear() - anniversaryGame.releaseYear
            newNotifications.push({
                type: "anniversary",
                game: anniversaryGame,
                title: "🎂 Anniversary",
                message: Utils.cleanGameTitle(anniversaryGame.title) + " was released " +
                yearsAgo + " year" + (yearsAgo > 1 ? "s" : "") + " ago today!",
                                  color: highlightColor,
                                  icon: "assets/images/icons/cake.svg"
            })
        }

        allCollectionProgress = calculateCollectionProgress()
        if (allCollectionProgress.length > 0) {
            var collectionProgress = allCollectionProgress[currentCollectionProgressIndex % allCollectionProgress.length]

            newNotifications.push({
                type: "collection_progress",
                game: null,
                title: collectionProgress.name + " Progress",
                message: "Played " + collectionProgress.played + " of " +
                collectionProgress.total + " games (" + collectionProgress.percent + "%)",
                                  color: achievementColor,
                                  icon: "assets/images/icons/collection.svg",
                                  collectionShortName: collectionProgress.shortName
            })
        }

        var randomSuggestion = getRandomSuggestion()
        if (randomSuggestion) {
            newNotifications.push({
                type: "random_suggestion",
                game: randomSuggestion.game,
                title: "🎲 Feeling Lucky?",
                message: "Try " + Utils.cleanGameTitle(randomSuggestion.game.title) +
                " from your " + randomSuggestion.collection,
                color: warningColor,
                icon: "assets/images/icons/dice.svg"
            })
        }

        var milestone = checkTimeMilestone()
        if (milestone) {
            newNotifications.push({
                type: "milestone",
                game: null,
                title: "🏆 Milestone Unlocked",
                message: milestone.message,
                color: milestoneColor,
                icon: "assets/images/icons/milestone.svg"
            })
        }

        var genreStats = analyzeFavoriteGenre()
        if (genreStats) {
            newNotifications.push({
                type: "genre_stats",
                game: null,
                title: "Genre Master",
                message: "You love " + genreStats.genre + "! " + genreStats.percent + "% of your playtime",
                color: achievementColor,
                icon: "assets/images/icons/genre.svg"
            })
        }

        var multiplayerGame = findMultiplayerGame()
        if (multiplayerGame) {
            newNotifications.push({
                type: "multiplayer",
                game: multiplayerGame,
                title: "👥 Multiplayer Fun",
                message: Utils.cleanGameTitle(multiplayerGame.title) + " supports up to " +
                multiplayerGame.players + " players!",
                color: multiplayerColor,
                icon: "assets/images/icons/multiplayer.svg"
            })
        }

        var oldFavorite = findOldFavorite()
        if (oldFavorite) {
            var monthsAgo = Math.floor((new Date() - oldFavorite.lastPlayed) / (1000 * 60 * 60 * 24 * 30))
            newNotifications.push({
                type: "revisit",
                game: oldFavorite,
                title: "Remember This?",
                message: "It's been " + monthsAgo + " month" + (monthsAgo > 1 ? "s" : "") +
                " since you played " + Utils.cleanGameTitle(oldFavorite.title),
                                  color: streakColor,
                                  icon: "assets/images/icons/history.svg"
            })
        }

        var devStats = analyzeDeveloperStats()
        if (devStats) {
            newNotifications.push({
                type: "developer",
                game: null,
                title: "Developer Fan",
                message: "You've played " + devStats.count + " " + devStats.developer +
                " game" + (devStats.count > 1 ? "s" : "") + " recently",
                                  color: highlightColor,
                                  icon: "assets/images/icons/developer.svg"
            })
        }

        var marathonGame = findMarathonSession()
        if (marathonGame) {
            newNotifications.push({
                type: "marathon",
                game: marathonGame.game,
                title: "Marathon Gamer!",
                message: formatPlayTime(marathonGame.duration) + " session on " +
                Utils.cleanGameTitle(marathonGame.game.title) + "!",
                                  color: achievementColor,
                                  icon: "assets/images/icons/playtime.svg"
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
                                  icon: "assets/images/icons/playtime.svg"
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
                icon: "assets/images/icons/collection.svg"
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

    function calculateGamingStreak() {
        var today = new Date()
        today.setHours(0, 0, 0, 0)

        var daysPlayed = []

        for (var i = 0; i < gameModel.count; i++) {
            var game = gameModel.get(i)
            if (game.lastPlayed && game.lastPlayed.toString() !== "Invalid Date") {
                var playDate = new Date(game.lastPlayed)
                playDate.setHours(0, 0, 0, 0)
                var dayKey = playDate.getTime()

                if (daysPlayed.indexOf(dayKey) === -1) {
                    daysPlayed.push(dayKey)
                }
            }
        }

        daysPlayed.sort(function(a, b) { return b - a })

        var streak = 0
        var checkDate = new Date(today)

        for (var j = 0; j < daysPlayed.length; j++) {
            if (daysPlayed[j] === checkDate.getTime()) {
                streak++
                checkDate.setDate(checkDate.getDate() - 1)
            } else {
                break
            }
        }

        return streak
    }

    function findUnplayedGem() {
        var unplayedGames = []

        for (var i = 0; i < gameModel.count; i++) {
            var game = gameModel.get(i)
            if (game.playCount === 0 && game.rating >= 0.7) {
                unplayedGames.push(game)
            }
        }

        if (unplayedGames.length > 0) {
            return unplayedGames[Math.floor(Math.random() * unplayedGames.length)]
        }

        return null
    }

    function findGameAnniversary() {
        var today = new Date()
        var currentMonth = today.getMonth() + 1
        var currentDay = today.getDate()

        for (var i = 0; i < gameModel.count; i++) {
            var game = gameModel.get(i)
            if (game.releaseYear > 0 && game.releaseMonth === currentMonth &&
                game.releaseDay === currentDay && game.releaseYear < today.getFullYear()) {
                return game
                }
        }

        return null
    }

    function calculateCollectionProgress() {
        var collections = {}

        for (var i = 0; i < gameModel.count; i++) {
            var game = gameModel.get(i)
            if (game.collections && game.collections.count > 0) {
                var coll = game.collections.get(0)
                var collName = coll.name

                if (!collections[collName]) {
                    collections[collName] = {
                        total: 0,
                        played: 0,
                        shortName: coll.shortName || ""
                    }
                }
                collections[collName].total++
                if (game.playCount > 0) {
                    collections[collName].played++
                }
            }
        }

        var allProgress = []

        for (var collName in collections) {
            var data = collections[collName]
            if (data.total >= 3 && data.played > 0) {
                var percent = Math.round((data.played / data.total) * 100)
                if (percent > 0 && percent < 100) {
                    allProgress.push({
                        name: collName,
                        total: data.total,
                        played: data.played,
                        percent: percent,
                        shortName: data.shortName
                    })
                }
            }
        }

        allProgress.sort(function(a, b) {
            return a.name.localeCompare(b.name)
        })

        return allProgress
    }

    function getRandomSuggestion() {
        var candidates = []

        for (var i = 0; i < gameModel.count; i++) {
            var game = gameModel.get(i)
            if (game.playCount === 0 || (game.lastPlayed &&
                (new Date() - game.lastPlayed) > 30 * 24 * 60 * 60 * 1000)) {
                candidates.push(game)
                }
        }

        if (candidates.length > 0) {
            var randomGame = candidates[Math.floor(Math.random() * candidates.length)]
            var collectionName = "library"

            if (randomGame.collections && randomGame.collections.count > 0) {
                collectionName = randomGame.collections.get(0).name
            }

            return {
                game: randomGame,
                collection: collectionName
            }
        }

        return null
    }

    function checkTimeMilestone() {
        var totalTime = 0

        for (var i = 0; i < gameModel.count; i++) {
            totalTime += gameModel.get(i).playTime
        }

        var totalHours = Math.floor(totalTime / 3600)
        var milestones = [50, 100, 200, 500, 1000, 2000]

        for (var j = 0; j < milestones.length; j++) {
            if (totalHours >= milestones[j] && totalHours < milestones[j] + 10) {
                return {
                    message: milestones[j] + " hours of total playtime reached!"
                }
            }
        }

        return null
    }

    function analyzeFavoriteGenre() {
        var genreTime = {}
        var totalTime = 0

        for (var i = 0; i < gameModel.count; i++) {
            var game = gameModel.get(i)
            if (game.playTime > 0 && game.genreList && game.genreList.length > 0) {
                for (var j = 0; j < game.genreList.length; j++) {
                    var genre = game.genreList[j]
                    if (!genreTime[genre]) {
                        genreTime[genre] = 0
                    }
                    genreTime[genre] += game.playTime
                    totalTime += game.playTime
                }
            }
        }

        var topGenre = null
        var maxTime = 0

        for (var genreName in genreTime) {
            if (genreTime[genreName] > maxTime) {
                maxTime = genreTime[genreName]
                topGenre = genreName
            }
        }

        if (topGenre && totalTime > 0) {
            var percent = Math.round((maxTime / totalTime) * 100)
            if (percent >= 30) {
                return {
                    genre: topGenre,
                    percent: percent
                }
            }
        }

        return null
    }

    function findMultiplayerGame() {
        var multiplayerGames = []

        for (var i = 0; i < gameModel.count; i++) {
            var game = gameModel.get(i)
            if (game.players > 1 && game.playCount === 0) {
                multiplayerGames.push(game)
            }
        }

        if (multiplayerGames.length > 0) {
            return multiplayerGames[Math.floor(Math.random() * multiplayerGames.length)]
        }

        return null
    }

    function findOldFavorite() {
        var candidates = []
        var threeMonthsAgo = new Date()
        threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3)

        for (var i = 0; i < gameModel.count; i++) {
            var game = gameModel.get(i)
            if (game.playCount >= 3 && game.lastPlayed &&
                game.lastPlayed.toString() !== "Invalid Date" &&
                game.lastPlayed < threeMonthsAgo) {
                candidates.push(game)
                }
        }

        if (candidates.length > 0) {
            candidates.sort(function(a, b) { return b.playCount - a.playCount })
            return candidates[0]
        }

        return null
    }

    function analyzeDeveloperStats() {
        var developerCount = {}
        var oneMonthAgo = new Date()
        oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1)

        for (var i = 0; i < gameModel.count; i++) {
            var game = gameModel.get(i)
            if (game.lastPlayed && game.lastPlayed.toString() !== "Invalid Date" &&
                game.lastPlayed > oneMonthAgo && game.developerList &&
                game.developerList.length > 0) {
                var dev = game.developerList[0]
                if (!developerCount[dev]) {
                    developerCount[dev] = 0
                }
                developerCount[dev]++
                }
        }

        var topDev = null
        var maxCount = 0

        for (var devName in developerCount) {
            if (developerCount[devName] > maxCount) {
                maxCount = developerCount[devName]
                topDev = devName
            }
        }

        if (topDev && maxCount >= 3) {
            return {
                developer: topDev,
                count: maxCount
            }
        }

        return null
    }

    function findMarathonSession() {
        var lastPlayedGame = findLastPlayedGame()

        if (lastPlayedGame && lastPlayedGame.playTime >= 18000) {
            var yesterday = new Date()
            yesterday.setDate(yesterday.getDate() - 1)
            yesterday.setHours(0, 0, 0, 0)

            var today = new Date()
            today.setHours(0, 0, 0, 0)

            if (lastPlayedGame.lastPlayed >= yesterday && lastPlayedGame.lastPlayed < today) {
                return {
                    game: lastPlayedGame,
                    duration: lastPlayedGame.playTime
                }
            }
        }

        return null
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
            if (game.lastPlayed && game.lastPlayed.toString() !== "Invalid Date" &&
                game.lastPlayed > cutoffDate) {
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
            anchors.margins: vpx(4)
            height: parent.height
            y: 0
            radius: vpx(10)
            color: Qt.rgba(currentNotification.color.r, currentNotification.color.g,
                           currentNotification.color.b, 0.04)

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: vpx(4)
                radius: vpx(12)
                samples: 24
                color: Qt.rgba(currentNotification.color.r, currentNotification.color.g,
                                currentNotification.color.b, 0.3)
            }

            Rectangle {
                id: cardContent
                anchors.fill: parent
                anchors.margins: vpx(4)
                radius: vpx(10)
                color: "transparent"

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
                                visible: currentNotification.game || currentNotification.type === "collection_progress"

                                Image {
                                    id: gameImage
                                    anchors.fill: parent
                                    source: currentNotification.game && currentNotification.game.assets ?
                                    currentNotification.game.assets.logo : ""
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
                                        source: {
                                            if (currentNotification.game) {
                                                return recentActivityPanel.getSystemImagePath(currentNotification.game)
                                            } else if (currentNotification.type === "collection_progress" && currentNotification.collectionShortName) {
                                                console.log("Collection Progress - shortName:", currentNotification.collectionShortName)
                                                return recentActivityPanel.getSystemImagePathFromShortName(currentNotification.collectionShortName)
                                            }
                                            return ""
                                        }
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        mipmap: true
                                        visible: status === Image.Ready && source !== ""

                                        onStatusChanged: {
                                            console.log("SystemImage status:", status, "source:", source)
                                        }
                                    }

                                    Text {
                                        id: shrtNameCollection
                                        anchors.centerIn: parent
                                        text: {
                                            if (currentNotification.game) {
                                                return recentActivityPanel.getCollectionShortName(currentNotification.game)
                                            } else if (currentNotification.type === "collection_progress" && currentNotification.collectionShortName) {
                                                return recentActivityPanel.getCollectionShortNameFromString(currentNotification.collectionShortName)
                                            }
                                            return "??"
                                        }
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
                                visible: !currentNotification.game && currentNotification.type !== "collection_progress"

                                Image {
                                    id: backupIcon
                                    anchors.centerIn: parent
                                    width: vpx(60)
                                    height: vpx(60)
                                    source: currentNotification.icon
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
                                    opacity: 1.0

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
                            id: textMessege
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: currentNotification.message
                            color: root.textColor
                            font.family: root.fontFamily
                            font.pixelSize: vpx(16)
                            maximumLineCount: 3
                        }

                        Row {
                            Layout.fillWidth: true
                            spacing: vpx(4)
                            visible: notifications.length > 1

                            Repeater {
                                model: notifications.length

                                Rectangle {
                                    width: vpx(16)
                                    height: vpx(4)
                                    radius: vpx(2)
                                    color: index === currentNotificationIndex ?
                                    currentNotification.color :
                                    Qt.rgba(root.secondaryTextColor.r, root.secondaryTextColor.g,
                                            root.secondaryTextColor.b, 0.3)

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
                        visible: currentNotification.game

                        Rectangle {
                            id: buttonBackground
                            anchors.fill: parent
                            radius: width / 2
                            color: Qt.rgba(currentNotification.color.r, currentNotification.color.g,
                                            currentNotification.color.b, 0.2)

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

                onStarted: {
                    if (notifications[currentNotificationIndex] &&
                        notifications[currentNotificationIndex].type === "collection_progress") {
                        currentCollectionProgressIndex++
                        updateNotifications()
                        }
                }
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
}

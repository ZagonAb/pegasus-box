import QtQuick 2.15
import QtGraphicalEffects 1.12
import QtMultimedia 5.15
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

            // MAIN MEDIA VIEWER
            Rectangle {
                width: parent.width
                height: width * 0.75
                radius: vpx(6)
                color: "#222"

                // IMAGE VIEWER
                Image {
                    id: gameImage
                    anchors.fill: parent
                    source: mediaPreview.currentMediaSource
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: !mediaPreview.currentIsVideo

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

                // VIDEO PLAYER
                Video {
                    id: videoPlayer
                    anchors.fill: parent
                    source: mediaPreview.currentIsVideo ? mediaPreview.currentMediaSource : ""
                    fillMode: VideoOutput.PreserveAspectFit
                    autoPlay: true
                    loops: MediaPlayer.Infinite
                    volume: 0.7
                    visible: mediaPreview.currentIsVideo

                    // Cargar volumen guardado al iniciar
                    Component.onCompleted: {
                        var savedVolume = api.memory.get('videoVolume')
                        if (savedVolume !== undefined) {
                            videoPlayer.volume = savedVolume
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "#333"
                        radius: vpx(4)
                        visible: videoPlayer.status === MediaPlayer.NoMedia ||
                        videoPlayer.status === MediaPlayer.InvalidMedia

                        Text {
                            anchors.centerIn: parent
                            text: "NO VIDEO"
                            color: secondaryTextColor
                            font.family: condensedFontFamily
                            font.pixelSize: vpx(18)
                        }
                    }

                    // Video controls overlay
                    Rectangle {
                        id: videoControls
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: vpx(50)
                        color: "#4D000000"
                        visible: mediaPreview.currentIsVideo
                        opacity: 0

                        // Animación de opacidad
                        Behavior on opacity {
                            NumberAnimation { duration: 300 }
                        }

                        // Timer para ocultar controles automáticamente
                        Timer {
                            id: hideControlsTimer
                            interval: 2000
                            onTriggered: {
                                if (!videoControlsArea.containsMouse) {
                                    videoControls.opacity = 0
                                }
                            }
                        }

                        // MouseArea para detectar hover sobre el video
                        MouseArea {
                            id: videoControlsArea
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true

                            onEntered: {
                                videoControls.opacity = 1
                                hideControlsTimer.stop()
                            }

                            onExited: {
                                hideControlsTimer.restart()
                            }

                            // Permitir que los clicks pasen a los controles internos
                            onPressed: mouse.accepted = false
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: vpx(20)

                            // Play/Pause button with SVG icon
                            Item {
                                width: vpx(32)
                                height: vpx(32)

                                Image {
                                    id: playPauseIcon
                                    anchors.centerIn: parent
                                    width: vpx(24)
                                    height: vpx(24)
                                    source: videoPlayer.playbackState === MediaPlayer.PlayingState ?
                                    "assets/images/icons/pause-preview.svg" :
                                    "assets/images/icons/play-preview.svg"
                                    sourceSize: Qt.size(width, height)
                                    mipmap: true
                                    cache: false

                                    ColorOverlay {
                                        anchors.fill: parent
                                        source: parent
                                        color: playPauseArea.containsMouse ? accentColor : "white"
                                        cached: false
                                    }
                                }

                                MouseArea {
                                    id: playPauseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (videoPlayer.playbackState === MediaPlayer.PlayingState) {
                                            videoPlayer.pause()
                                        } else {
                                            videoPlayer.play()
                                        }
                                    }
                                }

                                // Subtle hover effect
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width + vpx(8)
                                    height: parent.height + vpx(8)
                                    radius: vpx(4)
                                    color: "transparent"
                                    border.color: accentColor
                                    border.width: vpx(1)
                                    opacity: playPauseArea.containsMouse ? 0.5 : 0

                                    Behavior on opacity {
                                        NumberAnimation { duration: 150 }
                                    }
                                }
                            }

                            // Volume control
                            Item {
                                width: vpx(120)
                                height: vpx(32)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: vpx(10)

                                    // Volume icon
                                    Item {
                                        width: vpx(20)
                                        height: vpx(20)
                                        anchors.verticalCenter: parent.verticalCenter

                                        Image {
                                            id: volumeIcon
                                            anchors.centerIn: parent
                                            width: vpx(20)
                                            height: vpx(20)
                                            source: videoPlayer.volume === 0 ?
                                            "assets/images/icons/mute-preview.svg" :
                                            "assets/images/icons/volume-preview.svg"
                                            sourceSize: Qt.size(width, height)
                                            mipmap: true
                                            cache: false

                                            ColorOverlay {
                                                anchors.fill: parent
                                                source: parent
                                                color: volumeIconArea.containsMouse ? accentColor : "white"
                                                cached: false
                                            }
                                        }

                                        MouseArea {
                                            id: volumeIconArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (videoPlayer.volume > 0) {
                                                    videoPlayer.volume = 0
                                                } else {
                                                    videoPlayer.volume = 0.7
                                                }
                                                // Guardar volumen en memoria
                                                api.memory.set('videoVolume', videoPlayer.volume)
                                            }
                                        }
                                    }

                                    // Volume slider background
                                    Rectangle {
                                        id: volumeSliderBg
                                        width: vpx(80)
                                        height: vpx(6)
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: height / 2
                                        color: "#444444"

                                        // Volume fill
                                        Rectangle {
                                            anchors {
                                                left: parent.left
                                                top: parent.top
                                                bottom: parent.bottom
                                            }
                                            width: parent.width * videoPlayer.volume
                                            radius: parent.radius
                                            color: accentColor

                                            Behavior on width {
                                                NumberAnimation { duration: 100 }
                                            }
                                        }

                                        // Volume handle
                                        Rectangle {
                                            id: volumeHandle
                                            width: vpx(14)
                                            height: vpx(14)
                                            radius: width / 2
                                            x: (volumeSliderBg.width - width) * videoPlayer.volume
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: volumeSliderArea.containsMouse || volumeSliderArea.pressed ?
                                            accentColor : "white"
                                            border.width: vpx(2)
                                            border.color: "#222"

                                            Behavior on x {
                                                NumberAnimation { duration: 100 }
                                            }

                                            Behavior on color {
                                                ColorAnimation { duration: 150 }
                                            }

                                            // Glow effect on hover
                                            layer.enabled: volumeSliderArea.containsMouse
                                            layer.effect: DropShadow {
                                                horizontalOffset: 0
                                                verticalOffset: 0
                                                radius: vpx(8)
                                                samples: 17
                                                color: accentColor
                                            }
                                        }

                                        MouseArea {
                                            id: volumeSliderArea
                                            anchors.fill: parent
                                            anchors.margins: vpx(-8)
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor

                                            onPressed: {
                                                updateVolume(mouse.x)
                                            }

                                            onPositionChanged: {
                                                if (pressed) {
                                                    updateVolume(mouse.x)
                                                }
                                            }

                                            onReleased: {
                                                // Guardar volumen en memoria al soltar
                                                api.memory.set('videoVolume', videoPlayer.volume)
                                            }

                                            function updateVolume(mouseX) {
                                                var newVolume = Math.max(0, Math.min(1, mouseX / volumeSliderBg.width))
                                                videoPlayer.volume = newVolume
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // MouseArea global para detectar hover sobre todo el video
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: true
                        acceptedButtons: Qt.NoButton

                        onEntered: {
                            videoControls.opacity = 1
                            hideControlsTimer.stop()
                        }

                        onExited: {
                            hideControlsTimer.restart()
                        }
                    }

                    // Mostrar controles al iniciar reproducción
                    onPlaybackStateChanged: {
                        if (playbackState === MediaPlayer.PlayingState) {
                            videoControls.opacity = 1
                            hideControlsTimer.restart()
                        }
                    }
                }

                // Media type indicator
                /*Rectangle {
                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: vpx(10)
                    }
                    width: vpx(80)
                    height: vpx(24)
                    radius: vpx(4)
                    color: "#CC000000"
                    visible: mediaPreview.currentMediaType !== ""

                    Text {
                        anchors.centerIn: parent
                        text: mediaPreview.currentMediaType
                        color: accentColor
                        font.family: condensedFontFamily
                        font.pixelSize: vpx(11)
                        font.bold: true
                    }
                }*/
            }

            // MEDIA PREVIEW THUMBNAILS
            Item {
                id: mediaPreview
                width: parent.width
                height: vpx(90)
                visible: displayGame && availableMedia.length > 0

                property var availableMedia: {
                    if (!displayGame) return []

                        var media = []
                        var assets = displayGame.assets

                        // Helper function to add media items
                        function addMedia(source, type, label) {
                            if (source && source.toString() !== "") {
                                media.push({
                                    source: source,
                                    type: type,
                                    label: label,
                                    isVideo: type === "video"
                                })
                            }
                        }

                        // ORDEN PRIORITARIO: Screenshot, Logo, BoxFront, Background, Video, etc.

                        // 1. Screenshots primero (lo más importante)
                        addMedia(assets.screenshot, "image", "Screenshot")
                        addMedia(assets.titlescreen, "image", "Title Screen")

                        // 2. Logo
                        addMedia(assets.logo, "image", "Logo")

                        // 3. Box assets
                        addMedia(assets.boxFront, "image", "Box Front")
                        addMedia(assets.boxFull, "image", "Box Full")
                        addMedia(assets.boxBack, "image", "Box Back")
                        addMedia(assets.boxSpine, "image", "Box Spine")

                        // 4. Background
                        addMedia(assets.background, "image", "Background")

                        // 5. Video
                        addMedia(assets.video, "video", "Video")

                        // 6. UI assets
                        addMedia(assets.banner, "image", "Banner")
                        addMedia(assets.poster, "image", "Poster")
                        addMedia(assets.tile, "image", "Tile")
                        addMedia(assets.steam, "image", "Steam")

                        // 7. Arcade assets
                        addMedia(assets.marquee, "image", "Marquee")
                        addMedia(assets.bezel, "image", "Bezel")
                        addMedia(assets.panel, "image", "Panel")
                        addMedia(assets.cabinetLeft, "image", "Cabinet L")
                        addMedia(assets.cabinetRight, "image", "Cabinet R")

                        // 8. Otros
                        addMedia(assets.cartridge, "image", "Cartridge")

                        return media
                }

                property int currentMediaIndex: 0
                property string currentMediaSource: availableMedia.length > 0 ?
                availableMedia[currentMediaIndex].source :
                (displayGame ? displayGame.assets.screenshot || displayGame.assets.logo || "" : "")
                property bool currentIsVideo: availableMedia.length > 0 ?
                availableMedia[currentMediaIndex].isVideo : false
                property string currentMediaType: availableMedia.length > 0 ?
                availableMedia[currentMediaIndex].label : ""

                Column {
                    anchors.fill: parent
                    spacing: vpx(8)

                    Text {
                        text: "MEDIA (" + mediaPreview.availableMedia.length + ")"
                        color: accentColor
                        font.family: condensedFontFamily
                        font.pixelSize: vpx(14)
                        font.bold: true
                    }

                    Flickable {
                        width: parent.width
                        height: vpx(70)
                        contentWidth: mediaRow.width
                        contentHeight: height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Row {
                            id: mediaRow
                            spacing: vpx(8)
                            height: parent.height

                            Repeater {
                                model: mediaPreview.availableMedia

                                Rectangle {
                                    width: vpx(90)
                                    height: vpx(70)
                                    radius: vpx(4)
                                    color: "#333"
                                    border.width: mediaPreview.currentMediaIndex === index ? vpx(3) : vpx(1)
                                    border.color: mediaPreview.currentMediaIndex === index ? accentColor : "#555"

                                    // Thumbnail
                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: vpx(2)
                                        source: modelData.isVideo ? "" : modelData.source
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        visible: !modelData.isVideo

                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: Rectangle {
                                                width: vpx(86)
                                                height: vpx(66)
                                                radius: vpx(3)
                                            }
                                        }
                                    }

                                    // Video indicator
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: vpx(2)
                                        radius: vpx(3)
                                        color: "#444"
                                        visible: modelData.isVideo

                                        Text {
                                            anchors.centerIn: parent
                                            text: "▶"
                                            color: accentColor
                                            font.pixelSize: vpx(24)
                                        }
                                    }

                                    // Label overlay
                                    Rectangle {
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            bottom: parent.bottom
                                            margins: vpx(2)
                                        }
                                        height: vpx(18)
                                        radius: vpx(3)
                                        color: "#DD000000"

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            color: "white"
                                            font.family: condensedFontFamily
                                            font.pixelSize: vpx(9)
                                            elide: Text.ElideRight
                                            width: parent.width - vpx(4)
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked: {
                                            mediaPreview.currentMediaIndex = index
                                            if (modelData.isVideo) {
                                                videoPlayer.play()
                                            }
                                        }

                                        onEntered: parent.opacity = 0.8
                                        onExited: parent.opacity = 1
                                    }
                                }
                            }
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
                width: parent.width
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

            y: Math.min(
                Math.max(
                    0,
                    detailsFlickable.visibleArea.yPosition * scrollBar.height
                ),
                scrollBar.height - scrollHandle.height
            )

            radius: width / 2
            color: accentColor
        }
    }
}

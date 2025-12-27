import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtMultimedia 5.15
import QtGraphicalEffects 1.12

Item {
    id: musicPlayer

    property var musicTracks: []
    property int currentTrackIndex: 0
    property bool isPlaying: false
    property bool dropdownVisible: false
    property real volume: 0.5
    property bool isMuted: false

    function vpx(value) {
        return Math.round(value * root.height / 1080)
    }

    Audio {
        id: audioPlayer
        volume: isMuted ? 0 : musicPlayer.volume

        onStatusChanged: {
            if (status === Audio.EndOfMedia) {
                console.log("Track ended, playing next track")
                nextTrack()
            } else if (status === Audio.Loaded) {
                console.log("Track loaded:", source)
            } else if (status === Audio.Loading) {
                console.log("Loading track...")
            }
        }

        onError: {
            console.log("Audio error:", errorString)
        }

        onPlaybackStateChanged: {
            console.log("Playback state changed:", playbackState)
            if (playbackState === Audio.PlayingState) {
                isPlaying = true
            } else if (playbackState === Audio.PausedState || playbackState === Audio.StoppedState) {
                isPlaying = false
            }
        }
    }

    Component.onCompleted: {
        loadMusicList()
        loadVolumeSettings()
    }

    Component.onDestruction: {
        saveVolumeSettings()
    }

    function loadVolumeSettings() {
        var savedVolume = api.memory.get('musicPlayerVolume')
        var savedMuted = api.memory.get('musicPlayerMuted')

        if (savedVolume !== undefined) {
            volume = savedVolume
        }

        if (savedMuted !== undefined) {
            isMuted = savedMuted
        }

        console.log("Music Player: Loaded volume settings - Volume:", volume, "Muted:", isMuted)
    }

    function saveVolumeSettings() {
        api.memory.set('musicPlayerVolume', volume)
        api.memory.set('musicPlayerMuted', isMuted)
        console.log("Music Player: Saved volume settings - Volume:", volume, "Muted:", isMuted)
    }

    function loadMusicList() {
        var hardcodedTracks = [
            "assets/music/Doom E1M1.mp3",
            "assets/music/Crazy Taxi.mp3",
            "assets/music/Jester Elysium.mp3",
            "assets/music/Sonic the Hedgehog 3.mp3",
            "assets/music/Sled Storm.mp3",
            "assets/music/TOCA Ingame.mp3",
            "assets/music/Mortal Kombat.mp3",
            "assets/music/AMB BIKR.mp3"
        ]
        var availableTracks = []
        for (var i = 0; i < hardcodedTracks.length; i++) {
            availableTracks.push(hardcodedTracks[i])
        }
        musicTracks = availableTracks
        if (musicTracks.length > 0) initializePlayer()
    }

    function initializePlayer() {
        if (musicTracks.length > 0) {
            currentTrackIndex = 0
            audioPlayer.source = musicTracks[currentTrackIndex]
            console.log("Music Player initialized with", musicTracks.length, "tracks")
        }
    }

    function togglePlayPause() {
        if (musicTracks.length === 0) return

            if (isPlaying) {
                audioPlayer.pause()
                console.log("Music paused")
            } else {
                audioPlayer.play()
                console.log("Music playing")
            }
    }

    function nextTrack() {
        if (musicTracks.length === 0) return

            var wasPlaying = isPlaying
            audioPlayer.stop()

            currentTrackIndex = (currentTrackIndex + 1) % musicTracks.length
            audioPlayer.source = musicTracks[currentTrackIndex]

            //console.log("Next track:", getCurrentTrackName())

            if (wasPlaying) {
                nextTrackTimer.start()
            }
    }

    function previousTrack() {
        if (musicTracks.length === 0) return

            var wasPlaying = isPlaying
            audioPlayer.stop()

            currentTrackIndex = currentTrackIndex - 1
            if (currentTrackIndex < 0) {
                currentTrackIndex = musicTracks.length - 1
            }

            audioPlayer.source = musicTracks[currentTrackIndex]

            //console.log("Previous track:", getCurrentTrackName())

            if (wasPlaying) {
                prevTrackTimer.start()
            }
    }

    function selectTrack(index) {
        if (index >= 0 && index < musicTracks.length) {
            var wasPlaying = isPlaying

            audioPlayer.stop()

            currentTrackIndex = index
            audioPlayer.source = musicTracks[currentTrackIndex]

            //console.log("Selected track:", getCurrentTrackName())

            if (wasPlaying) {
                selectTrackTimer.start()
            }

            dropdownVisible = false
        }
    }

    Timer {
        id: nextTrackTimer
        interval: 100
        repeat: false
        onTriggered: {
            audioPlayer.play()
        }
    }

    Timer {
        id: prevTrackTimer
        interval: 100
        repeat: false
        onTriggered: {
            audioPlayer.play()
        }
    }

    Timer {
        id: selectTrackTimer
        interval: 100
        repeat: false
        onTriggered: {
            audioPlayer.play()
        }
    }

    function toggleMute() {
        isMuted = !isMuted
        saveVolumeSettings()
        console.log("Mute toggled:", isMuted)
    }

    function getCurrentTrackName() {
        if (musicTracks.length === 0) return "No music loaded"

            var fullPath = musicTracks[currentTrackIndex]
            var fileName = fullPath.split('/').pop()
            return fileName.replace('.mp3', '').replace('.wav', '').replace('.ogg', '')
    }

    function getTrackName(trackPath) {
        var fileName = trackPath.split('/').pop()
        return fileName.replace('.mp3', '').replace('.wav', '').replace('.ogg', '')
    }

    RowLayout {
        anchors.fill: parent
        spacing: vpx(15)

        Rectangle {
            id: trackTitleArea
            Layout.preferredWidth: vpx(250)
            Layout.fillHeight: true
            color: dropdownVisible ? "#333" : "transparent"
            radius: vpx(4)
            border.width: vpx(1)
            border.color: dropdownVisible ? root.accentColor : "#333"

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Behavior on border.color {
                ColorAnimation { duration: 150 }
            }

            Row {
                anchors.fill: parent
                anchors.margins: vpx(8)
                spacing: vpx(10)

                Image {
                    width: vpx(26)
                    height: vpx(26)
                    source: "assets/images/icons/music.svg"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    width: parent.width - vpx(60)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: vpx(2)

                    Text {
                        width: parent.width
                        text: getCurrentTrackName()
                        color: root.textColor
                        font.family: root.fontFamily
                        font.pixelSize: vpx(13)
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: isPlaying ? "Now Playing" : "Paused"
                        color: root.secondaryTextColor
                        font.family: root.fontFamily
                        font.pixelSize: vpx(10)
                    }
                }

                Text {
                    text: "▲"
                    color: root.secondaryTextColor
                    font.pixelSize: vpx(10)
                    anchors.verticalCenter: parent.verticalCenter
                    rotation: dropdownVisible ? 0 : 180

                    Behavior on rotation {
                        NumberAnimation { duration: 200 }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    dropdownVisible = !dropdownVisible
                }

                onEntered: {
                    if (!dropdownVisible) {
                        parent.color = "#2a2a2a"
                    }
                }

                onExited: {
                    if (!dropdownVisible) {
                        parent.color = "transparent"
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: vpx(1)
            Layout.preferredHeight: parent.height * 0.7
            color: root.borderColor
        }

        Row {
            spacing: vpx(10)
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                width: vpx(55)
                height: vpx(55)
                radius: vpx(4)
                color: prevMouseArea.containsMouse ? "#333" : "transparent"
                border.width: vpx(1)
                border.color: prevMouseArea.containsMouse ? root.accentColor : root.borderColor

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Image {
                    anchors.centerIn: parent
                    width: vpx(35)
                    height: vpx(35)
                    source: "assets/images/icons/play-back.svg"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }

                MouseArea {
                    id: prevMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: previousTrack()
                }
            }

            Rectangle {
                width: vpx(55)
                height: vpx(55)
                radius: vpx(4)
                color: playMouseArea.containsMouse ? root.accentColor : "#333"
                border.width: vpx(2)
                border.color: root.accentColor

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Image {
                    anchors.centerIn: parent
                    width: vpx(35)
                    height: vpx(35)
                    source: isPlaying ? "assets/images/icons/pause.svg" : "assets/images/icons/play-music.svg"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }

                MouseArea {
                    id: playMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: togglePlayPause()
                }
            }

            Rectangle {
                width: vpx(55)
                height: vpx(55)
                radius: vpx(4)
                color: nextMouseArea.containsMouse ? "#333" : "transparent"
                border.width: vpx(1)
                border.color: nextMouseArea.containsMouse ? root.accentColor : root.borderColor

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Image {
                    anchors.centerIn: parent
                    width: vpx(35)
                    height: vpx(35)
                    source: "assets/images/icons/play-forward.svg"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }

                MouseArea {
                    id: nextMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: nextTrack()
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: vpx(1)
            Layout.preferredHeight: parent.height * 0.7
            color: root.borderColor
        }

        Row {
            spacing: vpx(8)
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                width: vpx(30)
                height: vpx(30)
                radius: vpx(4)
                color: "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.centerIn: parent
                    width: vpx(24)
                    height: vpx(24)
                    source: isMuted ? "assets/images/icons/volume-mute.svg" : "assets/images/icons/volume.svg"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }

                MouseArea {
                    id: volumeIconMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: toggleMute()
                }
            }

            Rectangle {
                width: vpx(120)
                height: vpx(10)
                radius: vpx(3)
                color: "#333"
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: parent.width * (isMuted ? 0 : volume)
                    height: parent.height
                    radius: parent.radius
                    color: isMuted ? root.secondaryTextColor : root.accentColor

                    Behavior on width {
                        NumberAnimation { duration: 100 }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                Rectangle {
                    id: volumeHandle
                    x: Math.max(0, Math.min(parent.width - width, (parent.width - width) * (isMuted ? 0 : volume)))
                    width: vpx(18)
                    height: vpx(18)
                    radius: vpx(8)
                    color: root.textColor
                    border.width: vpx(2)
                    border.color: isMuted ? root.secondaryTextColor : root.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: volumeMouseArea.containsMouse || volumeMouseArea.pressed ? 1.0 : 0.8

                    Behavior on x {
                        NumberAnimation { duration: 100 }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }

                MouseArea {
                    id: volumeMouseArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onPressed: {
                        updateVolume(mouse.x)
                        if (isMuted) {
                            isMuted = false
                        }
                    }

                    onPositionChanged: {
                        if (pressed) {
                            updateVolume(mouse.x)
                            if (isMuted) {
                                isMuted = false
                            }
                        }
                    }

                    onReleased: {
                        saveVolumeSettings()
                    }

                    function updateVolume(x) {
                        var newVolume = Math.max(0, Math.min(1, x / parent.width))
                        volume = newVolume
                    }
                }
            }

            Text {
                text: isMuted ? "0%" : Math.round(volume * 100) + "%"
                color: root.secondaryTextColor
                font.family: root.fontFamily
                font.pixelSize: vpx(16)
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Item {
        id: dropdownContainer
        width: vpx(300)
        height: dropdownVisible ? Math.min(vpx(300), musicTracks.length * vpx(45) + vpx(20)) : 0
        anchors.bottom: parent.top
        anchors.bottomMargin: vpx(5)
        anchors.left: parent.left
        visible: dropdownVisible
        z: 200

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onWheel: {
                wheel.accepted = true;
            }

            onClicked: {
                mouse.accepted = true;
            }

            onPositionChanged: {
                mouse.accepted = true;
            }
        }

        Rectangle {
            id: dropdownPopup
            anchors.fill: parent
            radius: vpx(6)
            color: root.panelColor
            border.width: vpx(3)
            border.color: root.accentColor
            clip: true

            Column {
                anchors.fill: parent
                anchors.margins: vpx(10)
                spacing: 0

                Text {
                    width: parent.width
                    text: "Music Playlist (" + musicTracks.length + ")"
                    color: root.accentColor
                    font.family: root.condensedFontFamily
                    font.pixelSize: vpx(16)
                    font.bold: true
                    bottomPadding: vpx(8)
                }

                Rectangle {
                    width: parent.width
                    height: vpx(1)
                    color: root.borderColor
                }

                ListView {
                    id: trackList
                    width: parent.width
                    height: parent.height - vpx(30)
                    clip: true
                    interactive: true
                    boundsBehavior: Flickable.StopAtBounds

                    model: musicTracks

                    delegate: Item {
                        width: trackList.width
                        height: vpx(40)

                        Rectangle {
                            id: trackItemBg
                            anchors.fill: parent
                            anchors.margins: vpx(2)
                            radius: vpx(4)
                            color: trackMouseArea.containsMouse ? "#333" : "transparent"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: vpx(10)
                                anchors.rightMargin: vpx(10)
                                spacing: vpx(10)

                                Text {
                                    text: index === currentTrackIndex ? "♫" : "♪"
                                    color: index === currentTrackIndex ? root.accentColor : root.secondaryTextColor
                                    font.pixelSize: vpx(16)
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    width: parent.width - vpx(80)
                                    text: getTrackName(modelData)
                                    color: index === currentTrackIndex ? root.accentColor : root.textColor
                                    font.family: root.fontFamily
                                    font.pixelSize: vpx(16)
                                    font.bold: index === currentTrackIndex
                                    elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: index === currentTrackIndex && isPlaying ? "▶" : ""
                                    color: root.accentColor
                                    font.pixelSize: vpx(12)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                    margins: vpx(5)
                                }
                                height: vpx(1)
                                color: "#333"
                                visible: index < musicTracks.length - 1
                            }
                        }

                        MouseArea {
                            id: trackMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: selectTrack(index)
                        }
                    }

                    Rectangle {
                        id: scrollBar
                        anchors {
                            right: parent.right
                            top: parent.top
                            bottom: parent.bottom
                            rightMargin: vpx(2)
                        }
                        width: vpx(4)
                        radius: width / 2
                        color: "#555"
                        opacity: trackList.moving || trackList.flicking ? 0.8 : 0.3
                        visible: trackList.contentHeight > trackList.height

                        Behavior on opacity {
                            NumberAnimation { duration: 200 }
                        }

                        Rectangle {
                            id: scrollHandle
                            anchors {
                                left: parent.left
                                right: parent.right
                            }
                            height: Math.max(vpx(30), scrollBar.height * trackList.visibleArea.heightRatio)
                            y: trackList.visibleArea.yPosition * scrollBar.height
                            radius: width / 2
                            color: root.accentColor
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: dropdownVisible
        z: 199
        onClicked: dropdownVisible = false
        propagateComposedEvents: false
    }
}

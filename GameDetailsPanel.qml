import QtQuick 2.15
import QtGraphicalEffects 1.12
import QtMultimedia 5.15
import QtQuick.Layouts 1.15
import "qrc:/qmlutils" as PegasusUtils
import "utils.js" as Utils

Item {
    id: gameDetailsPanel

    property bool isExpanded: false
    property var displayGame: root.currentFilteredGame

    signal expansionChanged(bool expanded)

    onDisplayGameChanged: {
        detailsFlickable.contentY = 0
        autoScrollToTopTimer.stop()
    }

    Component {
        id: infoCardComponent

        Rectangle {
            id: infoCard

            property string iconSource: ""
            property string label: ""
            property string value: ""
            property color cardColor: "#2A2A2A"
            property color iconColor: accentColor
            property color labelTextColor: secondaryTextColor
            property color valueTextColor: textColor

            Layout.fillWidth: true
            Layout.preferredHeight: vpx(65)
            radius: vpx(6)
            color: cardColor

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
            }

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: vpx(2)
                radius: vpx(6)
                samples: 13
                color: "#20000000"
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: vpx(1)
                border.color: hoverArea.containsMouse ? accentColor : "#404040"
                opacity: hoverArea.containsMouse ? 0.8 : 0.3

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                Behavior on border.color {
                    ColorAnimation { duration: 200 }
                }
            }

            RowLayout {
                anchors {
                    fill: parent
                    margins: vpx(12)
                }
                spacing: vpx(12)

                Rectangle {
                    Layout.preferredWidth: vpx(40)
                    Layout.preferredHeight: vpx(40)
                    Layout.alignment: Qt.AlignVCenter
                    radius: vpx(8)
                    color: "#1A1A1A"

                    Image {
                        id: icon
                        anchors.centerIn: parent
                        width: vpx(24)
                        height: vpx(24)
                        source: iconSource
                        sourceSize: Qt.size(width, height)
                        mipmap: true
                        visible: false
                    }

                    ColorOverlay {
                        anchors.fill: icon
                        source: icon
                        color: iconColor
                        cached: false
                    }

                    Glow {
                        anchors.fill: icon
                        source: icon
                        radius: vpx(8)
                        samples: 17
                        color: iconColor
                        opacity: hoverArea.containsMouse ? 0.6 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: 200 }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: vpx(4)

                    Text {
                        text: label
                        color: labelTextColor
                        font.family: condensedFontFamily
                        font.pixelSize: vpx(11)
                        font.bold: true
                        opacity: 0.7
                        Layout.fillWidth: true
                    }

                    Text {
                        text: value
                        color: valueTextColor
                        font.family: fontFamily
                        font.pixelSize: vpx(16)
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            scale: hoverArea.containsMouse ? 1.01 : 1.0

            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (!gameDetailsPanel.isExpanded) {
                gameDetailsPanel.isExpanded = true
                gameDetailsPanel.expansionChanged(true)
            }
        }
        propagateComposedEvents: true
    }

    Rectangle {
        id: panelBackground
        anchors.fill: parent
        color: panelColor
        radius: vpx(8)
        border.width: isExpanded ? vpx(3) : vpx(2)
        border.color: isExpanded ? accentColor : borderColor

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: vpx(4)
            radius: isExpanded ? vpx(16) : vpx(12)
            samples: 25
            color: isExpanded ? "#60000000" : "#40000000"
        }

        Behavior on border.width {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        Behavior on border.color {
            ColorAnimation { duration: 300 }
        }
    }

    Rectangle {
        visible: isExpanded
        anchors {
            top: parent.top
            right: parent.right
            margins: vpx(12)
        }
        width: vpx(6)
        height: vpx(6)
        radius: width / 2
        color: accentColor

        SequentialAnimation on opacity {
            running: isExpanded
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.3; duration: 1000 }
            NumberAnimation { from: 0.3; to: 1.0; duration: 1000 }
        }
    }

    Text {
        id: panelTitle
        text: isExpanded ? "DETAILS (EXPANDED)" : "DETAILS"
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

        Behavior on text {
            SequentialAnimation {
                NumberAnimation { target: panelTitle; property: "opacity"; to: 0; duration: 150 }
                PropertyAction { target: panelTitle; property: "text" }
                NumberAnimation { target: panelTitle; property: "opacity"; to: 1; duration: 150 }
            }
        }
    }

    Item {
        id: openPanelIcon
        width: vpx(28)
        height: vpx(28)
        anchors {
            top: parent.top
            right: parent.right
            margins: vpx(20)
        }
        visible: !isExpanded

        Image {
            id: openPanelImage
            anchors.fill: parent
            source: "assets/images/icons/panel-right-open.svg"
            fillMode: Image.PreserveAspectFit
            mipmap: true
        }

        MouseArea {
            id: iconMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!gameDetailsPanel.isExpanded) {
                    gameDetailsPanel.isExpanded = true
                    gameDetailsPanel.expansionChanged(true)
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width + vpx(8)
            height: parent.height + vpx(8)
            radius: vpx(4)
            color: "transparent"
            border.color: accentColor
            border.width: vpx(1)
            opacity: iconMouseArea.containsMouse ? 0.3 : 0

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
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

        onMovementEnded: {
            if (contentY > 0) {
                autoScrollToTopTimer.restart()
            }
        }

        onFlickEnded: {
            if (contentY > 0) {
                autoScrollToTopTimer.restart()
            }
        }

        onMovementStarted: {
            autoScrollToTopTimer.stop()
        }

        Timer {
            id: autoScrollToTopTimer
            interval: 60000
            repeat: false
            onTriggered: {
                scrollToTopAnimation.start()
            }
        }

        NumberAnimation {
            id: scrollToTopAnimation
            target: detailsFlickable
            property: "contentY"
            to: 0
            duration: 500
            easing.type: Easing.OutCubic
        }

        Column {
            id: detailsColumn
            width: parent.width
            spacing: vpx(20)

            Rectangle {
                width: parent.width
                height: width * 0.75
                radius: vpx(6)
                color: "#222"

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

                Video {
                    id: videoPlayer
                    anchors.fill: parent
                    source: mediaPreview.currentIsVideo ? mediaPreview.currentMediaSource : ""
                    fillMode: VideoOutput.PreserveAspectFit
                    autoPlay: true
                    loops: MediaPlayer.Infinite
                    volume: 0.7
                    visible: mediaPreview.currentIsVideo

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

                        Behavior on opacity {
                            NumberAnimation { duration: 300 }
                        }

                        Timer {
                            id: hideControlsTimer
                            interval: 2000
                            onTriggered: {
                                if (!videoControlsArea.containsMouse) {
                                    videoControls.opacity = 0
                                }
                            }
                        }

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

                            onPressed: mouse.accepted = false
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: vpx(20)

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

                            Item {
                                width: vpx(120)
                                height: vpx(32)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: vpx(10)

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
                                                api.memory.set('videoVolume', videoPlayer.volume)
                                            }
                                        }
                                    }

                                    Rectangle {
                                        id: volumeSliderBg
                                        width: vpx(80)
                                        height: vpx(6)
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: height / 2
                                        color: "#444444"

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

                    onPlaybackStateChanged: {
                        root.videoPlayingInDetails = (playbackState === MediaPlayer.PlayingState)
                        if (playbackState === MediaPlayer.PlayingState) {
                            videoControls.opacity = 1
                            hideControlsTimer.restart()
                        }
                    }

                    onSourceChanged: {
                        root.videoPlayingInDetails = false
                    }
                }
            }

            Item {
                id: mediaPreview
                width: parent.width
                height: vpx(98)
                visible: displayGame && availableMedia.length > 0

                property int currentMediaIndex: 0
                property string currentMediaSource: availableMedia.length > 0 ?
                availableMedia[currentMediaIndex].source :
                (displayGame ? displayGame.assets.screenshot || displayGame.assets.logo || "" : "")
                property bool currentIsVideo: availableMedia.length > 0 ?
                availableMedia[currentMediaIndex].isVideo : false
                property string currentMediaType: availableMedia.length > 0 ?
                availableMedia[currentMediaIndex].label : ""

                property var availableMedia: {
                    if (!displayGame) return [];

                    var media = [];
                    var assets = displayGame.assets;

                    function addArrayToList(array, type, label) {
                        if (array && array.length > 0) {
                            for (var i = 0; i < array.length; i++) {
                                var source = array[i];
                                if (source && source.toString() !== "") {
                                    media.push({
                                        source: source,
                                        type: type,
                                        label: label + (array.length > 1 ? " " + (i + 1) : ""),
                                               isVideo: type === "video",
                                               orderPriority: getOrderPriority(type)
                                    });
                                }
                            }
                        }
                    }

                    function getOrderPriority(type) {
                        switch(type) {
                            case "screenshot": return 1;
                            case "image": return 1;
                            case "titlescreen": return 2;
                            case "logo": return 3;
                            case "boxFront": return 4;
                            case "boxFull": return 5;
                            case "boxBack": return 6;
                            case "boxSpine": return 7;
                            case "background": return 8;
                            case "banner": return 9;
                            case "poster": return 10;
                            case "tile": return 11;
                            case "steam": return 12;
                            case "marquee": return 13;
                            case "bezel": return 14;
                            case "panel": return 15;
                            case "cabinetLeft": return 16;
                            case "cabinetRight": return 17;
                            case "cartridge": return 18;
                            case "video": return 99;
                            default: return 50;
                        }
                    }

                    var allMediaItems = [];

                    if (assets.screenshotList && assets.screenshotList.length > 0) {
                        for (var i = 0; i < assets.screenshotList.length; i++) {
                            var screenshotSource = assets.screenshotList[i];
                            if (screenshotSource && screenshotSource.toString() !== "") {
                                allMediaItems.push({
                                    source: screenshotSource,
                                    type: "screenshot",
                                    label: "Screenshot" + (assets.screenshotList.length > 1 ? " " + (i + 1) : ""),
                                                   isVideo: false,
                                                   orderPriority: 1
                                });
                            }
                        }
                    } else if (assets.screenshot && assets.screenshot.toString() !== "") {
                        allMediaItems.push({
                            source: assets.screenshot,
                            type: "screenshot",
                            label: "Screenshot",
                            isVideo: false,
                            orderPriority: 1
                        });
                    }

                    if (assets.titlescreenList && assets.titlescreenList.length > 0) {
                        for (var j = 0; j < assets.titlescreenList.length; j++) {
                            var titleSource = assets.titlescreenList[j];
                            if (titleSource && titleSource.toString() !== "") {
                                allMediaItems.push({
                                    source: titleSource,
                                    type: "titlescreen",
                                    label: "Title Screen" + (assets.titlescreenList.length > 1 ? " " + (j + 1) : ""),
                                                   isVideo: false,
                                                   orderPriority: 2
                                });
                            }
                        }
                    } else if (assets.titlescreen && assets.titlescreen.toString() !== "") {
                        allMediaItems.push({
                            source: assets.titlescreen,
                            type: "titlescreen",
                            label: "Title Screen",
                            isVideo: false,
                            orderPriority: 2
                        });
                    }

                    var otherAssets = [
                        { prop: "logo", label: "Logo", priority: 3 },
                        { prop: "boxFront", label: "Box Front", priority: 4 },
                        { prop: "boxFull", label: "Box Full", priority: 5 },
                        { prop: "boxBack", label: "Box Back", priority: 6 },
                        { prop: "boxSpine", label: "Box Spine", priority: 7 },
                        { prop: "background", label: "Background", priority: 8 },
                        { prop: "banner", label: "Banner", priority: 9 },
                        { prop: "poster", label: "Poster", priority: 10 },
                        { prop: "tile", label: "Tile", priority: 11 },
                        { prop: "steam", label: "Steam Grid", priority: 12 },
                        { prop: "marquee", label: "Marquee", priority: 13 },
                        { prop: "bezel", label: "Bezel", priority: 14 },
                        { prop: "panel", label: "Panel", priority: 15 },
                        { prop: "cabinetLeft", label: "Cabinet L", priority: 16 },
                        { prop: "cabinetRight", label: "Cabinet R", priority: 17 },
                        { prop: "cartridge", label: "Cartridge", priority: 18 }
                    ];

                    for (var k = 0; k < otherAssets.length; k++) {
                        var asset = otherAssets[k];

                        var listName = asset.prop + "List";
                        if (assets[listName] && assets[listName].length > 0) {
                            for (var l = 0; l < assets[listName].length; l++) {
                                var listSource = assets[listName][l];
                                if (listSource && listSource.toString() !== "") {
                                    allMediaItems.push({
                                        source: listSource,
                                        type: asset.prop,
                                        label: asset.label + (assets[listName].length > 1 ? " " + (l + 1) : ""),
                                                       isVideo: false,
                                                       orderPriority: asset.priority
                                    });
                                }
                            }
                        }
                        else if (assets[asset.prop] && assets[asset.prop].toString() !== "") {
                            allMediaItems.push({
                                source: assets[asset.prop],
                                type: asset.prop,
                                label: asset.label,
                                isVideo: false,
                                orderPriority: asset.priority
                            });
                        }
                    }

                    if (assets.videoList && assets.videoList.length > 0) {
                        for (var m = 0; m < assets.videoList.length; m++) {
                            var videoSource = assets.videoList[m];
                            if (videoSource && videoSource.toString() !== "") {
                                allMediaItems.push({
                                    source: videoSource,
                                    type: "video",
                                    label: "Video" + (assets.videoList.length > 1 ? " " + (m + 1) : ""),
                                                   isVideo: true,
                                                   orderPriority: 99
                                });
                            }
                        }
                    } else if (assets.video && assets.video.toString() !== "") {
                        allMediaItems.push({
                            source: assets.video,
                            type: "video",
                            label: "Video",
                            isVideo: true,
                            orderPriority: 99
                        });
                    }

                    allMediaItems.sort(function(a, b) {
                        return a.orderPriority - b.orderPriority;
                    });

                    var finalMedia = [];
                    for (var n = 0; n < allMediaItems.length; n++) {
                        var item = allMediaItems[n];
                        finalMedia.push({
                            source: item.source,
                            type: item.type,
                            label: item.label,
                            isVideo: item.isVideo
                        });
                    }

                    return finalMedia;
                }

                Text {
                    id: mediaTitle
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    text: "MEDIA (" + mediaPreview.availableMedia.length + ")"
                    color: accentColor
                    font.family: condensedFontFamily
                    font.pixelSize: vpx(14)
                    font.bold: true
                }

                Flickable {
                    id: mediaFlickable
                    anchors {
                        top: mediaTitle.bottom
                        left: parent.left
                        right: parent.right
                        topMargin: vpx(8)
                    }
                    width: parent.width
                    height: vpx(70)
                    contentWidth: mediaRow.width
                    contentHeight: height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    function scrollToItem(itemX, itemWidth) {
                        var itemCenter = itemX + itemWidth / 2
                        var viewCenter = contentX + width / 2
                        var targetX = itemCenter - width / 2

                        targetX = Math.max(0, Math.min(targetX, contentWidth - width))

                        scrollAnimation.to = targetX
                        scrollAnimation.start()
                    }

                    NumberAnimation {
                        id: scrollAnimation
                        target: mediaFlickable
                        property: "contentX"
                        duration: 300
                        easing.type: Easing.OutCubic
                    }

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
                                        var itemX = index * (vpx(90) + vpx(8))
                                        mediaFlickable.scrollToItem(itemX, vpx(90))

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

                Rectangle {
                    id: mediaScrollBar
                    anchors {
                        top: mediaFlickable.bottom
                        left: parent.left
                        right: parent.right
                        topMargin: vpx(8)
                    }
                    height: vpx(6)
                    radius: height / 2
                    color: "#555"
                    opacity: mediaFlickable.moving || mediaFlickable.flicking ? 0.8 : 0.3
                    visible: mediaFlickable.contentWidth > mediaFlickable.width

                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    Rectangle {
                        id: mediaScrollHandle
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: Math.max(vpx(30), mediaScrollBar.width * mediaFlickable.visibleArea.widthRatio)

                        x: Math.min(
                            Math.max(
                                0,
                                mediaFlickable.visibleArea.xPosition * mediaScrollBar.width
                            ),
                            mediaScrollBar.width - mediaScrollHandle.width
                        )

                        radius: height / 2
                        color: accentColor
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
                text: sharedGamesFilter && sharedGamesFilter.currentFilter !== "All Games" ?
                "Filter: " + sharedGamesFilter.currentFilter : ""
                color: accentColor
                font.family: condensedFontFamily
                font.pixelSize: vpx(14)
                visible: text !== ""
            }

            ColumnLayout {
                id: basicInfoColumn
                width: parent.width
                spacing: vpx(16)
                visible: displayGame

                Text {
                    text: "BASIC INFO"
                    color: accentColor
                    font.family: condensedFontFamily
                    font.pixelSize: vpx(16)
                    font.bold: true
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: vpx(6)
                    Layout.rightMargin: vpx(6)
                    spacing: vpx(10)

                    Loader {
                        sourceComponent: infoCardComponent
                        Layout.fillWidth: true
                        Layout.preferredHeight: vpx(65)

                        onLoaded: {
                            item.iconSource = "assets/images/icons/year.svg"
                            item.label = "YEAR"
                            item.value = Qt.binding(function() {
                                return displayGame && displayGame.releaseYear > 0 ?
                                displayGame.releaseYear.toString() : "Unknown"
                            })
                        }
                    }

                    Loader {
                        sourceComponent: infoCardComponent
                        Layout.fillWidth: true
                        Layout.preferredHeight: vpx(65)

                        onLoaded: {
                            item.iconSource = "assets/images/icons/genre.svg"
                            item.label = "GENRE"
                            item.value = Qt.binding(function() {
                                return displayGame && displayGame.genre ?
                                Utils.getFirstGenre(displayGame) : "Unknown"
                            })
                        }
                    }
                }

                Loader {
                    sourceComponent: infoCardComponent
                    Layout.fillWidth: true
                    Layout.preferredHeight: vpx(65)
                    Layout.leftMargin: vpx(6)
                    Layout.rightMargin: vpx(6)

                    onLoaded: {
                        item.iconSource = "assets/images/icons/developer.svg"
                        item.label = "DEVELOPER"
                        item.value = Qt.binding(function() {
                            return displayGame && displayGame.developer ?
                            displayGame.developer : "Unknown"
                        })
                    }
                }

                Loader {
                    sourceComponent: infoCardComponent
                    Layout.fillWidth: true
                    Layout.preferredHeight: vpx(65)
                    Layout.leftMargin: vpx(6)
                    Layout.rightMargin: vpx(6)

                    onLoaded: {
                        item.iconSource = "assets/images/icons/publisher.svg"
                        item.label = "PUBLISHER"
                        item.value = Qt.binding(function() {
                            return displayGame && displayGame.publisher ?
                            displayGame.publisher : "Unknown"
                        })
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: vpx(6)
                    Layout.rightMargin: vpx(6)
                    spacing: vpx(10)

                    Loader {
                        sourceComponent: infoCardComponent
                        Layout.fillWidth: true
                        Layout.preferredHeight: vpx(65)

                        onLoaded: {
                            item.iconSource = "assets/images/icons/players.svg"
                            item.label = "PLAYERS"
                            item.value = Qt.binding(function() {
                                return displayGame ? displayGame.players + "P" : "1P"
                            })
                        }
                    }

                    Loader {
                        sourceComponent: infoCardComponent
                        Layout.fillWidth: true
                        Layout.preferredHeight: vpx(65)

                        onLoaded: {
                            item.iconSource = "assets/images/icons/rating.svg"
                            item.label = "RATING"
                            item.value = Qt.binding(function() {
                                return displayGame ? Math.round(displayGame.rating * 100) + "%" : "0%"
                            })
                        }
                    }
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

            ColumnLayout {
                id: statsColumn
                width: parent.width
                spacing: vpx(16)
                visible: displayGame && (displayGame.playCount > 0 || displayGame.playTime > 0)

                Text {
                    text: "STATISTICS"
                    color: accentColor
                    font.family: condensedFontFamily
                    font.pixelSize: vpx(16)
                    font.bold: true
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: vpx(6)
                    Layout.rightMargin: vpx(6)
                    spacing: vpx(10)

                    Loader {
                        sourceComponent: infoCardComponent
                        Layout.fillWidth: true
                        Layout.preferredHeight: vpx(65)

                        onLoaded: {
                            item.iconSource = "assets/images/icons/playcount.svg"
                            item.label = "PLAY COUNT"
                            item.value = Qt.binding(function() {
                                return displayGame ? displayGame.playCount.toString() : "0"
                            })
                        }
                    }

                    Loader {
                        sourceComponent: infoCardComponent
                        Layout.fillWidth: true
                        Layout.preferredHeight: vpx(65)

                        onLoaded: {
                            item.iconSource = "assets/images/icons/playtime.svg"
                            item.label = "PLAY TIME"
                            item.value = Qt.binding(function() {
                                return displayGame ? Utils.formatPlayTime(displayGame.playTime) : "0h 0m"
                            })
                        }
                    }
                }

                Loader {
                    sourceComponent: infoCardComponent
                    Layout.fillWidth: true
                    Layout.preferredHeight: vpx(65)
                    Layout.leftMargin: vpx(6)
                    Layout.rightMargin: vpx(6)

                    onLoaded: {
                        item.iconSource = "assets/images/icons/lastplayed.svg"
                        item.label = "LAST PLAYED"
                        item.value = Qt.binding(function() {
                            return displayGame && displayGame.lastPlayed ?
                            Utils.formatDate(displayGame.lastPlayed) : "Never"
                        })
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: vpx(2)
                    Layout.leftMargin: vpx(6)
                    Layout.rightMargin: vpx(6)
                    radius: height / 2
                    color: "#333"

                    Rectangle {
                        width: vpx(60)
                        height: parent.height
                        radius: parent.radius
                        color: accentColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
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
                            //console.log("Launch button clicked for:", displayGame.title);

                            if (displayGame.collections) {
                                //console.log("Display game collections:", displayGame.collections.count);
                                for (var i = 0; i < displayGame.collections.count; i++) {
                                    var col = displayGame.collections.get(i);
                                    //console.log("  -", col.name);
                                }
                            }

                            var success = Utils.launchExactGame(displayGame, api);

                            if (!success) {
                                //console.log("Fallback: calling root.launchCurrentGame()");
                                root.launchCurrentGame();
                            }
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

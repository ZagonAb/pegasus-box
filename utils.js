function formatPlayTime(seconds) {
    if (!seconds || seconds < 60) {
        return "0h 0m";
    }

    var hours = Math.floor(seconds / 3600);
    var minutes = Math.floor((seconds % 3600) / 60);

    return hours + "h " + minutes + "m";
}


function formatDate(dateObj) {
    if (!dateObj || !dateObj.getFullYear) {
        return "Never";
    }

    var now = new Date();
    var diff = now - dateObj;
    var diffDays = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
        return "Today";
    } else if (diffDays === 1) {
        return "Yesterday";
    } else if (diffDays < 7) {
        return diffDays + " days ago";
    } else if (diffDays < 30) {
        var weeks = Math.floor(diffDays / 7);
        return weeks + " week" + (weeks > 1 ? "s" : "") + " ago";
    } else {
        var day = dateObj.getDate();
        var month = dateObj.getMonth() + 1;
        var year = dateObj.getFullYear();

        return (day < 10 ? "0" : "") + day + "/" +
        (month < 10 ? "0" : "") + month + "/" +
        year;
    }
}


function getAverageColor(imageUrl) {
    return "#333333";
}

function exists(value) {
    return value !== undefined && value !== null && value !== "";
}

function capitalize(text) {
    if (!text) return "";
    return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase();
}

function truncate(text, maxLength) {
    if (!text) return "";
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - 3) + "...";
}

function saveToLocalStorage(key, value) {
    try {
        if (typeof localStorage !== 'undefined') {
            localStorage.setItem(key, JSON.stringify(value));
            return true;
        }
    } catch (e) {
        console.error("Error saving to localStorage:", e);
    }
    return false;
}

function loadFromLocalStorage(key, defaultValue) {
    try {
        if (typeof localStorage !== 'undefined') {
            var item = localStorage.getItem(key);
            return item ? JSON.parse(item) : defaultValue;
        }
    } catch (e) {
        console.error("Error loading from localStorage:", e);
    }
    return defaultValue;
}

function getSafeIndex(index, maxCount) {
    if (index === undefined || index === null) return 0;
    if (maxCount <= 0) return 0;
    return Math.max(0, Math.min(index, maxCount - 1));
}

function isValidGame(game) {
    return game && game.title && game.launch;
}

function isValidCollection(collection) {
    return collection && collection.name && collection.games;
}

function debugStateInfo(rootObj) {
    if (!rootObj) return "Root object not available";

    var info = {
        collectionIndex: rootObj.currentCollectionIndex,
        gameIndex: rootObj.currentGameIndex,
        collectionsCount: api.collections ? api.collections.count : 0,
        currentCollection: rootObj.currentCollection ? rootObj.currentCollection.name : "null",
        currentGame: rootObj.currentGame ? rootObj.currentGame.title : "null",
        gamesInCollection: rootObj.currentCollection ? rootObj.currentCollection.games.count : 0
    };

    return JSON.stringify(info, null, 2);
}


function cleanGameTitle(title) {
    if (!title || typeof title !== 'string') {
        return title || '';
    }

    const patterns = [
        /\s*\([^)]*(?:USA|NGM|Euro|Europe|Japan|World|Japan, USA|Korea|Asia|Brazil|Germany|France|Italy|Spain|UK|Australia|Canada|rev|sitdown|set|Hispanic|China|Ver|ver|US|68k|bootleg|Nintendo|Taiwan|Hong Kong|Latin America|Mexico|Russia|Sweden|Netherlands|Belgium|Portugal|Greece|Finland|Norway|Denmark|Poland|Czech|Slovak|Hungary|Romania|Bulgaria|Croatia|Serbia|Turkey|Israel|UAE|Saudi Arabia|South Africa|Egypt|Philippines|Indonesia|Malaysia|Singapore|Thailand|Vietnam)[^)]*\)/gi,
        /\s*\([^)]*(?:Rev \d+|Version \d+|v\d+\.\d+|Update \d+|Beta|Alpha|Demo|Prototype|Unl|Sample|Preview|Trial)[^)]*\)/gi,
        /\s*\([^)]*(?:NES|SNES|N64|GC|Wii|Switch|GB|GBC|GBA|DS|3DS|PS1|PS2|PS3|PS4|PS5|PSP|Vita|Xbox|Xbox 360|Xbox One|Genesis|Mega Drive|Saturn|Dreamcast|Arcade|MAME|FBA|Neo Geo)[^)]*\)/gi,
        /\s*-\s*(?:USA|EUR|JPN|KOR|ASI|BRA|GER|FRA|ITA|SPA|UK|AUS|CAN|CHN|TWN|HKG|LAT|MEX|RUS)[\s\-]*/gi,
        /\s*\[[^\]]*(?:Rev \d+|v\d+\.\d+)[^\]]*\]/gi,
        /\s*\[[^\]]*(?:Good|Bad|Overdump|Underdump|Verified|Trurip|No-Intro|Redump)[^\]]*\]/gi,
        /\s*\[[^\]]*(?:Crack|Trainer|Cheat|Hack|Patch|Fixed|Translated)[^\]]*\]/gi,
        /\s*\[[^\]]*(?:!\?|!\s*|\(\?\))[^\]]*\]/gi,
        /\s*\(Disk \d+ of \d+\)/gi,
        /\s*\(Side [A-B]\)/gi,
        /\s*\(Track \d+\)/gi,
        /\s*\([\d\s]+in[\d\s]+\)/gi,
        /\s*\(\d{4}[-\.]\d{2}[-\.]\d{2}\)/,
        /\s*\(\s*\d{4}\s*\)/gi
        ];

        let cleanedTitle = title;

        patterns.forEach(pattern => {
            cleanedTitle = cleanedTitle.replace(pattern, '');
        });

        cleanedTitle = cleanedTitle
        .replace(/ZZZ\(notgame\):\s*/gi, '')
        .replace(/ZZZ\(notgame\):#\s*/gi, '');

        cleanedTitle = cleanedTitle
        .replace(/^\s+|\s+$/g, '')
        .replace(/\s{2,}/g, ' ')
        .replace(/^[-\s]+|[-\s]+$/g, '')
        .replace(/,\s*$/, '')
        .replace(/\.\s*$/, '');

        if (!cleanedTitle || cleanedTitle.trim() === '') {
            return title.trim();
        }

        return cleanedTitle.trim();
}

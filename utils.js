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

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

function getFilterAvailability(collection) {
    if (!collection || !collection.games || collection.games.count === 0) {
        return {
            favorites: false,
            lastPlayed: false,
            topRating: false,
            year: false,
            categories: false
        }
    }

    var hasFavorites = false
    var hasLastPlayed = false
    var hasRating = false
    var hasYear = false

    // Contadores para debug
    var totalGames = collection.games.count
    var favoritesCount = 0
    var lastPlayedCount = 0
    var ratingCount = 0
    var yearCount = 0

    for (var i = 0; i < totalGames; i++) {
        var game = collection.games.get(i)
        if (!game) continue

            if (game.favorite) {
                hasFavorites = true
                favoritesCount++
            }

            if (game.lastPlayed && game.lastPlayed.getTime) {
                var time = game.lastPlayed.getTime()
                if (!isNaN(time) && time > 0) {
                    hasLastPlayed = true
                    lastPlayedCount++
                }
            }

            if (game.rating && game.rating > 0) {
                hasRating = true
                ratingCount++
            }

            if (game.releaseYear && game.releaseYear > 0) {
                hasYear = true
                yearCount++
            }
    }

    console.log("Filter availability check for", collection.name + ":")
    console.log("- Total games:", totalGames)
    console.log("- Favorites:", favoritesCount, "available:", hasFavorites)
    console.log("- Last played:", lastPlayedCount, "available:", hasLastPlayed)
    console.log("- Rating:", ratingCount, "available:", hasRating)
    console.log("- Year:", yearCount, "available:", hasYear)

    return {
        favorites: hasFavorites,
        lastPlayed: hasLastPlayed,
        topRating: hasRating,
        year: hasYear,
        categories: false
    }
}

function applyGameFilter(games, filterType) {
    if (!games || games.count === 0) return games

        switch(filterType) {
            case "Favorites":
                // Filtrar solo favoritos
                return filterGamesByFavorite(games, true)
            case "Last Played":
                // Ordenar por último jugado
                return sortGamesByLastPlayed(games)
            case "Top Rating":
                // Ordenar por rating
                return sortGamesByRating(games)
            case "Year":
                // Ordenar por año
                return sortGamesByYear(games)
            case "All Games":
            default:
                // Ordenar alfabéticamente
                return sortGamesAlphabetically(games)
        }
}

function filterGamesByFavorite(games, favoriteOnly) {
    var result = []
    for (var i = 0; i < games.count; i++) {
        var game = games.get(i)
        if (game && game.favorite === favoriteOnly) {
            result.push(game)
        }
    }
    return result
}

function sortGamesByLastPlayed(games) {
    var gameArray = []
    for (var i = 0; i < games.count; i++) {
        var game = games.get(i)
        if (game && game.lastPlayed && game.lastPlayed.getTime) {
            gameArray.push(game)
        }
    }

    // Ordenar por fecha (más reciente primero)
    gameArray.sort(function(a, b) {
        var timeA = a.lastPlayed.getTime()
        var timeB = b.lastPlayed.getTime()
        return timeB - timeA
    })

    return gameArray
}

function sortGamesByRating(games) {
    var gameArray = []
    for (var i = 0; i < games.count; i++) {
        var game = games.get(i)
        if (game) {
            gameArray.push(game)
        }
    }

    // Ordenar por rating (más alto primero)
    gameArray.sort(function(a, b) {
        return b.rating - a.rating
    })

    return gameArray
}

function sortGamesByYear(games) {
    var gameArray = []
    for (var i = 0; i < games.count; i++) {
        var game = games.get(i)
        if (game && game.releaseYear > 0) {
            gameArray.push(game)
        }
    }

    // Ordenar por año (más reciente primero)
    gameArray.sort(function(a, b) {
        return b.releaseYear - a.releaseYear
    })

    return gameArray
}

function sortGamesAlphabetically(games) {
    var gameArray = []
    for (var i = 0; i < games.count; i++) {
        var game = games.get(i)
        if (game) {
            gameArray.push(game)
        }
    }

    // Ordenar alfabéticamente por título
    gameArray.sort(function(a, b) {
        var titleA = a.title || ""
        var titleB = b.title || ""
        return titleA.localeCompare(titleB)
    })

    return gameArray
}

function countFavorites(games) {
    if (!games || games.count === 0) return 0

        var count = 0
        for (var i = 0; i < games.count; i++) {
            var game = games.get(i)
            if (game && game.favorite) {
                count++
            }
        }
        return count
}

function hasRecentlyPlayed(games) {
    if (!games || games.count === 0) return false

        // Considerar "recientemente jugado" si se jugó en los últimos 30 días
        var thirtyDaysAgo = new Date()
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)

        for (var i = 0; i < games.count; i++) {
            var game = games.get(i)
            if (game && game.lastPlayed && game.lastPlayed.getTime) {
                var lastPlayedTime = game.lastPlayed.getTime()
                if (!isNaN(lastPlayedTime) && lastPlayedTime > thirtyDaysAgo.getTime()) {
                    return true
                }
            }
        }
        return false
}

function cleanAndSplitGenres(genreText) {
    if (!genreText) return [];

    var separators = [",", "/", "-", "&", "|", ";"];
    var allParts = [genreText];

    for (var i = 0; i < separators.length; i++) {
        var separator = separators[i];
        var newParts = [];

        for (var j = 0; j < allParts.length; j++) {
            var part = allParts[j];
            var splitParts = part.split(separator);

            for (var k = 0; k < splitParts.length; k++) {
                newParts.push(splitParts[k]);
            }
        }
        allParts = newParts;
    }

    var cleanedParts = [];
    for (var l = 0; l < allParts.length; l++) {
        var cleaned = allParts[l].trim();

        if (cleaned.length > 0 &&
            cleaned.toLowerCase() !== "and" &&
            cleaned.toLowerCase() !== "or" &&
            cleaned.toLowerCase() !== "game" &&
            cleaned.length > 2) {
            cleanedParts.push(cleaned);
            }
    }

    return cleanedParts;
}

function getFirstGenre(gameData) {
    if (!gameData || !gameData.genre) return "Unknown";

    var cleanedGenres = cleanAndSplitGenres(gameData.genre);
    return cleanedGenres.length > 0 ? cleanedGenres[0] : "Unknown";
}

import QtQuick 2.15
import SortFilterProxyModel 0.2
import "utils.js" as Utils
Item {
    id: gamesFilter

    property var sourceModel: null
    property string currentFilter: "All Games"
    property string searchText: ""
    property string searchField: "title"
    property var filteredModel: gamesProxyModel
    property bool globalSearchMode: false
    property bool isSearching: false
    property bool useAllGamesModel: false

    signal currentFilteredGameChanged(var game)
    signal searchCompleted()

    SortFilterProxyModel {
        id: gamesProxyModel

        sourceModel: {
            if (gamesFilter.useAllGamesModel) {
                //console.log("GamesFilter: Using GAME LIBRARY mode (", api.allGames.count, "games )")
                return api.allGames
            }

            if (gamesFilter.globalSearchMode && gamesFilter.searchText !== "") {
                //console.log("GamesFilter: Using api.allGames (", api.allGames.count, "games )")
                return api.allGames
            }

            //console.log("GamesFilter: Using collection model")
            return gamesFilter.sourceModel
        }

        filters: ExpressionFilter {
            id: searchFilter
            enabled: gamesFilter.searchText !== ""
            expression: {
                if (gamesFilter.searchText === "") {
                    return true
                }

                var searchLower = gamesFilter.searchText.toLowerCase()
                var field = gamesFilter.searchField

                switch(field) {
                    case "title":
                        var title = model.title || ""
                        return title.toLowerCase().indexOf(searchLower) !== -1

                    case "developer":
                        var developer = model.developer || ""
                        return developer.toLowerCase().indexOf(searchLower) !== -1

                    case "genre":
                        var genre = model.genre || ""
                        return genre.toLowerCase().indexOf(searchLower) !== -1

                    case "publisher":
                        var publisher = model.publisher || ""
                        return publisher.toLowerCase().indexOf(searchLower) !== -1

                    case "tags":
                        if (model.tagList && model.tagList.length > 0) {
                            for (var i = 0; i < model.tagList.length; i++) {
                                if (model.tagList[i].toLowerCase().indexOf(searchLower) !== -1) {
                                    return true
                                }
                            }
                        }
                        return false

                    case "sortBy":
                        var sortBy = model.sortBy || ""
                        return sortBy.toLowerCase().indexOf(searchLower) !== -1

                    default:
                        var defaultTitle = model.title || ""
                        return defaultTitle.toLowerCase().indexOf(searchLower) !== -1
                }
            }
        }

        sorters: [
            RoleSorter {
                id: favoriteSorter
                roleName: "favorite"
                sortOrder: Qt.DescendingOrder
                enabled: gamesFilter.currentFilter === "Favorites" && !gamesFilter.globalSearchMode
                priority: 10
            },

            RoleSorter {
                id: lastPlayedSorter
                roleName: "lastPlayed"
                sortOrder: Qt.DescendingOrder
                enabled: gamesFilter.currentFilter === "Last Played" && !gamesFilter.globalSearchMode
                priority: 9
            },

            RoleSorter {
                id: ratingSorter
                roleName: "rating"
                sortOrder: Qt.DescendingOrder
                enabled: gamesFilter.currentFilter === "Top Rating" && !gamesFilter.globalSearchMode
                priority: 8
            },

            RoleSorter {
                id: yearSorter
                roleName: "releaseYear"
                sortOrder: Qt.DescendingOrder
                enabled: gamesFilter.currentFilter === "Year" && !gamesFilter.globalSearchMode
                priority: 7
            },

            /*RoleSorter {
                id: playCountSorter
                roleName: "playCount"
                sortOrder: Qt.DescendingOrder
                enabled: gamesFilter.globalSearchMode
                priority: 6
            },*/

            RoleSorter {
                id: titleSorter
                roleName: "sortBy"
                sortOrder: Qt.AscendingOrder
                priority: 1
            }
        ]
    }

    function updateFilter(filterType) {
        //console.log("GamesFilter: Updating filter to:", filterType)
        currentFilter = filterType

        if (filterType !== "All Games" || searchText === "") {
            globalSearchMode = false
            isSearching = false
        }

        gamesProxyModel.invalidate()
        filterChanged()

        if (gamesProxyModel.count > 0) {
            currentFilteredGameChanged(gamesProxyModel.get(0))
        }
    }

    function updateSearch(text, field) {
        var trimmedText = text.trim()
        //console.log("GamesFilter: Updating search")
        //console.log("  - Text:", trimmedText)
        //console.log("  - Field:", field)

        searchText = trimmedText
        searchField = field || "title"
        isSearching = true

        if (trimmedText !== "") {
            globalSearchMode = true
            //console.log("GamesFilter: Global search ENABLED")
            //console.log("  - Searching in", api.allGames.count, "total games")
            //console.log("  - Search field:", searchField)
        } else {
            globalSearchMode = false
            isSearching = false
            //console.log("GamesFilter: Global search DISABLED")
        }

        gamesProxyModel.invalidate()
        searchChanged()

        var resultCount = gamesProxyModel.count
        //console.log("GamesFilter: Found", resultCount, "results")

        if (resultCount > 0) {
            var maxLog = Math.min(resultCount, 5)
            //console.log("GamesFilter: Top results:")
            for (var i = 0; i < maxLog; i++) {
                var game = gamesProxyModel.get(i)
                if (game) {
                    var fieldValue = ""
                    switch(searchField) {
                        case "developer": fieldValue = game.developer || "N/A"; break
                        case "genre": fieldValue = game.genre || "N/A"; break
                        case "publisher": fieldValue = game.publisher || "N/A"; break
                        case "sortBy": fieldValue = game.sortBy || "N/A"; break
                        default: fieldValue = game.title || "N/A"
                    }
                    //console.log("  " + (i+1) + ".", game.title, "(" + searchField + ":", fieldValue + ")")
                }
            }
            if (resultCount > 5) {
                //console.log("  ... and", (resultCount - 5), "more")
            }
        }

        searchCompleteTimer.restart()
    }

    Timer {
        id: searchCompleteTimer
        interval: 100
        onTriggered: {
            isSearching = false
            searchCompleted()
        }
    }

    function checkFilterAvailability(collection) {
        var gamesToCheck = null

        if (useAllGamesModel) {
            gamesToCheck = api.allGames
        } else if (collection && collection.games) {
            gamesToCheck = collection.games
        }

        if (!gamesToCheck) {
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
        var gamesCount = gamesToCheck.count
        var checkLimit = Math.min(gamesCount, 100)

        for (var i = 0; i < checkLimit; i++) {
            var game = gamesToCheck.get(i)
            if (game) {
                if (!hasFavorites && game.favorite === true) {
                    hasFavorites = true
                }

                if (!hasLastPlayed && game.lastPlayed) {
                    var timestamp = game.lastPlayed.getTime()
                    if (!isNaN(timestamp) && timestamp > 0) {
                        hasLastPlayed = true
                    }
                }

                if (!hasRating && game.rating > 0) {
                    hasRating = true
                }

                if (!hasYear && game.releaseYear > 0) {
                    hasYear = true
                }
            }

            if (hasFavorites && hasLastPlayed && hasRating && hasYear) {
                break
            }
        }

        var result = {
            favorites: hasFavorites,
            lastPlayed: hasLastPlayed,
            topRating: hasRating,
            year: hasYear,
            categories: false
        }

        //console.log("GamesFilter: Filter availability:", JSON.stringify(result))
        return result
    }

    function resetFilter() {
        //console.log("GamesFilter: Resetting filter to All Games")
        currentFilter = "All Games"
        searchText = ""
        searchField = "title"
        globalSearchMode = false
        isSearching = false
        gamesProxyModel.invalidate()
    }

    function getFilteredCount() {
        return gamesProxyModel.count
    }

    function getGameAt(index) {
        if (index >= 0 && index < gamesProxyModel.count) {
            return gamesProxyModel.get(index)
        }
        return null
    }

    function getAllGames() {
        return gamesProxyModel.toVarArray()
    }

    signal filterChanged()
    signal searchChanged()

    function activateGameLibrary(activate) {
        //console.log("GamesFilter: Game Library mode", activate ? "ACTIVATED" : "DEACTIVATED")
        useAllGamesModel = activate

        if (activate) {
            currentFilter = "All Games"
            searchText = ""
            searchField = "title"
            globalSearchMode = false
            isSearching = false
        }

        gamesProxyModel.invalidate()
        filterChanged()

        if (gamesProxyModel.count > 0) {
            currentFilteredGameChanged(gamesProxyModel.get(0))
        }
    }

    Component.onCompleted: {
        //console.log("=".repeat(60))
        //console.log("GamesFilter: Component loaded with field-specific search")
        //console.log("  - Total games in api.allGames:", api.allGames.count)
        //console.log("  - Total collections:", api.collections.count)
        //console.log("  - Available search fields: title, developer, genre, publisher, tags, sortBy")
        //console.log("  - Default search field: title")
        //console.log("=".repeat(60))
    }

    Connections {
        target: gamesProxyModel
        function onCountChanged() {
            //console.log("GamesFilter: Filtered count changed to", gamesProxyModel.count)
        }
    }
}

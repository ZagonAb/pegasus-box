import QtQuick 2.15
import SortFilterProxyModel 0.2
import "utils.js" as Utils

Item {
    id: gamesFilter

    // Propiedades públicas
    property var sourceModel: null
    property string currentFilter: "All Games"
    property string searchText: ""
    property string searchField: "title" // Campo activo de búsqueda
    property var filteredModel: gamesProxyModel

    // Modo de búsqueda global
    property bool globalSearchMode: false
    property bool isSearching: false

    signal currentFilteredGameChanged(var game)
    signal searchCompleted()

    // Proxy model para ordenar/filtrar
    SortFilterProxyModel {
        id: gamesProxyModel

        // Cambiar dinámicamente entre colección actual y api.allGames
        sourceModel: {
            if (gamesFilter.globalSearchMode && gamesFilter.searchText !== "") {
                console.log("GamesFilter: Using api.allGames (", api.allGames.count, "games )")
                return api.allGames
            }
            console.log("GamesFilter: Using collection model")
            return gamesFilter.sourceModel
        }

        // FILTRO MEJORADO: Buscar en el campo específico seleccionado
        filters: ExpressionFilter {
            id: searchFilter
            enabled: gamesFilter.searchText !== ""
            expression: {
                if (gamesFilter.searchText === "") {
                    return true
                }

                var searchLower = gamesFilter.searchText.toLowerCase()
                var field = gamesFilter.searchField

                // Buscar según el campo seleccionado
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
                        // Fallback a búsqueda en título
                        var defaultTitle = model.title || ""
                        return defaultTitle.toLowerCase().indexOf(searchLower) !== -1
                }
            }
        }

        // Ordenamiento optimizado
        sorters: [
            // Favoritos primero (solo si el filtro está activo Y no estamos en búsqueda global)
            RoleSorter {
                id: favoriteSorter
                roleName: "favorite"
                sortOrder: Qt.DescendingOrder
                enabled: gamesFilter.currentFilter === "Favorites" && !gamesFilter.globalSearchMode
                priority: 10
            },

            // Último jugado
            RoleSorter {
                id: lastPlayedSorter
                roleName: "lastPlayed"
                sortOrder: Qt.DescendingOrder
                enabled: gamesFilter.currentFilter === "Last Played" && !gamesFilter.globalSearchMode
                priority: 9
            },

            // Rating
            RoleSorter {
                id: ratingSorter
                roleName: "rating"
                sortOrder: Qt.DescendingOrder
                enabled: gamesFilter.currentFilter === "Top Rating" && !gamesFilter.globalSearchMode
                priority: 8
            },

            // Año de lanzamiento
            RoleSorter {
                id: yearSorter
                roleName: "releaseYear"
                sortOrder: Qt.DescendingOrder
                enabled: gamesFilter.currentFilter === "Year" && !gamesFilter.globalSearchMode
                priority: 7
            },

            // En búsqueda global: ordenar por relevancia (playCount) primero
            RoleSorter {
                id: playCountSorter
                roleName: "playCount"
                sortOrder: Qt.DescendingOrder
                enabled: gamesFilter.globalSearchMode
                priority: 6
            },

            // Título alfabético (siempre activo como fallback)
            RoleSorter {
                id: titleSorter
                roleName: "sortBy"  // Usar sortBy en lugar de title para mejor ordenamiento
                sortOrder: Qt.AscendingOrder
                priority: 1
            }
        ]
    }

    // Función para actualizar el filtro
    function updateFilter(filterType) {
        console.log("GamesFilter: Updating filter to:", filterType)
        currentFilter = filterType

        // Deshabilitar búsqueda global cuando se cambia de filtro
        if (filterType !== "All Games" || searchText === "") {
            globalSearchMode = false
            isSearching = false
        }

        // Invalidar y actualizar
        gamesProxyModel.invalidate()
        filterChanged()

        // Emitir juego actual si hay elementos
        if (gamesProxyModel.count > 0) {
            currentFilteredGameChanged(gamesProxyModel.get(0))
        }
    }

    // Función MEJORADA para actualizar la búsqueda con campo específico
    function updateSearch(text, field) {
        var trimmedText = text.trim()
        console.log("GamesFilter: Updating search")
        console.log("  - Text:", trimmedText)
        console.log("  - Field:", field)

        searchText = trimmedText
        searchField = field || "title"
        isSearching = true

        // Habilitar búsqueda global si hay texto
        if (trimmedText !== "") {
            globalSearchMode = true
            console.log("GamesFilter: Global search ENABLED")
            console.log("  - Searching in", api.allGames.count, "total games")
            console.log("  - Search field:", searchField)
        } else {
            globalSearchMode = false
            isSearching = false
            console.log("GamesFilter: Global search DISABLED")
        }

        // Forzar actualización
        gamesProxyModel.invalidate()
        searchChanged()

        // Log de resultados
        var resultCount = gamesProxyModel.count
        console.log("GamesFilter: Found", resultCount, "results")

        // Mostrar algunos resultados en el log (máximo 5)
        if (resultCount > 0) {
            var maxLog = Math.min(resultCount, 5)
            console.log("GamesFilter: Top results:")
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
                    console.log("  " + (i+1) + ".", game.title, "(" + searchField + ":", fieldValue + ")")
                }
            }
            if (resultCount > 5) {
                console.log("  ... and", (resultCount - 5), "more")
            }
        }

        // Pequeño delay para simular búsqueda y dar tiempo al UI
        searchCompleteTimer.restart()
    }

    // Timer para completar búsqueda
    Timer {
        id: searchCompleteTimer
        interval: 100 // Pequeño delay para que se vea el spinner
        onTriggered: {
            isSearching = false
            searchCompleted()
        }
    }

    // Función mejorada para verificar disponibilidad de filtros
    function checkFilterAvailability(collection) {
        if (!collection || !collection.games) {
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
        var gamesCount = collection.games.count

        // Optimización: revisar máximo 100 juegos para la verificación
        var checkLimit = Math.min(gamesCount, 100)

        for (var i = 0; i < checkLimit; i++) {
            var game = collection.games.get(i)
            if (game) {
                // Verificar favoritos
                if (!hasFavorites && game.favorite === true) {
                    hasFavorites = true
                }

                // Verificar lastPlayed (debe ser una fecha válida)
                if (!hasLastPlayed && game.lastPlayed) {
                    // Verificar si es una fecha válida comprobando getTime()
                    var timestamp = game.lastPlayed.getTime()
                    if (!isNaN(timestamp) && timestamp > 0) {
                        hasLastPlayed = true
                    }
                }

                // Verificar rating (mayor que 0)
                if (!hasRating && game.rating > 0) {
                    hasRating = true
                }

                // Verificar año de lanzamiento
                if (!hasYear && game.releaseYear > 0) {
                    hasYear = true
                }
            }

            // Salir temprano si ya encontramos todos
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

        console.log("GamesFilter: Filter availability:", JSON.stringify(result))
        return result
    }

    // Función para resetear filtro
    function resetFilter() {
        console.log("GamesFilter: Resetting filter to All Games")
        currentFilter = "All Games"
        searchText = ""
        searchField = "title"
        globalSearchMode = false
        isSearching = false
        gamesProxyModel.invalidate()
    }

    // Función para contar juegos filtrados
    function getFilteredCount() {
        return gamesProxyModel.count
    }

    // Función para obtener juego por índice
    function getGameAt(index) {
        if (index >= 0 && index < gamesProxyModel.count) {
            return gamesProxyModel.get(index)
        }
        return null
    }

    // Función para obtener todos los juegos como array (útil para operaciones complejas)
    function getAllGames() {
        return gamesProxyModel.toVarArray()
    }

    // Señales
    signal filterChanged()
    signal searchChanged()

    // Inicializar
    Component.onCompleted: {
        console.log("=".repeat(60))
        console.log("GamesFilter: Component loaded with field-specific search")
        console.log("  - Total games in api.allGames:", api.allGames.count)
        console.log("  - Total collections:", api.collections.count)
        console.log("  - Available search fields: title, developer, genre, publisher, tags, sortBy")
        console.log("  - Default search field: title")
        console.log("=".repeat(60))
    }

    // Conexión para monitorear cambios en el modelo
    Connections {
        target: gamesProxyModel
        function onCountChanged() {
            console.log("GamesFilter: Filtered count changed to", gamesProxyModel.count)
        }
    }
}


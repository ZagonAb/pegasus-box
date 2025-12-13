import QtQuick 2.15
import SortFilterProxyModel 0.2
import "utils.js" as Utils

Item {
    id: gamesFilter

    // Propiedades públicas
    property var sourceModel: null
    property string currentFilter: "All Games"
    property string searchText: ""
    property var filteredModel: gamesProxyModel

    signal currentFilteredGameChanged(var game)

    // Proxy model para ordenar/filtrar
    SortFilterProxyModel {
        id: gamesProxyModel
        sourceModel: gamesFilter.sourceModel

        // Filtro por búsqueda - CORREGIDO: usar ExpressionFilter en lugar de StringFilter
        filters: ExpressionFilter {
            id: searchFilter
            enabled: gamesFilter.searchText !== ""
            expression: {
                if (gamesFilter.searchText === "") {
                    return true
                }

                var title = model.title || ""
                var searchLower = gamesFilter.searchText.toLowerCase()
                var titleLower = title.toString().toLowerCase()

                return titleLower.indexOf(searchLower) !== -1
            }
        }

        // Ordenamiento por filtro seleccionado
        sorters: [
            // Primer nivel: Favoritos (si el filtro es "Favorites")
            RoleSorter {
                id: favoriteSorter
                roleName: "favorite"
                sortOrder: Qt.DescendingOrder
                enabled: gamesFilter.currentFilter === "Favorites"
            },
            // Segundo nivel: Último jugado (si el filtro es "Last Played")
            RoleSorter {
                id: lastPlayedSorter
                roleName: "lastPlayed"
                sortOrder: Qt.DescendingOrder
                enabled: gamesFilter.currentFilter === "Last Played"
            },
            // Tercer nivel: Rating (si el filtro es "Top Rating")
            RoleSorter {
                id: ratingSorter
                roleName: "rating"
                sortOrder: Qt.DescendingOrder
                enabled: gamesFilter.currentFilter === "Top Rating"
            },
            // Cuarto nivel: Año de lanzamiento (si el filtro es "Year")
            RoleSorter {
                id: yearSorter
                roleName: "releaseYear"
                sortOrder: Qt.DescendingOrder
                enabled: gamesFilter.currentFilter === "Year"
            },
            // Quinto nivel: Título (orden alfabético para todo)
            RoleSorter {
                id: titleSorter
                roleName: "title"
                sortOrder: Qt.AscendingOrder
                // Siempre activo para mantener orden consistente
            }
        ]
    }

    // Función para actualizar el modelo según el filtro seleccionado
    function updateFilter(filterType) {
        console.log("GamesFilter: Updating filter to:", filterType)
        currentFilter = filterType

        // Fuerza la actualización del proxy model
        gamesProxyModel.invalidate()

        // Emitir señales de cambio
        filterChanged()

        // Emitir juego actual si hay elementos
        if (gamesProxyModel.count > 0) {
            currentFilteredGameChanged(gamesProxyModel.get(0))
        }
    }

    // Función para actualizar la búsqueda
    function updateSearch(text) {
        console.log("GamesFilter: Updating search to:", text)
        searchText = text
        gamesProxyModel.invalidate()
        searchChanged()
    }

    // Función para verificar disponibilidad de filtros
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

        for (var i = 0; i < collection.games.count; i++) {
            var game = collection.games.get(i)
            if (game) {
                if (game.favorite) hasFavorites = true

                    if (game.lastPlayed && game.lastPlayed.getTime) {
                        if (!isNaN(game.lastPlayed.getTime())) {
                            hasLastPlayed = true
                        }
                    }

                    if (game.rating > 0) hasRating = true
                        if (game.releaseYear > 0) hasYear = true
            }

            // Si ya encontramos todos, podemos salir
            if (hasFavorites && hasLastPlayed && hasRating && hasYear) break
        }

        return {
            favorites: hasFavorites,
            lastPlayed: hasLastPlayed,
            topRating: hasRating,
            year: hasYear,
            categories: false // Por ahora, siempre falso hasta que implementemos categorías
        }
    }

    // Función para resetear filtro
    function resetFilter() {
        console.log("GamesFilter: Resetting filter to All Games")
        currentFilter = "All Games"
        searchText = ""
        gamesProxyModel.invalidate()
    }

    // Función para contar cuántos juegos cumplen con el filtro actual
    function getFilteredCount() {
        return gamesProxyModel.count
    }

    // Función para obtener el juego en un índice específico
    function getGameAt(index) {
        if (index >= 0 && index < gamesProxyModel.count) {
            return gamesProxyModel.get(index)
        }
        return null
    }

    // Señales
    signal filterChanged()
    signal searchChanged()

    // Inicializar
    Component.onCompleted: {
        console.log("GamesFilter component loaded")
    }
}

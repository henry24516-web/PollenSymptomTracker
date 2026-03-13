import Foundation
import SwiftUI

/// ViewModel for pollen data
@MainActor
class PollenViewModel: ObservableObject {
    @Published var currentPollen: PollenData?
    @Published var historicalPollen: [PollenData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var location: (lat: Double, lon: Double, name: String) = (51.5074, -0.1278, "London")

    @Published var locationQuery = ""
    @Published var locationSuggestions: [LocationSuggestion] = []
    @Published var isSearchingLocations = false

    private let apiService = PollenAPIService.shared
    private let geocodingService = GeocodingService.shared
    private let storage = StorageService.shared

    init() {
        if let savedLocation = storage.loadUserLocation() {
            location = (savedLocation.latitude, savedLocation.longitude, savedLocation.cityName ?? "Current")
        }

        if let cached = storage.loadCachedPollenData() {
            currentPollen = cached
        }
    }

    func fetchCurrentPollen() async {
        isLoading = true
        errorMessage = nil

        do {
            let data = try await apiService.fetchPollenData(location: (location.lat, location.lon))
            let localizedData = PollenData(
                date: data.date,
                treePollen: data.treePollen,
                grassPollen: data.grassPollen,
                weedPollen: data.weedPollen,
                location: location.name,
                dataSource: data.dataSource,
                confidence: data.confidence,
                isFallback: data.isFallback
            )
            currentPollen = localizedData
            storage.cachePollenData(localizedData)

            if localizedData.dataSource.contains("Europe") {
                TelemetryService.shared.trackFallback(.primary)
            } else {
                TelemetryService.shared.trackFallback(.backup)
            }
        } catch {
            errorMessage = "Live pollen feeds unavailable. Showing resilient fallback model."

            if let cached = storage.loadCachedPollenData() {
                currentPollen = PollenData(
                    date: cached.date,
                    treePollen: cached.treePollen,
                    grassPollen: cached.grassPollen,
                    weedPollen: cached.weedPollen,
                    location: location.name,
                    dataSource: "Cached last-known good",
                    confidence: .medium,
                    isFallback: true
                )
                TelemetryService.shared.trackFallback(.cache)
            } else {
                let logs = storage.loadSymptomLogs()
                currentPollen = apiService.generateModelFallback(
                    locationName: location.name,
                    latitude: location.lat,
                    recentSymptoms: logs
                )
                TelemetryService.shared.trackFallback(.localModel)
            }
        }

        isLoading = false
    }

    func fetchHistoricalPollen(days: Int = 7) async {
        isLoading = true

        do {
            let data = try await apiService.fetchHistoricalPollenData(days: days, location: (location.lat, location.lon))
            historicalPollen = data.map {
                PollenData(
                    date: $0.date,
                    treePollen: $0.treePollen,
                    grassPollen: $0.grassPollen,
                    weedPollen: $0.weedPollen,
                    location: location.name,
                    dataSource: $0.dataSource,
                    confidence: $0.confidence,
                    isFallback: $0.isFallback
                )
            }
        } catch {
            historicalPollen = generateSampleHistoricalData(days: days)
        }

        isLoading = false
    }

    func searchLocations() async {
        let query = locationQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else {
            locationSuggestions = []
            return
        }

        isSearchingLocations = true
        defer { isSearchingLocations = false }

        do {
            locationSuggestions = try await geocodingService.searchCity(query)
        } catch {
            locationSuggestions = []
        }
    }

    func selectLocation(_ suggestion: LocationSuggestion) {
        updateLocation(
            latitude: suggestion.latitude,
            longitude: suggestion.longitude,
            cityName: suggestion.name
        )
        locationQuery = ""
        locationSuggestions = []
    }

    func updateLocation(latitude: Double, longitude: Double, cityName: String?) {
        location = (latitude, longitude, cityName ?? "Current")
        storage.saveUserLocation(latitude: latitude, longitude: longitude, cityName: cityName)

        Task {
            await fetchCurrentPollen()
            await fetchHistoricalPollen()
        }
    }

    private func generateSamplePollen() -> PollenData {
        PollenData(
            treePollen: 35,
            grassPollen: 25,
            weedPollen: 15,
            location: location.name,
            dataSource: "Sample fallback",
            confidence: .low,
            isFallback: true
        )
    }

    private func generateSampleHistoricalData(days: Int) -> [PollenData] {
        var data: [PollenData] = []
        let calendar = Calendar.current

        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let treePollen = Double.random(in: 10...60)
            let grassPollen = Double.random(in: 10...50)
            let weedPollen = Double.random(in: 5...40)

            data.append(PollenData(
                date: date,
                treePollen: treePollen,
                grassPollen: grassPollen,
                weedPollen: weedPollen,
                location: location.name,
                dataSource: "Sample historical fallback",
                confidence: .low,
                isFallback: true
            ))
        }

        return data.reversed()
    }
}

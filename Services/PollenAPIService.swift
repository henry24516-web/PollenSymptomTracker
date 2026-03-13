import Foundation

/// Service for fetching pollen data with resilient fallback chain.
/// Primary data source: Open-Meteo Air Quality API (free)
class PollenAPIService {
    static let shared = PollenAPIService()

    private let baseURL = "https://air-quality-api.open-meteo.com/v1/air-quality"

    private var latitude: Double = 51.5074 // London default
    private var longitude: Double = -0.1278
    private let requestTimeout: TimeInterval = 12
    private let retryBudget = 1

    private init() {
        if let lat = ProcessInfo.processInfo.environment["POLLEN_LATITUDE"],
           let lon = ProcessInfo.processInfo.environment["POLLEN_LONGITUDE"] {
            latitude = Double(lat) ?? 51.5074
            longitude = Double(lon) ?? -0.1278
        }
    }

    /// Fallback chain:
    /// 1) Open-Meteo CAMS Europe
    /// 2) Open-Meteo CAMS Global
    func fetchPollenData(location: (lat: Double, lon: Double)? = nil) async throws -> PollenData {
        let lat = location?.lat ?? latitude
        let lon = location?.lon ?? longitude

        do {
            return try await fetchCurrentFromOpenMeteo(lat: lat, lon: lon, domain: "cams_europe", sourceLabel: "Open-Meteo CAMS Europe")
        } catch {
            return try await fetchCurrentFromOpenMeteo(lat: lat, lon: lon, domain: "cams_global", sourceLabel: "Open-Meteo CAMS Global")
        }
    }

    func fetchHistoricalPollenData(days: Int, location: (lat: Double, lon: Double)? = nil) async throws -> [PollenData] {
        let lat = location?.lat ?? latitude
        let lon = location?.lon ?? longitude

        do {
            return try await fetchHistoricalFromOpenMeteo(days: days, lat: lat, lon: lon, domain: "cams_europe", sourceLabel: "Open-Meteo CAMS Europe")
        } catch {
            return try await fetchHistoricalFromOpenMeteo(days: days, lat: lat, lon: lon, domain: "cams_global", sourceLabel: "Open-Meteo CAMS Global")
        }
    }

    /// Local model fallback when APIs are unavailable.
    /// Uses month seasonality + latitude weighting + user symptom intensity.
    func generateModelFallback(locationName: String, latitude: Double, recentSymptoms: [SymptomLog]) -> PollenData {
        let month = Calendar.current.component(.month, from: Date())

        // UK/Europe-oriented seasonality baseline (0-100 scale)
        let treeSeason: Double = [0, 15, 45, 75, 90, 70, 40, 20, 10, 8, 5, 2, 0][safe: month] ?? 20
        let grassSeason: Double = [0, 2, 8, 20, 45, 80, 95, 70, 35, 12, 4, 1, 0][safe: month] ?? 20
        let weedSeason: Double = [0, 1, 4, 10, 18, 30, 45, 60, 70, 55, 25, 8, 2][safe: month] ?? 20

        // Latitude adjustment: slightly lower intensity at very high latitudes.
        let latFactor = max(0.75, min(1.15, 1.0 - abs(latitude - 51.5) / 100.0))

        // Symptom adjustment from recent logs (0.85...1.25)
        let recent = recentSymptoms.suffix(7)
        let avgSymptom = recent.isEmpty ? 3.0 : recent.map { Double($0.overallSeverity) }.reduce(0, +) / Double(recent.count)
        let symptomFactor = max(0.85, min(1.25, 0.7 + (avgSymptom / 10.0)))

        return PollenData(
            treePollen: treeSeason * latFactor * symptomFactor,
            grassPollen: grassSeason * latFactor * symptomFactor,
            weedPollen: weedSeason * latFactor * symptomFactor,
            location: locationName,
            dataSource: "Fallback seasonal model",
            confidence: .low,
            isFallback: true
        )
    }

    // MARK: - Internals

    private func fetchCurrentFromOpenMeteo(lat: Double, lon: Double, domain: String, sourceLabel: String) async throws -> PollenData {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(name: "current", value: "alder_pollen,birch_pollen,grass_pollen,mugwort_pollen,ragweed_pollen"),
            URLQueryItem(name: "domains", value: domain),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = components?.url else { throw PollenAPIError.invalidURL }

        let data = try await fetchDataWithRetry(url: url, retries: retryBudget)
        let apiResponse = try JSONDecoder().decode(OpenMeteoAirQualityResponse.self, from: data)
        guard let current = apiResponse.current else { throw PollenAPIError.noData }

        let tree = max(current.alderPollen ?? 0, current.birchPollen ?? 0)
        let grass = current.grassPollen ?? 0
        let weed = max(current.mugwortPollen ?? 0, current.ragweedPollen ?? 0)

        return PollenData(
            treePollen: tree,
            grassPollen: grass,
            weedPollen: weed,
            location: "Current Location",
            dataSource: sourceLabel,
            confidence: domain == "cams_europe" ? .high : .medium,
            isFallback: domain != "cams_europe"
        )
    }

    private func fetchHistoricalFromOpenMeteo(days: Int, lat: Double, lon: Double, domain: String, sourceLabel: String) async throws -> [PollenData] {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(name: "hourly", value: "alder_pollen,birch_pollen,grass_pollen,mugwort_pollen,ragweed_pollen"),
            URLQueryItem(name: "past_days", value: String(max(1, min(days, 30)))),
            URLQueryItem(name: "domains", value: domain),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = components?.url else { throw PollenAPIError.invalidURL }

        let data = try await fetchDataWithRetry(url: url, retries: retryBudget)
        let decoded = try JSONDecoder().decode(OpenMeteoAirQualityResponse.self, from: data)
        guard let hourly = decoded.hourly,
              let timestamps = hourly.time,
              !timestamps.isEmpty else {
            throw PollenAPIError.noData
        }

        var dailyBuckets: [String: (date: Date, tree: Double, grass: Double, weed: Double)] = [:]
        let formatter = ISO8601DateFormatter()

        for index in 0..<timestamps.count {
            guard let date = formatter.date(from: timestamps[index]) else { continue }
            let day = Calendar.current.startOfDay(for: date)
            let dayKey = ISO8601DateFormatter().string(from: day)

            let alder = hourly.alderPollen?[safe: index] ?? 0
            let birch = hourly.birchPollen?[safe: index] ?? 0
            let grass = hourly.grassPollen?[safe: index] ?? 0
            let mugwort = hourly.mugwortPollen?[safe: index] ?? 0
            let ragweed = hourly.ragweedPollen?[safe: index] ?? 0

            let tree = max(alder, birch)
            let weed = max(mugwort, ragweed)

            if let existing = dailyBuckets[dayKey] {
                dailyBuckets[dayKey] = (existing.date, max(existing.tree, tree), max(existing.grass, grass), max(existing.weed, weed))
            } else {
                dailyBuckets[dayKey] = (day, tree, grass, weed)
            }
        }

        return dailyBuckets.values
            .sorted { $0.date < $1.date }
            .map {
                PollenData(
                    date: $0.date,
                    treePollen: $0.tree,
                    grassPollen: $0.grass,
                    weedPollen: $0.weed,
                    location: "Historical",
                    dataSource: sourceLabel,
                    confidence: domain == "cams_europe" ? .high : .medium,
                    isFallback: domain != "cams_europe"
                )
            }
    }

    private func fetchDataWithRetry(url: URL, retries: Int) async throws -> Data {
        var lastError: Error?

        for attempt in 0...retries {
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = requestTimeout
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw PollenAPIError.serverError
                }
                return data
            } catch {
                lastError = error
                if attempt < retries {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                }
            }
        }

        throw lastError ?? PollenAPIError.serverError
    }
}

enum PollenAPIError: Error, LocalizedError {
    case invalidURL
    case serverError
    case noData
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .serverError: return "Server error occurred"
        case .noData: return "No pollen data available"
        case .decodingError: return "Failed to parse response"
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

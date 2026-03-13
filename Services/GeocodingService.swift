import Foundation

struct LocationSuggestion: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let countryCode: String?

    init(name: String, latitude: Double, longitude: Double, countryCode: String?) {
        self.id = "\(name)-\(latitude)-\(longitude)"
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.countryCode = countryCode
    }
}

final class GeocodingService {
    static let shared = GeocodingService()
    private init() {}

    func searchCity(_ query: String, limit: Int = 8) async throws -> [LocationSuggestion] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")
        components?.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: String(limit)),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(OpenMeteoGeocodingResponse.self, from: data)

        return (decoded.results ?? []).map {
            let country = $0.countryCode?.uppercased()
            let name = [
                $0.name,
                $0.admin1,
                country
            ].compactMap { $0 }.joined(separator: ", ")

            return LocationSuggestion(
                name: name,
                latitude: $0.latitude,
                longitude: $0.longitude,
                countryCode: country
            )
        }
    }
}

private struct OpenMeteoGeocodingResponse: Codable {
    let results: [ResultItem]?

    struct ResultItem: Codable {
        let name: String?
        let latitude: Double
        let longitude: Double
        let countryCode: String?
        let admin1: String?

        enum CodingKeys: String, CodingKey {
            case name, latitude, longitude, admin1
            case countryCode = "country_code"
        }
    }
}

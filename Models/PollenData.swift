import Foundation

/// Represents pollen data from the API
struct PollenData: Codable, Identifiable {
    let id: UUID
    let date: Date
    let treePollen: Double
    let grassPollen: Double
    let weedPollen: Double
    let overallLevel: PollenLevel
    let location: String
    let dataSource: String
    let confidence: DataConfidence
    let isFallback: Bool

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        treePollen: Double,
        grassPollen: Double,
        weedPollen: Double,
        location: String,
        dataSource: String = "Unknown",
        confidence: DataConfidence = .medium,
        isFallback: Bool = false
    ) {
        self.id = id
        self.date = date
        self.treePollen = treePollen
        self.grassPollen = grassPollen
        self.weedPollen = weedPollen
        self.location = location
        self.dataSource = dataSource
        self.confidence = confidence
        self.isFallback = isFallback
        self.overallLevel = PollenData.calculateOverallLevel(tree: treePollen, grass: grassPollen, weed: weedPollen)
    }

    private enum CodingKeys: String, CodingKey {
        case id, date, treePollen, grassPollen, weedPollen, location, dataSource, confidence, isFallback
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        treePollen = try c.decode(Double.self, forKey: .treePollen)
        grassPollen = try c.decode(Double.self, forKey: .grassPollen)
        weedPollen = try c.decode(Double.self, forKey: .weedPollen)
        location = try c.decodeIfPresent(String.self, forKey: .location) ?? "Unknown"
        dataSource = try c.decodeIfPresent(String.self, forKey: .dataSource) ?? "Unknown"
        confidence = try c.decodeIfPresent(DataConfidence.self, forKey: .confidence) ?? .medium
        isFallback = try c.decodeIfPresent(Bool.self, forKey: .isFallback) ?? false
        overallLevel = PollenData.calculateOverallLevel(tree: treePollen, grass: grassPollen, weed: weedPollen)
    }

    static func calculateOverallLevel(tree: Double, grass: Double, weed: Double) -> PollenLevel {
        let maxPollen = max(tree, max(grass, weed))
        switch maxPollen {
        case 0..<20: return .low
        case 20..<50: return .moderate
        case 50..<80: return .high
        default: return .veryHigh
        }
    }
}

enum DataConfidence: String, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

enum PollenLevel: String, Codable, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"

    var color: String {
        switch self {
        case .low: return "green"
        case .moderate: return "yellow"
        case .high: return "orange"
        case .veryHigh: return "red"
        }
    }

    var icon: String {
        switch self {
        case .low: return "leaf.fill"
        case .moderate: return "leaf.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .veryHigh: return "exclamationmark.triangle.fill"
        }
    }
}

struct OpenMeteoAirQualityResponse: Codable {
    let current: CurrentAirQuality?
    let hourly: HourlyAirQuality?

    struct CurrentAirQuality: Codable {
        let alderPollen: Double?
        let birchPollen: Double?
        let grassPollen: Double?
        let mugwortPollen: Double?
        let ragweedPollen: Double?

        enum CodingKeys: String, CodingKey {
            case alderPollen = "alder_pollen"
            case birchPollen = "birch_pollen"
            case grassPollen = "grass_pollen"
            case mugwortPollen = "mugwort_pollen"
            case ragweedPollen = "ragweed_pollen"
        }
    }

    struct HourlyAirQuality: Codable {
        let time: [String]?
        let alderPollen: [Double]?
        let birchPollen: [Double]?
        let grassPollen: [Double]?
        let mugwortPollen: [Double]?
        let ragweedPollen: [Double]?

        enum CodingKeys: String, CodingKey {
            case time
            case alderPollen = "alder_pollen"
            case birchPollen = "birch_pollen"
            case grassPollen = "grass_pollen"
            case mugwortPollen = "mugwort_pollen"
            case ragweedPollen = "ragweed_pollen"
        }
    }
}

import Foundation

final class TelemetryService {
    static let shared = TelemetryService()

    private let defaults = UserDefaults.standard
    private let prefix = "com.pollenhealth.symptomtracker.telemetry."

    private init() {}

    enum FallbackPath: String, CaseIterable {
        case primary = "primary"
        case backup = "backup"
        case cache = "cache"
        case localModel = "local_model"
    }

    func trackFallback(_ path: FallbackPath) {
        let key = prefix + "fallback." + path.rawValue
        defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
        defaults.set(Date(), forKey: prefix + "last_event_at")
    }

    func fallbackStats() -> [FallbackPath: Int] {
        var out: [FallbackPath: Int] = [:]
        for path in FallbackPath.allCases {
            out[path] = defaults.integer(forKey: prefix + "fallback." + path.rawValue)
        }
        return out
    }

    func reset() {
        for path in FallbackPath.allCases {
            defaults.removeObject(forKey: prefix + "fallback." + path.rawValue)
        }
        defaults.removeObject(forKey: prefix + "last_event_at")
    }
}

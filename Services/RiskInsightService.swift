import Foundation

struct RiskWindow: Identifiable, Codable {
    let id = UUID()
    let startHour: Int
    let endHour: Int
    let riskLevel: PollenLevel
    let guidance: String
}

final class RiskInsightService {
    static let shared = RiskInsightService()
    private init() {}

    func riskWindows(current: PollenData) -> [RiskWindow] {
        switch current.overallLevel {
        case .low:
            return [RiskWindow(startHour: 11, endHour: 16, riskLevel: .moderate, guidance: "Low overall risk. Keep routine meds accessible.")]
        case .moderate:
            return [RiskWindow(startHour: 10, endHour: 16, riskLevel: .high, guidance: "Moderate day. Consider reducing long outdoor exposure at midday.")]
        case .high:
            return [RiskWindow(startHour: 9, endHour: 17, riskLevel: .high, guidance: "High-risk window. Wear sunglasses/mask and shower after outdoor time.")]
        case .veryHigh:
            return [RiskWindow(startHour: 8, endHour: 18, riskLevel: .veryHigh, guidance: "Very high risk. Prioritize indoor routes and pre-emptive medication plan.")]
        }
    }

    func weeklySummary(logs: [SymptomLog], pollen: [PollenData]) -> String {
        let symptomAvg = logs.isEmpty ? 0 : logs.map { Double($0.overallSeverity) }.reduce(0,+) / Double(logs.count)
        let pollenAvg = pollen.isEmpty ? 0 : pollen.map { max($0.treePollen, max($0.grassPollen, $0.weedPollen)) }.reduce(0,+) / Double(max(1,pollen.count))
        return "7-day summary: Avg symptom severity \(String(format: "%.1f", symptomAvg))/5. Avg peak pollen \(String(format: "%.0f", pollenAvg))."
    }
}

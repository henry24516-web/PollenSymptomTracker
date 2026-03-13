import Foundation

/// Represents a symptom log entry
struct SymptomLog: Codable, Identifiable {
    let id: UUID
    let date: Date
    let symptoms: [Symptom]
    let notes: String
    let overallSeverity: Int // 1-5 scale
    
    init(id: UUID = UUID(), date: Date = Date(), symptoms: [Symptom], notes: String = "", overallSeverity: Int) {
        self.id = id
        self.date = date
        self.symptoms = symptoms
        self.notes = notes
        self.overallSeverity = min(5, max(1, overallSeverity))
    }
}

/// Predefined symptom types
enum Symptom: String, Codable, CaseIterable, Identifiable {
    case runnyNose = "Runny Nose"
    case sneezing = "Sneezing"
    case itchyEyes = "Itchy Eyes"
    case nasalCongestion = "Nasal Congestion"
    case headache = "Headache"
    case fatigue = "Fatigue"
    case soreThroat = "Sore Throat"
    case coughing = "Coughing"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .runnyNose: return "drop.fill"
        case .sneezing: return "wind"
        case .itchyEyes: return "eye.fill"
        case .nasalCongestion: return "bandage.fill"
        case .headache: return "brain.head.profile"
        case .fatigue: return "battery.25"
        case .soreThroat: return "cross.case.fill"
        case .coughing: return "lungs.fill"
        }
    }
}

/// Severity level for individual symptoms
enum SymptomSeverity: Int, Codable, CaseIterable {
    case none = 0
    case mild = 1
    case moderate = 2
    case severe = 3
    case verySevere = 4
    
    var description: String {
        switch self {
        case .none: return "None"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        case .verySevere: return "Very Severe"
        }
    }
}

/// Individual symptom with severity
struct SymptomEntry: Codable, Identifiable {
    let id: UUID
    let symptom: Symptom
    var severity: SymptomSeverity
    
    init(id: UUID = UUID(), symptom: Symptom, severity: SymptomSeverity) {
        self.id = id
        self.symptom = symptom
        self.severity = severity
    }
}

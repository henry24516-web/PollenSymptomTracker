import Foundation
import SwiftUI

/// ViewModel for symptom logging
@MainActor
class SymptomLogViewModel: ObservableObject {
    @Published var symptomLogs: [SymptomLog] = []
    @Published var todayLog: SymptomLog?
    @Published var isLoading = false
    @Published var canLogMore: Bool = true
    @Published var monthlyLogCount: Int = 0
    @Published var nearLimitWarning: Bool = false
    
    private let storage = StorageService.shared
    private let freeLimit = 10 // Free tier limit per month
    
    init() {
        loadLogs()
    }
    
    /// Load all symptom logs from storage
    func loadLogs() {
        symptomLogs = storage.loadSymptomLogs()
        
        // Check if user has logged today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        todayLog = symptomLogs.first { calendar.isDate($0.date, inSameDayAs: today) }
        
        // Check if free tier limit reached
        checkLimit()
    }
    
    /// Add a new symptom log
    func addLog(symptoms: [SymptomEntry], notes: String, severity: Int) {
        let newLog = SymptomLog(
            symptoms: symptoms.map { Symptom(rawValue: $0.symptom.rawValue) ?? .fatigue },
            notes: notes,
            overallSeverity: severity
        )
        
        storage.addSymptomLog(newLog)
        loadLogs()
    }
    
    /// Get logs for trend chart
    func getLogsForTrend(days: Int) -> [SymptomLog] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        
        return symptomLogs
            .filter { $0.date >= startDate }
            .sorted { $0.date < $1.date }
    }
    
    /// Get logs within a date range
    func getLogs(from startDate: Date, to endDate: Date) -> [SymptomLog] {
        return storage.getSymptomLogs(from: startDate, to: endDate)
    }
    
    /// Check if user can log more symptoms (free tier limit)
    private func checkLimit() {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        
        let thisMonthLogs = symptomLogs.filter { $0.date >= startOfMonth }
        monthlyLogCount = thisMonthLogs.count
        canLogMore = monthlyLogCount < freeLimit
        nearLimitWarning = monthlyLogCount >= max(1, freeLimit - 2) && canLogMore
    }
    
    func deleteLog(id: UUID) {
        storage.deleteSymptomLog(id: id)
        loadLogs()
    }

    /// Get average severity for a specific symptom
    func getAverageSeverity(for symptom: Symptom, days: Int) -> Double {
        let logs = getLogsForTrend(days: days)
        let entries = logs.flatMap { $0.symptoms }
        
        let relevantEntries = entries.filter { $0.symptom == symptom }
        
        guard !relevantEntries.isEmpty else { return 0 }
        
        let totalSeverity = relevantEntries.reduce(0) { $0 + $1.severity.rawValue }
        return Double(totalSeverity) / Double(relevantEntries.count)
    }
    
    /// Get symptom frequency (how often each symptom appears)
    func getSymptomFrequency(days: Int) -> [Symptom: Int] {
        let logs = getLogsForTrend(days: days)
        var frequency: [Symptom: Int] = [:]
        
        for log in logs {
            for symptom in log.symptoms {
                frequency[symptom, default: 0] += 1
            }
        }
        
        return frequency
    }
}

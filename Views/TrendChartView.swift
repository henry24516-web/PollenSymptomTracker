import SwiftUI
import Charts

/// View displaying symptom and pollen trend charts
struct TrendChartView: View {
    @EnvironmentObject var pollenViewModel: PollenViewModel
    @EnvironmentObject var symptomLogViewModel: SymptomLogViewModel
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    
    @State private var selectedRange: TrendRange = .week
    
    enum TrendRange: String, CaseIterable {
        case week = "7 Days"
        case twoWeeks = "14 Days"
        case month = "30 Days"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .twoWeeks: return 14
            case .month: return 30
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Range selector
                    rangeSelector
                    
                    // Premium check for 14+ days
                    if selectedRange != .week && !subscriptionViewModel.isPremium {
                        premiumGate
                    } else {
                        // Symptom trend chart
                        symptomChart
                        
                        // Pollen overlay chart
                        pollenChart
                        
                        // Insights
                        insightsSection

                        riskWindowsSection

                        weeklySummarySection
                    }
                }
                .padding()
            }
            .navigationTitle("Trends")
        }
    }
    
    // MARK: - Range Selector
    
    private var rangeSelector: some View {
        Picker("Range", selection: $selectedRange) {
            ForEach(TrendRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Premium Gate
    
    private var premiumGate: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundColor(.yellow)
            
            Text("Premium Feature")
                .font(.headline)
            
            Text("Upgrade to view trends beyond 7 days")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Upgrade Now") {
                subscriptionViewModel.showPaywall = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Symptom Chart
    
    private var symptomChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Symptom Severity")
                .font(.headline)
            
            let logs = symptomLogViewModel.getLogsForTrend(days: selectedRange.days)
            
            if logs.isEmpty {
                emptyChartPlaceholder("No symptom data")
            } else {
                Chart(logs) { log in
                    LineMark(
                        x: .value("Date", log.date),
                        y: .value("Severity", log.overallSeverity)
                    )
                    .foregroundStyle(Color.green)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", log.date),
                        y: .value("Severity", log.overallSeverity)
                    )
                    .foregroundStyle(Color.green)
                }
                .chartYScale(domain: 0...5)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 1, 2, 3, 4, 5]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Pollen Chart
    
    private var pollenChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pollen Levels")
                .font(.headline)
            
            if pollenViewModel.historicalPollen.isEmpty {
                emptyChartPlaceholder("No pollen data")
            } else {
                Chart {
                    ForEach(pollenViewModel.historicalPollen) { data in
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value("Tree", data.treePollen)
                        )
                        .foregroundStyle(Color.green)
                        .symbol(Circle())
                        
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value("Grass", data.grassPollen)
                        )
                        .foregroundStyle(Color.yellow)
                        .symbol(Circle())
                        
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value("Weed", data.weedPollen)
                        )
                        .foregroundStyle(Color.orange)
                        .symbol(Circle())
                    }
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day().month())
                    }
                }
                .frame(height: 200)
                
                // Legend
                HStack(spacing: 20) {
                    legendItem(color: .green, label: "Tree")
                    legendItem(color: .yellow, label: "Grass")
                    legendItem(color: .orange, label: "Weed")
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Insights
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)
            
            let frequency = symptomLogViewModel.getSymptomFrequency(days: selectedRange.days)
            let sortedSymptoms = frequency.sorted { $0.value > $1.value }
            
            if sortedSymptoms.isEmpty {
                Text("Log symptoms to see insights")
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(sortedSymptoms.prefix(3)), id: \.key) { symptom, count in
                    HStack {
                        Image(systemName: symptom.icon)
                            .foregroundColor(.green)
                        
                        Text(symptom.rawValue)
                        
                        Spacer()
                        
                        Text("\(count) times")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var riskWindowsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk Windows")
                .font(.headline)

            if let current = pollenViewModel.currentPollen {
                let windows = RiskInsightService.shared.riskWindows(current: current)
                ForEach(windows) { window in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(window.startHour):00–\(window.endHour):00 · \(window.riskLevel.rawValue)")
                            .font(.subheadline.weight(.semibold))
                        Text(window.guidance)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            } else {
                Text("Load pollen data to view risk windows")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var weeklySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Summary")
                .font(.headline)

            Text(
                RiskInsightService.shared.weeklySummary(
                    logs: symptomLogViewModel.getLogsForTrend(days: 7),
                    pollen: pollenViewModel.historicalPollen
                )
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Helpers
    
    private func emptyChartPlaceholder(_ message: String) -> some View {
        VStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(message)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }
}

#Preview {
    TrendChartView()
        .environmentObject(PollenViewModel())
        .environmentObject(SymptomLogViewModel())
        .environmentObject(SubscriptionViewModel())
}

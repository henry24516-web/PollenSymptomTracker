import SwiftUI

/// View for logging daily symptoms
struct SymptomLogView: View {
    @EnvironmentObject var symptomLogViewModel: SymptomLogViewModel
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    
    @State private var showingLogSheet = false
    @State private var selectedSymptoms: [SymptomEntry] = []
    @State private var notes = ""
    @State private var overallSeverity: Int = 3
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Premium prompt if limit reached
                if !subscriptionViewModel.isPremium && !symptomLogViewModel.canLogMore {
                    premiumPrompt
                }
                
                if symptomLogViewModel.nearLimitWarning && !subscriptionViewModel.isPremium {
                    nearLimitBanner
                }

                // Today's log status
                todayStatus
                
                // Log history
                logHistory
            }
            .navigationTitle("Symptoms")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingLogSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(!subscriptionViewModel.isPremium && !symptomLogViewModel.canLogMore)
                }
            }
            .sheet(isPresented: $showingLogSheet) {
                logEntrySheet
            }
        }
    }
    
    // MARK: - Premium Prompt
    
    private var premiumPrompt: some View {
        Button {
            subscriptionViewModel.showPaywall = true
        } label: {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                Text("Free limit reached. Upgrade for unlimited logging!")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemYellow).opacity(0.2))
        }
    }
    
    private var nearLimitBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("You have used \(symptomLogViewModel.monthlyLogCount)/10 free logs this month")
                .font(.caption)
            Spacer()
            Button("Upgrade") { subscriptionViewModel.showPaywall = true }
                .font(.caption.weight(.semibold))
        }
        .padding(10)
        .background(Color.orange.opacity(0.15))
    }

    // MARK: - Today's Status
    
    private var todayStatus: some View {
        VStack(spacing: 8) {
            if let todayLog = symptomLogViewModel.todayLog {
                // Already logged today
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Logged today")
                        .font(.headline)
                    Spacer()
                }
                
                HStack {
                    Text("Severity: \(todayLog.overallSeverity)/5")
                        .font(.subheadline)
                    Spacer()
                }
                
                if !todayLog.symptoms.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(todayLog.symptoms, id: \.self) { symptom in
                                Text(symptom.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            } else {
                // Not logged today
                HStack {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                    Text("No symptoms logged today")
                        .font(.headline)
                    Spacer()
                    
                    Button("Log Now") {
                        showingLogSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Log History
    
    private var logHistory: some View {
        List {
            if symptomLogViewModel.symptomLogs.isEmpty {
                ContentUnavailableView(
                    "No Symptoms Logged",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Start tracking your symptoms to see patterns")
                )
            } else {
                ForEach(symptomLogViewModel.symptomLogs.sorted(by: { $0.date > $1.date })) { log in
                    SymptomLogRow(log: log)
                }
                .onDelete { indexSet in
                    let sorted = symptomLogViewModel.symptomLogs.sorted(by: { $0.date > $1.date })
                    for index in indexSet {
                        symptomLogViewModel.deleteLog(id: sorted[index].id)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Log Entry Sheet
    
    private var logEntrySheet: some View {
        NavigationStack {
            Form {
                Section("How are you feeling?") {
                    ForEach(Symptom.allCases) { symptom in
                        HStack {
                            Image(systemName: symptom.icon)
                                .foregroundColor(.green)
                            Text(symptom.rawValue)
                            Spacer()
                            
                            Picker("Severity", selection: bindingFor(symptom)) {
                                Text("None").tag(SymptomSeverity.none)
                                Text("Mild").tag(SymptomSeverity.mild)
                                Text("Moderate").tag(SymptomSeverity.moderate)
                                Text("Severe").tag(SymptomSeverity.severe)
                                Text("Very Severe").tag(SymptomSeverity.verySevere)
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                
                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
                
                Section("Overall Severity") {
                    Slider(value: Binding(
                        get: { Double(overallSeverity) },
                        set: { overallSeverity = Int($0) }
                    ), in: 1...5, step: 1) {
                        Text("Severity")
                    }
                    .tint(.green)
                    
                    Text(severityText(overallSeverity))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Log Symptoms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingLogSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveLog()
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func bindingFor(_ symptom: Symptom) -> Binding<SymptomSeverity> {
        let entry = selectedSymptoms.first { $0.symptom == symptom }
        let initialSeverity = entry?.severity ?? .none
        
        return Binding(
            get: { selectedSymptoms.first { $0.symptom == symptom }?.severity ?? .none },
            set: { newValue in
                if let index = selectedSymptoms.firstIndex(where: { $0.symptom == symptom }) {
                    if newValue == .none {
                        selectedSymptoms.remove(at: index)
                    } else {
                        selectedSymptoms[index] = SymptomEntry(symptom: symptom, severity: newValue)
                    }
                } else if newValue != .none {
                    selectedSymptoms.append(SymptomEntry(symptom: symptom, severity: newValue))
                }
            }
        )
    }
    
    private func severityText(_ value: Int) -> String {
        switch value {
        case 1: return "Minimal symptoms"
        case 2: return "Mild discomfort"
        case 3: return "Moderate symptoms"
        case 4: return "Significant discomfort"
        case 5: return "Severe symptoms"
        default: return ""
        }
    }
    
    private func saveLog() {
        symptomLogViewModel.addLog(
            symptoms: selectedSymptoms,
            notes: notes,
            severity: overallSeverity
        )
        showingLogSheet = false
        
        // Reset form
        selectedSymptoms = []
        notes = ""
        overallSeverity = 3
    }
}

/// Row view for symptom log entry
struct SymptomLogRow: View {
    let log: SymptomLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(log.date, style: .date)
                    .font(.headline)
                
                Spacer()
                
                severityBadge
            }
            
            if !log.symptoms.isEmpty {
                Text(log.symptoms.map { $0.rawValue }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            if !log.notes.isEmpty {
                Text(log.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var severityBadge: some View {
        Text("\(log.overallSeverity)/5")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(severityColor(log.overallSeverity).opacity(0.2))
            .cornerRadius(8)
    }
    
    private func severityColor(_ severity: Int) -> Color {
        switch severity {
        case 1...2: return .green
        case 3: return .yellow
        case 4...5: return .red
        default: return .gray
        }
    }
}

#Preview {
    SymptomLogView()
        .environmentObject(SymptomLogViewModel())
        .environmentObject(SubscriptionViewModel())
}

import SwiftUI

/// View displaying current pollen levels
struct PollenView: View {
    @EnvironmentObject var pollenViewModel: PollenViewModel
    @State private var showTrustInfo = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    locationSearch
                    pollenHeader
                    pollenBreakdown
                    recommendationCard
                    locationInfo
                }
                .padding()
            }
            .navigationTitle("Pollen")
            .refreshable {
                await pollenViewModel.fetchCurrentPollen()
            }
            .task {
                if pollenViewModel.currentPollen == nil {
                    await pollenViewModel.fetchCurrentPollen()
                }
            }
        }
    }

    private var locationSearch: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search area (e.g. Camden, London)", text: $pollenViewModel.locationQuery)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .onChange(of: pollenViewModel.locationQuery) { _ in
                        Task { await pollenViewModel.searchLocations() }
                    }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)

            if pollenViewModel.isSearchingLocations {
                ProgressView("Finding areas...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !pollenViewModel.locationSuggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(pollenViewModel.locationSuggestions.prefix(5)) { suggestion in
                        Button {
                            pollenViewModel.selectLocation(suggestion)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.name)
                                        .foregroundColor(.primary)
                                    Text("\(String(format: "%.4f", suggestion.latitude)), \(String(format: "%.4f", suggestion.longitude))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                        }
                        .buttonStyle(.plain)

                        if suggestion.id != pollenViewModel.locationSuggestions.prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
            }
        }
    }

    private var pollenHeader: some View {
        VStack(spacing: 12) {
            if pollenViewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let pollen = pollenViewModel.currentPollen {
                ZStack {
                    Circle()
                        .fill(pollenLevelColor(pollen.overallLevel))
                        .frame(width: 120, height: 120)

                    VStack {
                        Image(systemName: pollen.overallLevel.icon)
                            .font(.system(size: 40))
                            .foregroundColor(.white)

                        Text(pollen.overallLevel.rawValue)
                            .font(.headline)
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                    }
                }
                .transition(.scale.combined(with: .opacity))

                Text("Overall Pollen Level")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Unable to load pollen data")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var pollenBreakdown: some View {
        VStack(spacing: 16) {
            Text("Pollen Breakdown")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                pollenCard(
                    title: "Tree",
                    value: pollenViewModel.currentPollen?.treePollen ?? 0,
                    icon: "tree.fill",
                    color: .green
                )

                pollenCard(
                    title: "Grass",
                    value: pollenViewModel.currentPollen?.grassPollen ?? 0,
                    icon: "leaf.fill",
                    color: .yellow
                )

                pollenCard(
                    title: "Weed",
                    value: pollenViewModel.currentPollen?.weedPollen ?? 0,
                    icon: "camera.macro",
                    color: .orange
                )
            }
        }
    }

    private func pollenCard(title: String, value: Double, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(String(format: "%.0f", value))
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var recommendationCard: some View {
        let level = pollenViewModel.currentPollen?.overallLevel ?? .moderate

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("What to do today")
                    .font(.headline)
                Spacer()
            }

            Text(primaryAction(for: level))
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(secondaryAction(for: level))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.25), value: level)
    }

    private var locationInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.green)

                Text(pollenViewModel.location.name)
                    .font(.subheadline)

                Spacer()

                Button {
                    showTrustInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            if pollenViewModel.currentPollen?.isFallback == true {
                Label("Using fallback data path", systemImage: "shield.lefthalf.filled")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }

            Divider()

            Label("Data source: \(pollenViewModel.currentPollen?.dataSource ?? "Unknown")", systemImage: "externaldrive.badge.checkmark")
                .font(.caption)
                .foregroundColor(.secondary)

            Label("Confidence: \(pollenViewModel.currentPollen?.confidence.rawValue ?? "Unknown")", systemImage: "checkmark.shield")
                .font(.caption2)
                .foregroundColor(.secondary)

            Label("Updated: \(Date.now.formatted(date: .abbreviated, time: .shortened))", systemImage: "clock")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showTrustInfo) {
            trustInfoSheet
        }
    }

    private var trustInfoSheet: some View {
        NavigationStack {
            List {
                Section("How to read data trust") {
                    Text("Source shows where the pollen values came from (live provider, backup, cache, or local model).")
                    Text("Confidence is high for primary provider responses, medium for backup/cache, and low for local fallback model data.")
                    Text("If fallback data is shown, the app is still usable while external data sources recover.")
                }
            }
            .navigationTitle("Data Trust")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func primaryAction(for level: PollenLevel) -> String {
        switch level {
        case .low:
            return "Low risk: ideal day for outdoor plans."
        case .moderate:
            return "Moderate risk: keep antihistamines handy outdoors."
        case .high:
            return "High risk: reduce exposure 11:00–16:00 and wear sunglasses."
        case .veryHigh:
            return "Very high risk: prioritize indoor time and mask outdoors."
        }
    }

    private func secondaryAction(for level: PollenLevel) -> String {
        switch level {
        case .low:
            return "Log symptoms tonight to improve personal forecasts."
        case .moderate:
            return "Shower after being outside and track evening symptoms."
        case .high:
            return "Close windows in peak hours and log response to medication."
        case .veryHigh:
            return "Set high-alert notifications and avoid parks/grass-heavy routes."
        }
    }

    private func pollenLevelColor(_ level: PollenLevel) -> Color {
        switch level {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .veryHigh: return .red
        }
    }
}

#Preview {
    PollenView()
        .environmentObject(PollenViewModel())
}

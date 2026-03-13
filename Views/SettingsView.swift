//
//  SettingsView.swift
//  PollenSymptomTracker
//  Settings screen with notification controls and subscription management
//

import SwiftUI

/// Settings view for app configuration
struct SettingsView: View {
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var authService = AuthService.shared
    
    @State private var dailyReminderEnabled = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!
    @State private var highPollenAlertsEnabled = true
    @State private var showSubscriptionSheet = false
    @State private var showClearDataAlert = false
    @State private var showExportSheet = false
    
    var body: some View {
        NavigationStack {
            Form {
                authSection

                // Subscription Section
                subscriptionSection
                
                // Notifications Section
                notificationsSection

                reliabilitySection
                
                // Data Section
                dataSection
                
                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .onAppear {
                loadNotificationPreferences()
            }
            .sheet(isPresented: $showSubscriptionSheet) {
                PaywallView()
            }
            .alert("Clear All Data?", isPresented: $showClearDataAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will delete all your symptom logs and reset the app. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Auth Section

    private var authSection: some View {
        Section {
            HStack {
                Label("Sign-In", systemImage: "person.crop.circle")
                Spacer()
                Text(authService.provider)
                    .foregroundColor(.secondary)
            }

            if authService.isSignedIn {
                Button(role: .destructive) {
                    authService.signOut()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } else {
                Button {
                    authService.signInWithApple()
                } label: {
                    Label("Continue with Apple", systemImage: "apple.logo")
                }

                #if canImport(GoogleSignIn)
                Button {
                    authService.signInWithGoogle()
                } label: {
                    Label("Continue with Google", systemImage: "globe")
                }
                #endif
            }
        } header: {
            Text("Account")
        }
    }

    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        Section {
            // Current status
            HStack {
                Label("Subscription Status", systemImage: "crown.fill")
                Spacer()
                Text(subscriptionViewModel.statusText)
                    .foregroundColor(subscriptionViewModel.isPremium ? .green : .secondary)
            }
            
            // Expiration date (if premium)
            if subscriptionViewModel.isPremium {
                HStack {
                    Label("Expires", systemImage: "calendar")
                    Spacer()
                    Text(subscriptionViewModel.expirationDateFormatted)
                        .foregroundColor(.secondary)
                }
            }
            
            // Upgrade/Manage button
            Button {
                showSubscriptionSheet = true
            } label: {
                HStack {
                    if subscriptionViewModel.isPremium {
                        Text("Manage Subscription")
                    } else {
                        Text("Upgrade to Premium")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)
        } header: {
            Text("Subscription")
        } footer: {
            if !subscriptionViewModel.isPremium {
                Text("Premium unlocks unlimited logging, trend charts, and export features.")
            }
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        Section {
            // Permission status
            HStack {
                Label("Notification Permission", systemImage: "bell.fill")
                Spacer()
                Text(notificationService.isAuthorized ? "Enabled" : "Disabled")
                    .foregroundColor(notificationService.isAuthorized ? .green : .red)
            }
            
            // Open settings button
            if !notificationService.isAuthorized {
                Button {
                    notificationService.openSettings()
                } label: {
                    HStack {
                        Text("Enable Notifications")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Daily reminder toggle
            Toggle(isOn: $dailyReminderEnabled) {
                Label("Daily Reminder", systemImage: "clock.fill")
            }
            .onChange(of: dailyReminderEnabled) { newValue in
                if newValue && !notificationService.isAuthorized {
                    Task {
                        let granted = await notificationService.requestAuthorization()
                        if !granted {
                            dailyReminderEnabled = false
                        }
                    }
                }
                saveNotificationPreferences()
            }
            
            // Reminder time
            if dailyReminderEnabled {
                DatePicker(
                    "Reminder Time",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .onChange(of: reminderTime) { _ in
                    saveNotificationPreferences()
                }
            }
            
            // High pollen alerts
            Toggle(isOn: $highPollenAlertsEnabled) {
                Label("High Pollen Alerts", systemImage: "exclamationmark.triangle.fill")
            }
            .onChange(of: highPollenAlertsEnabled) { _ in
                saveNotificationPreferences()
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Daily reminders help you build consistent tracking habits.")
        }
    }
    
    // MARK: - Reliability Section

    private var reliabilitySection: some View {
        Section {
            let stats = TelemetryService.shared.fallbackStats()
            HStack {
                Text("Primary API hits")
                Spacer()
                Text("\(stats[.primary] ?? 0)")
                    .foregroundColor(.secondary)
            }
            HStack {
                Text("Backup API hits")
                Spacer()
                Text("\(stats[.backup] ?? 0)")
                    .foregroundColor(.secondary)
            }
            HStack {
                Text("Cache fallback hits")
                Spacer()
                Text("\(stats[.cache] ?? 0)")
                    .foregroundColor(.secondary)
            }
            HStack {
                Text("Model fallback hits")
                Spacer()
                Text("\(stats[.localModel] ?? 0)")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Reliability")
        } footer: {
            Text("Tracks fallback path usage so we can monitor resilience in production.")
        }
    }

    // MARK: - Data Section
    
    private var dataSection: some View {
        Section {
            // Symptom logs count
            HStack {
                Label("Symptom Logs", systemImage: "list.bullet.clipboard")
                Spacer()
                Text("\(StorageService.shared.loadSymptomLogs().count)")
                    .foregroundColor(.secondary)
            }
            
            // Export data
            Button {
                exportData()
            } label: {
                Label("Export My Data", systemImage: "square.and.arrow.up")
            }
            
            // Clear data
            Button(role: .destructive) {
                showClearDataAlert = true
            } label: {
                Label("Clear All Data", systemImage: "trash")
            }

            Button(role: .destructive) {
                clearAllData()
                authService.signOut()
            } label: {
                Label("Delete Account Data", systemImage: "person.crop.circle.badge.xmark")
            }
        } header: {
            Text("Data")
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundColor(.secondary)
            }
            
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                HStack {
                    Text("Privacy Policy")
                    Spacer()
                }
            }
            .foregroundColor(.primary)

            NavigationLink {
                TermsView()
            } label: {
                HStack {
                    Text("Terms of Service")
                    Spacer()
                }
            }
            .foregroundColor(.primary)
        } header: {
            Text("About")
        }
    }
    
    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Helpers
    
    private func loadNotificationPreferences() {
        let prefs = StorageService.shared.loadNotificationPreferences()
        dailyReminderEnabled = prefs.dailyReminderEnabled
        reminderTime = prefs.reminderTime ?? Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!
        highPollenAlertsEnabled = prefs.highPollenAlertsEnabled
    }
    
    private func saveNotificationPreferences() {
        let prefs = NotificationPreferences(
            dailyReminderEnabled: dailyReminderEnabled,
            reminderTime: dailyReminderEnabled ? reminderTime : nil,
            highPollenAlertsEnabled: highPollenAlertsEnabled
        )
        
        StorageService.shared.saveNotificationPreferences(prefs)
        
        // Schedule/cancel notification
        Task {
            if dailyReminderEnabled {
                await notificationService.scheduleDailyReminder(time: reminderTime)
            } else {
                await notificationService.cancelDailyReminder()
            }
        }
    }
    
    private func exportData() {
        if let data = StorageService.shared.exportData(),
           let jsonString = String(data: data, encoding: .utf8) {
            // In a real app, this would present a share sheet
            print("Exported data: \(jsonString.prefix(200))...")
        }
    }
    
    private func clearAllData() {
        StorageService.shared.clearAllData()
        NotificationService.shared.clearAllNotifications()
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(SubscriptionViewModel())
}

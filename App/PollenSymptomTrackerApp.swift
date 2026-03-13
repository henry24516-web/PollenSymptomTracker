//
//  PollenSymptomTrackerApp.swift
//  PollenSymptomTracker
//  Main app entry point
//

import SwiftUI

@main
struct PollenSymptomTrackerApp: App {
    @StateObject private var pollenViewModel = PollenViewModel()
    @StateObject private var symptomLogViewModel = SymptomLogViewModel()
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    @StateObject private var paymentService = PaymentService()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView(isOnboardingComplete: $hasCompletedOnboarding)
                }
            }
            .environmentObject(pollenViewModel)
            .environmentObject(symptomLogViewModel)
            .environmentObject(subscriptionViewModel)
            .environmentObject(paymentService)
            .task {
                subscriptionViewModel.setPaymentService(paymentService)
                // Initialize services on app launch
                await initializeServices()
            }
        }
    }
    
    private func initializeServices() async {
        // Check and refresh subscription status
        subscriptionViewModel.checkSubscriptionStatus()
        
        // Request notification authorization if enabled
        let prefs = StorageService.shared.loadNotificationPreferences()
        if prefs.dailyReminderEnabled {
            let notificationService = NotificationService.shared
            await notificationService.checkAuthorizationStatus()
            if notificationService.isAuthorized {
                await notificationService.scheduleDailyReminder(time: prefs.reminderTime)
            }
        }
    }
}

// MARK: - Main Tab View

/// Main tab-based navigation
struct MainTabView: View {
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PollenView()
                .tabItem {
                    Label("Pollen", systemImage: "leaf.fill")
                }
                .tag(0)
            
            SymptomLogView()
                .tabItem {
                    Label("Log", systemImage: "list.bullet.clipboard")
                }
                .tag(1)
            
            TrendChartView()
                .tabItem {
                    Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.green)
    }
}

#Preview {
    MainTabView()
        .environmentObject(PollenViewModel())
        .environmentObject(SymptomLogViewModel())
        .environmentObject(SubscriptionViewModel())
}

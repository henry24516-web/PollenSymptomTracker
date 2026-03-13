//
//  OnboardingView.swift
//  PollenSymptomTracker
//  Premium onboarding with auth options and reminder setup
//

import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    @Binding var isOnboardingComplete: Bool

    @State private var currentPage = 0
    @State private var enableNotifications = false
    @State private var selectedReminderTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!
    @State private var showNotificationPermissionAlert = false
    @State private var selectedAuth: AuthProvider?

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Know Your Trigger Windows",
            description: "Get area-level pollen forecasts and avoid peak exposure times before symptoms hit.",
            systemImage: "wind",
            accentColor: .mint
        ),
        OnboardingPage(
            title: "Track Symptoms in 10 Seconds",
            description: "Log sneezing, eyes, congestion and sleep daily to discover your personal trigger profile.",
            systemImage: "checklist",
            accentColor: .teal
        ),
        OnboardingPage(
            title: "Get Personal Insights",
            description: "Understand correlations between pollen spikes and your symptom trends over time.",
            systemImage: "chart.line.uptrend.xyaxis",
            accentColor: .blue
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }

                authPage
                    .tag(pages.count)

                settingsPage
                    .tag(pages.count + 1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    ForEach(0..<(pages.count + 2), id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: index == currentPage ? 20 : 8, height: 8)
                    }
                }

                HStack(spacing: 16) {
                    if currentPage < pages.count + 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .foregroundColor(.secondary)
                    }

                    Button(action: nextAction) {
                        Text(currentPage == pages.count + 1 ? "Get Started" : "Next")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .alert("Enable Notifications", isPresented: $showNotificationPermissionAlert) {
            Button("Enable") { requestNotificationPermission() }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("Enable notifications to receive daily symptom reminders and high pollen alerts.")
        }
    }

    private var authPage: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 64))
                .foregroundColor(.indigo)

            Text("Secure your progress")
                .font(.title2.bold())

            Text("Sign in to sync your data and keep your logs safe across devices.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                AuthService.shared.handleAppleSignIn(result)
                if case .success = result {
                    selectedAuth = .apple
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .cornerRadius(12)
            .padding(.horizontal)

            #if canImport(GoogleSignIn)
            Button {
                selectedAuth = .google
                AuthService.shared.signInWithGoogle()
            } label: {
                HStack(spacing: 10) {
                    Text("G")
                        .font(.headline.weight(.bold))
                        .frame(width: 28, height: 28)
                        .background(Color.white)
                        .clipShape(Circle())
                    Text("Continue with Google")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(red: 66/255, green: 133/255, blue: 244/255))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            #else
            Label("Google Sign-In available in next update", systemImage: "hourglass")
                .font(.footnote)
                .foregroundColor(.secondary)
            #endif

            if let selectedAuth {
                Label("Selected: \(selectedAuth.rawValue)", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.footnote)
            }

            if let authError = AuthService.shared.authErrorMessage {
                Text(authError)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Text("Apple Sign In is wired to native UI. Google Sign-In is shown only when SDK is integrated.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer()
        }
        .padding(.top, 30)
    }

    private var settingsPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "gearshape.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text("Personalize Your Experience")
                .font(.title2)
                .fontWeight(.bold)

            Text("Configure your reminders and alerts to get the most out of Pollen Tracker")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 16) {
                Toggle(isOn: $enableNotifications) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Reminders")
                            .font(.headline)
                        Text("Get reminded to log your symptoms")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)

                if enableNotifications {
                    DatePicker("Reminder Time", selection: $selectedReminderTime, displayedComponents: .hourAndMinute)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 40)
    }

    private func nextAction() {
        if currentPage < pages.count + 1 {
            withAnimation { currentPage += 1 }
        } else {
            if enableNotifications {
                showNotificationPermissionAlert = true
            } else {
                completeOnboarding()
            }
        }
    }

    private func requestNotificationPermission() {
        Task {
            let notificationService = NotificationService.shared
            let granted = await notificationService.requestAuthorization()

            if granted {
                notificationService.savePreferences(
                    dailyReminderEnabled: true,
                    reminderTime: selectedReminderTime,
                    highPollenAlerts: true
                )
            }

            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        if !enableNotifications {
            NotificationService.shared.savePreferences(
                dailyReminderEnabled: false,
                reminderTime: nil,
                highPollenAlerts: true
            )
        }

        StorageService.shared.completeOnboarding()
        isOnboardingComplete = true
    }
}

enum AuthProvider: String {
    case apple = "Apple"
    case google = "Google"
}

struct OnboardingPage {
    let title: String
    let description: String
    let systemImage: String
    let accentColor: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: page.systemImage)
                .font(.system(size: 80))
                .foregroundColor(page.accentColor)
                .padding()

            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
        .environmentObject(SubscriptionViewModel())
}

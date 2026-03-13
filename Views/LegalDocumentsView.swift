import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Privacy Policy")
                    .font(.title2.bold())
                Text("Last updated: \(Date.now.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Group {
                    Text("Data we process")
                        .font(.headline)
                    Text("• Symptom logs and notes you enter\n• Location search input and selected coordinates\n• Notification preferences\n• Subscription status metadata")

                    Text("How data is used")
                        .font(.headline)
                    Text("Data is used for app functionality: symptom tracking, trend analytics, pollen forecasts, and reminders.")

                    Text("Third-party services")
                        .font(.headline)
                    Text("We request pollen and geocoding data from Open-Meteo APIs using coordinates/city names. We do not sell personal health data.")

                    Text("Retention and deletion")
                        .font(.headline)
                    Text("Data is stored locally on your device. You can export or delete all app data anytime in Settings.")

                    Text("Contact")
                        .font(.headline)
                    Text("For privacy requests, contact: privacy@pollenhealth.app")
                }
                .font(.body)
            }
            .padding()
        }
        .navigationTitle("Privacy")
    }
}

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Terms of Service")
                    .font(.title2.bold())

                Group {
                    Text("Pollen insights are informational and not a substitute for medical advice.")
                    Text("The app provides forecasts and symptom tracking to support allergy management.")
                    Text("Premium subscriptions auto-renew unless cancelled in Apple account settings at least 24 hours before renewal.")
                    Text("Manage and cancel subscriptions in iOS Settings > Apple ID > Subscriptions.")
                    Text("You are responsible for medication and care decisions.")
                }
                .font(.body)
            }
            .padding()
        }
        .navigationTitle("Terms")
    }
}

#Preview {
    PrivacyPolicyView()
}

import SwiftUI

/// Paywall view for subscription upgrade
struct PaywallView: View {
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    paywallHeader
                    
                    // Features list
                    featuresList
                    
                    // Pricing
                    pricingSection
                    
                    // CTA Button
                    subscribeButton
                    
                    // Restore
                    restoreButton

                    paidAppsTermsLink
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var paywallHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Upgrade to Premium")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Unlock all features and take control of your allergies")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Features
    
    private var featuresList: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(subscriptionViewModel.config.products.first?.features ?? [], id: \.self) { feature in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    
                    Text(feature)
                        .font(.body)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Pricing
    
    private var pricingSection: some View {
        VStack(spacing: 8) {
            if let product = subscriptionViewModel.config.products.first {
                Text(product.price)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("per month")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Price in different tiers (configurable)
                VStack(spacing: 4) {
                    Text("Flexible pricing: \(subscriptionViewModel.config.priceRangeMin) - \(subscriptionViewModel.config.priceRangeMax)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Pricing and offers may vary by region")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Subscribe Button
    
    private var subscribeButton: some View {
        Button {
            Task {
                await subscriptionViewModel.subscribe(to: "monthly")
            }
        } label: {
            HStack {
                if subscriptionViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Subscribe Now")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(subscriptionViewModel.isLoading)
    }
    
    // MARK: - Restore Button
    
    private var restoreButton: some View {
        Button {
            Task {
                await subscriptionViewModel.restorePurchases()
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var paidAppsTermsLink: some View {
        Group {
            if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                Link(destination: url) {
                    Text("Terms of Use (EULA)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .underline()
                }
            }
        }
        .padding(.top, 4)
    }
}

/// Configuration file for subscription (to be placed in app bundle)
struct SubscriptionConfigJSON: View {
    static let exampleConfig = """
    {
      "defaultPrice": "£2.99",
      "priceRangeMin": "£1.99",
      "priceRangeMax": "£4.99",
      "priceTierMin": 1,
      "priceTierMax": 6,
      "products": [
        {
          "id": "monthly",
          "name": "Premium Monthly",
          "price": "£299",
          "priceTier": 2,
          "features": [
            "Unlimited symptom logging",
            "Trend charts (7/14/30 days)",
            "Export data to CSV",
            "High pollen alerts",
            "Ad-free experience"
          ],
          "isAnnual": false
        }
      ]
    }
    """
    
    var body: some View {
        Text("See SubscriptionConfig.json in project")
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionViewModel())
}

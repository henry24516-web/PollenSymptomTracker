import Foundation

/// Subscription product configuration
struct SubscriptionProduct: Codable, Identifiable {
    let id: String
    let name: String
    let price: String
    let priceTier: Int // App Store price tier (0-127)
    let features: [String]
    let isAnnual: Bool
    
    /// StoreKit product ID pattern
    static let productIDPrefix = "com.pollenhealth.symptomtracker.premium"
    
    init(id: String = "monthly", name: String = "Premium", price: String = "£2.99", priceTier: Int = 2, features: [String] = [], isAnnual: Bool = false) {
        self.id = id
        self.name = name
        self.price = price
        self.priceTier = priceTier
        self.features = features
        self.isAnnual = isAnnual
    }
    
    var productID: String {
        return "\(SubscriptionProduct.productIDPrefix).\(id)"
    }
}

/// Subscription tier configuration
struct SubscriptionConfig: Codable {
    let defaultPrice: String
    let priceRangeMin: String
    let priceRangeMax: String
    let priceTierMin: Int
    let priceTierMax: Int
    let products: [SubscriptionProduct]
    
    /// Load config from bundle or use defaults
    static func load() -> SubscriptionConfig {
        // Try to load from config file
        let configPath = Bundle.main.path(forResource: "SubscriptionConfig", ofType: "json")
        
        if let path = configPath,
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let config = try? JSONDecoder().decode(SubscriptionConfig.self, from: data) {
            return config
        }
        
        // Return default configuration
        return SubscriptionConfig.default
    }
    
    static let `default` = SubscriptionConfig(
        defaultPrice: "£2.99",
        priceRangeMin: "£1.99",
        priceRangeMax: "£4.99",
        priceTierMin: 1,  // £1.99
        priceTierMax: 6,  // £4.99
        products: [
            SubscriptionProduct(
                id: "monthly",
                name: "Premium Monthly",
                price: "£2.99",
                priceTier: 2,
                features: [
                    "Unlimited symptom logging",
                    "Trend charts (7/14/30 days)",
                    "Export data to CSV",
                    "High pollen alerts",
                    "Ad-free experience"
                ],
                isAnnual: false
            )
        ]
    )
}

/// Subscription status
enum SubscriptionStatus: String, Codable {
    case free = "free"
    case premium = "premium"
    case trial = "trial"
    case expired = "expired"
}

/// User's subscription state
struct SubscriptionState: Codable {
    var status: SubscriptionStatus
    var expirationDate: Date?
    var productID: String?
    
    var isActive: Bool {
        guard status == .premium || status == .trial else { return false }
        guard let expDate = expirationDate else { return true }
        return expDate > Date()
    }
}

//
//  PaymentService.swift
//  PollenSymptomTracker
//  StoreKit 2 implementation with subscription management
//

import Foundation
import StoreKit

/// StoreKit 2 payment service for subscriptions
/// Supports: product loading, purchase flow, restore purchases, entitlement checks
/// Gracefully handles simulator/dev environment without App Store connection
@MainActor
class PaymentService: ObservableObject {
    // MARK: - Published Properties
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isStoreAvailable = false
    
    // MARK: - Configuration
    
    /// Product IDs aligned with £1.99–£4.99 pricing strategy
    /// Note: Actual pricing tier is set in App Store Connect
    private let productIDs: Set<String> = [
        "com.pollenhealth.symptomtracker.premium.monthly",
        "com.pollenhealth.symptomtracker.premium.yearly"
    ]
    
    // Only load monthly for initial release
    private var activeProductIDs: [String] {
        // In production, conditionally include yearly based on config
        ["com.pollenhealth.symptomtracker.premium.monthly"]
    }
    
    // MARK: - Private Properties
    
    private var transactionListener: Task<Void, Error>?
    private let storage = StorageService.shared
    
    // MARK: - Initialization
    
    init() {
        // Listen for transaction updates
        transactionListener = listenForTransactions()
        
        // Load products on init
        Task {
            await loadProducts()
            await updatePurchasedStatus()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Product Loading
    
    /// Load available products from App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        // Check if StoreKit is available
        guard hasStoreKitAccess() else {
            handleStoreUnavailable()
            isLoading = false
            return
        }
        
        do {
            // Request products from App Store
            let storeProducts = try await Product.products(for: Set(activeProductIDs))
            
            // Sort by price
            products = storeProducts.sorted { $0.price < $1.price }
            
            isStoreAvailable = true
            
            if products.isEmpty {
                errorMessage = "No products available. Check App Store Connect configuration."
            }
        } catch {
            // Handle StoreKit errors gracefully
            handleStoreError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase Flow
    
    /// Purchase a product
    /// - Parameter product: The Product to purchase
    /// - Returns: true if purchase successful, false otherwise
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Check store availability
        guard isStoreAvailable else {
            errorMessage = "App Store is not available. Please check your network connection."
            isLoading = false
            return false
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)
                
                // Update purchased status
                await updatePurchasedStatus()
                
                // Finish the transaction
                await transaction.finish()
                
                isLoading = false
                return true
                
            case .userCancelled:
                isLoading = false
                return false
                
            case .pending:
                isLoading = false
                errorMessage = "Purchase is pending approval. You'll be notified when it's complete."
                return false
                
            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Subscribe to a specific product ID
    /// - Parameter productID: The product ID to subscribe to
    /// - Returns: true if successful
    func subscribe(to productID: String) async -> Bool {
        // Find the product
        guard let product = products.first(where: { $0.id == productID }) else {
            // Try to find by matching suffix
            guard let product = products.first(where: { $0.id.hasSuffix(productID) }) else {
                errorMessage = "Product not found: \(productID)"
                return false
            }
            return await purchase(product)
        }
        
        return await purchase(product)
    }
    
    // MARK: - Restore Purchases
    
    /// Restore previous purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        guard isStoreAvailable else {
            errorMessage = "App Store is not available. Cannot restore purchases."
            isLoading = false
            return
        }
        
        do {
            // Iterate through all current entitlements
            for await result in Transaction.currentEntitlements {
                do {
                    let transaction = try checkVerified(result)
                    await updatePurchasedStatus()
                    await transaction.finish()
                } catch {
                    print("Failed to verify transaction: \(error)")
                }
            }
            
            // Also check for non-renewing subscriptions
            await updatePurchasedStatus()
            
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Entitlement Checks
    
    /// Check if user has premium access
    var isPremium: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    /// Check if a specific product is purchased
    func isPurchased(_ productID: String) -> Bool {
        purchasedProductIDs.contains(productID)
    }
    
    /// Get the current subscription product if any
    var currentSubscription: Product? {
        guard let productID = purchasedProductIDs.first else { return nil }
        return products.first { $0.id == productID }
    }
    
    // MARK: - Transaction Updates
    
    /// Listen for transaction updates from App Store
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    /// Update purchased product IDs from App Store
    private func updatePurchasedStatus() async {
        var purchased = Set<String>()
        
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }
        
        purchasedProductIDs = purchased
    }
    
    // MARK: - Verification
    
    /// Verify StoreKit result
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PaymentError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Store Availability
    
    /// Check if StoreKit is accessible
    private func hasStoreKitAccess() -> Bool {
        // In simulator, StoreKit may not be fully available
        #if targetEnvironment(simulator)
        // Check if we can reach the store
        return true // Allow simulator to attempt StoreKit calls
        #else
        return true
        #endif
    }
    
    /// Handle unavailable store
    private func handleStoreUnavailable() {
        isStoreAvailable = false
        products = []
        
        // In development, provide helpful message
        #if targetEnvironment(simulator)
        errorMessage = "App Store is not available in the simulator. StoreKit operations will not work. Use TestFlight or a real device for testing."
        #else
        errorMessage = "Unable to connect to App Store. Please check your internet connection and try again."
        #endif
    }
    
    /// Handle store errors
    private func handleStoreError(_ error: Error) {
        isStoreAvailable = false
        
        // Check for specific error types
        if let storeError = error as? StoreKitError {
            switch storeError {
            case .notAvailableInStorefront:
                errorMessage = "Products not available in your region."
            case .notAvailableForDevice:
                errorMessage = "Products not available on this device."
            case .paymentNotAllowed:
                errorMessage = "In-app purchases are not allowed. Check device restrictions."
            default:
                errorMessage = "Store error: \(storeError.localizedDescription)"
            }
        } else {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Sandbox Testing
    
    /// Check if running in sandbox environment
    var isSandbox: Bool {
        // StoreKit 2 doesn't expose this directly, but we can infer from environment
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    /// Get a message for sandbox testing
    var sandboxMessage: String? {
        #if targetEnvironment(simulator)
        return "Running in Simulator - StoreKit purchases will not work. Test with TestFlight on a real device."
        #else
        return nil
        #endif
    }
}

// MARK: - Errors

enum PaymentError: LocalizedError {
    case verificationFailed
    case purchaseFailed
    case storeNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Transaction verification failed"
        case .purchaseFailed:
            return "Purchase could not be completed"
        case .storeNotAvailable:
            return "App Store is not available"
        }
    }
}

// MARK: - Product Extension

extension Product {
    /// Get display name for the subscription
    var displayName: String {
        if id.contains("yearly") {
            return "Premium Yearly"
        }
        return "Premium Monthly"
    }
    
    /// Get subscription period description
    var periodDescription: String {
        guard let subscription = self.subscription else {
            return ""
        }
        
        let period = subscription.subscriptionPeriod
        let unit = period.unit
        
        switch unit {
        case .day:
            return period.numberOfUnits == 1 ? "per day" : "per \(period.numberOfUnits) days"
        case .week:
            return period.numberOfUnits == 1 ? "per week" : "per \(period.numberOfUnits) weeks"
        case .month:
            return period.numberOfUnits == 1 ? "per month" : "per \(period.numberOfUnits) months"
        case .year:
            return period.numberOfUnits == 1 ? "per year" : "per \(period.numberOfUnits) years"
        @unknown default:
            return "per month"
        }
    }
}

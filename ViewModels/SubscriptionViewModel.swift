//
//  SubscriptionViewModel.swift
//  PollenSymptomTracker
//  ViewModel for subscription management with StoreKit 2 integration
//

import Foundation
import SwiftUI
import StoreKit

/// ViewModel for subscription management
/// Integrates with StoreKit 2 for real purchases
@MainActor
class SubscriptionViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var subscriptionState: SubscriptionState
    @Published var config: SubscriptionConfig
    @Published var isLoading = false
    @Published var showPaywall = false
    @Published var errorMessage: String?
    
    // StoreKit integration
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isStoreAvailable = false
    
    // MARK: - Private Properties
    
    private let storage = StorageService.shared
    private var paymentService: PaymentService?
    
    // MARK: - Initialization
    
    init() {
        subscriptionState = storage.loadSubscriptionState()
        config = SubscriptionConfig.load()
        
        // Note: PaymentService is injected via environment in production
        // For standalone use, we'll initialize lazily
    }
    
    // MARK: - Environment Integration
    
    /// Set the payment service from environment
    func setPaymentService(_ service: PaymentService) {
        self.paymentService = service
        self.products = service.products
        self.purchasedProductIDs = service.purchasedProductIDs
        self.isStoreAvailable = service.isStoreAvailable
    }
    
    // MARK: - Subscription Status
    
    /// Check current subscription status
    func checkSubscriptionStatus() {
        let state = storage.loadSubscriptionState()
        
        // Check if expired
        if state.status == .premium || state.status == .trial {
            if let expDate = state.expirationDate, expDate < Date() {
                subscriptionState = SubscriptionState(
                    status: .expired,
                    expirationDate: expDate,
                    productID: state.productID
                )
                storage.saveSubscriptionState(subscriptionState)
            } else {
                subscriptionState = state
            }
        } else {
            subscriptionState = state
        }
        
        // Sync with StoreKit
        syncWithStoreKit()
    }
    
    /// Sync subscription state with StoreKit
    private func syncWithStoreKit() {
        // If StoreKit shows active subscription, update local state
        if let paymentService = paymentService, paymentService.isPremium {
            // Find the product
            if let productID = paymentService.purchasedProductIDs.first {
                // Calculate expiration (for subscriptions, it's current date + period)
                // In production, you'd get this from the transaction
                let expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
                
                subscriptionState = SubscriptionState(
                    status: .premium,
                    expirationDate: expirationDate,
                    productID: productID
                )
                
                storage.saveSubscriptionState(subscriptionState)
            }
        }
    }
    
    // MARK: - Premium Access
    
    /// Check if user has premium access
    var isPremium: Bool {
        // Check StoreKit first
        if let service = paymentService, service.isPremium {
            return true
        }
        
        // Fall back to local state
        return subscriptionState.isActive
    }
    
    /// Show paywall if not premium
    func checkAndShowPaywall() {
        if !isPremium {
            showPaywall = true
        }
    }
    
    // MARK: - Subscribe
    
    /// Subscribe to premium
    /// - Parameter productID: The product ID to subscribe to
    func subscribe(to productID: String) async {
        isLoading = true
        errorMessage = nil
        
        // Try to use StoreKit if available
        if let service = paymentService, service.isStoreAvailable {
            let success = await service.subscribe(to: productID)
            
            if success {
                // Update local state
                let expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
                subscriptionState = SubscriptionState(
                    status: .premium,
                    expirationDate: expirationDate,
                    productID: productID
                )
                storage.saveSubscriptionState(subscriptionState)
            } else {
                errorMessage = service.errorMessage ?? "Purchase failed"
            }
        } else {
            // Fallback: Simulate subscription for development/testing
            #if DEBUG
            simulateSubscription(productID: productID)
            #else
            errorMessage = "App Store is not available. Please check your internet connection."
            #endif
        }
        
        isLoading = false
        showPaywall = false
    }
    
    /// Simulate subscription for development
    #if DEBUG
    private func simulateSubscription(productID: String) {
        let expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        
        subscriptionState = SubscriptionState(
            status: .premium,
            expirationDate: expirationDate,
            productID: productID
        )
        
        storage.saveSubscriptionState(subscriptionState)
    }
    #endif
    
    // MARK: - Restore Purchases
    
    /// Restore previous purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        if let service = paymentService {
            await service.restorePurchases()
            
            // Check if restoration was successful
            if service.isPremium {
                checkSubscriptionStatus()
            } else {
                errorMessage = "No previous purchases found."
            }
        } else {
            #if DEBUG
            // In debug mode, just refresh
            checkSubscriptionStatus()
            #else
            errorMessage = "Unable to restore purchases. Please try again."
            #endif
        }
        
        isLoading = false
    }
    
    // MARK: - Cancel Subscription
    
    /// Cancel subscription (marks as expired)
    /// Note: This doesn't actually cancel with Apple, just marks locally
    func cancelSubscription() {
        subscriptionState = SubscriptionState(
            status: .expired,
            expirationDate: Date(),
            productID: subscriptionState.productID
        )
        
        storage.saveSubscriptionState(subscriptionState)
    }
    
    // MARK: - Formatting
    
    /// Get formatted expiration date
    var expirationDateFormatted: String {
        guard let date = subscriptionState.expirationDate else {
            return "N/A"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Get subscription status text
    var statusText: String {
        switch subscriptionState.status {
        case .free:
            return "Free Plan"
        case .premium:
            return "Premium (Active)"
        case .trial:
            return "Trial"
        case .expired:
            return "Expired"
        }
    }
    
    // MARK: - Sandbox Message
    
    /// Get sandbox/testing message
    var sandboxMessage: String? {
        #if targetEnvironment(simulator)
        return "StoreKit is not available in the simulator. Purchases won't work without TestFlight."
        #else
        return paymentService?.sandboxMessage
        #endif
    }
}

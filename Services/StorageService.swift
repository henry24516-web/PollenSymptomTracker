//
//  StorageService.swift
//  PollenSymptomTracker
//  Enhanced storage service with migration-safe handling
//

import Foundation

/// Service for local data storage using UserDefaults
/// Includes migration-safe handling for stored logs/settings
class StorageService {
    static let shared = StorageService()
    
    private let defaults = UserDefaults.standard
    
    // Storage keys - using app-specific prefix to avoid conflicts
    private static let appPrefix = "com.pollenhealth.symptomtracker."
    private let symptomLogsKey = Self.appPrefix + "symptom_logs"
    private let subscriptionStateKey = Self.appPrefix + "subscription_state"
    private let lastPollenDataKey = Self.appPrefix + "last_pollen_data"
    private let userLocationKey = Self.appPrefix + "user_location"
    private let onboardingCompletedKey = Self.appPrefix + "onboarding_completed"
    private let notificationPrefsKey = Self.appPrefix + "notification_prefs"
    private let storageVersionKey = Self.appPrefix + "storage_version"
    
    // Current storage schema version
    private let currentStorageVersion = 2
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        
        // Run migrations on init
        runMigrationsIfNeeded()
    }
    
    // MARK: - Migration Support
    
    /// Run storage migrations if needed
    private func runMigrationsIfNeeded() {
        let storedVersion = defaults.integer(forKey: storageVersionKey)
        
        if storedVersion < 1 {
            migrateFromV0toV1()
        }
        
        if storedVersion < 2 {
            migrateFromV1toV2()
        }
        
        // Update version after all migrations
        defaults.set(currentStorageVersion, forKey: storageVersionKey)
    }
    
    /// Migration from v0 to v1: Add app prefix to keys
    private func migrateFromV0toV1() {
        // Migrate symptom logs
        if let oldData = UserDefaults.standard.data(forKey: "symptom_logs"),
           defaults.data(forKey: symptomLogsKey) == nil {
            defaults.set(oldData, forKey: symptomLogsKey)
        }
        
        // Migrate subscription state
        if let oldData = UserDefaults.standard.data(forKey: "subscription_state"),
           defaults.data(forKey: subscriptionStateKey) == nil {
            defaults.set(oldData, forKey: subscriptionStateKey)
        }
        
        // Migrate pollen data
        if let oldData = UserDefaults.standard.data(forKey: "last_pollen_data"),
           defaults.data(forKey: lastPollenDataKey) == nil {
            defaults.set(oldData, forKey: lastPollenDataKey)
        }
        
        // Migrate user location
        if let oldDict = UserDefaults.standard.dictionary(forKey: "user_location"),
           defaults.dictionary(forKey: userLocationKey) == nil {
            defaults.set(oldDict, forKey: userLocationKey)
        }
    }
    
    /// Migration from v1 to v2: Add notification preferences
    private func migrateFromV1toV2() {
        // V2 adds notification preferences - no data migration needed
        // Just ensure defaults are set
        if defaults.object(forKey: notificationPrefsKey) == nil {
            defaults.set(false, forKey: "notification_daily_reminder_enabled")
            defaults.set(true, forKey: "notification_high_pollen_alerts")
        }
    }
    
    // MARK: - Symptom Logs
    
    /// Save symptom logs with atomic write
    func saveSymptomLogs(_ logs: [SymptomLog]) {
        do {
            let data = try encoder.encode(logs)
            
            // Use temporary key for atomic write
            let tempKey = symptomLogsKey + "_temp"
            defaults.set(data, forKey: tempKey)
            
            // Atomically rename
            if defaults.data(forKey: tempKey) != nil {
                defaults.removeObject(forKey: symptomLogsKey)
                defaults.set(data, forKey: symptomLogsKey)
                defaults.removeObject(forKey: tempKey)
            }
        } catch {
            print("Failed to save symptom logs: \(error)")
        }
    }
    
    /// Load symptom logs with fallback
    func loadSymptomLogs() -> [SymptomLog] {
        guard let data = defaults.data(forKey: symptomLogsKey) else {
            return []
        }
        
        do {
            return try decoder.decode([SymptomLog].self, from: data)
        } catch {
            print("Failed to load symptom logs: \(error)")
            // Try to recover by returning empty array
            return []
        }
    }
    
    /// Add a new symptom log
    func addSymptomLog(_ log: SymptomLog) {
        var logs = loadSymptomLogs()
        logs.append(log)
        saveSymptomLogs(logs)
    }
    
    /// Get symptom logs for a specific date range
    func getSymptomLogs(from startDate: Date, to endDate: Date) -> [SymptomLog] {
        let logs = loadSymptomLogs()
        return logs.filter { log in
            log.date >= startDate && log.date <= endDate
        }
    }
    
    /// Delete a symptom log by ID
    func deleteSymptomLog(id: UUID) {
        var logs = loadSymptomLogs()
        logs.removeAll { $0.id == id }
        saveSymptomLogs(logs)
    }
    
    // MARK: - Subscription State
    
    /// Save subscription state with validation
    func saveSubscriptionState(_ state: SubscriptionState) {
        do {
            let data = try encoder.encode(state)
            defaults.set(data, forKey: subscriptionStateKey)
        } catch {
            print("Failed to save subscription state: \(error)")
        }
    }
    
    /// Load subscription state with fallback
    func loadSubscriptionState() -> SubscriptionState {
        guard let data = defaults.data(forKey: subscriptionStateKey) else {
            return SubscriptionState(status: .free, expirationDate: nil, productID: nil)
        }
        
        do {
            let state = try decoder.decode(SubscriptionState.self, from: data)
            
            // Validate the loaded state
            if state.status == .premium || state.status == .trial {
                if let expDate = state.expirationDate, expDate < Date() {
                    // Expired - return expired state
                    return SubscriptionState(
                        status: .expired,
                        expirationDate: expDate,
                        productID: state.productID
                    )
                }
            }
            
            return state
        } catch {
            print("Failed to load subscription state: \(error)")
            return SubscriptionState(status: .free, expirationDate: nil, productID: nil)
        }
    }
    
    // MARK: - Pollen Data Cache
    
    /// Cache last pollen data
    func cachePollenData(_ data: PollenData) {
        do {
            let encoded = try encoder.encode(data)
            defaults.set(encoded, forKey: lastPollenDataKey)
        } catch {
            print("Failed to cache pollen data: \(error)")
        }
    }
    
    /// Load cached pollen data
    func loadCachedPollenData() -> PollenData? {
        guard let data = defaults.data(forKey: lastPollenDataKey) else {
            return nil
        }
        
        do {
            return try decoder.decode(PollenData.self, from: data)
        } catch {
            print("Failed to decode cached pollen data: \(error)")
            return nil
        }
    }
    
    // MARK: - User Location
    
    /// Save user location
    func saveUserLocation(latitude: Double, longitude: Double, cityName: String?) {
        let location: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "cityName": cityName ?? ""
        ]
        defaults.set(location, forKey: userLocationKey)
    }
    
    /// Load user location
    func loadUserLocation() -> (latitude: Double, longitude: Double, cityName: String?)? {
        guard let location = defaults.dictionary(forKey: userLocationKey),
              let lat = location["latitude"] as? Double,
              let lon = location["longitude"] as? Double else {
            return nil
        }
        
        let cityName = location["cityName"] as? String
        return (lat, lon, cityName)
    }
    
    // MARK: - Onboarding State
    
    /// Check if onboarding is completed
    var isOnboardingCompleted: Bool {
        get { defaults.bool(forKey: onboardingCompletedKey) }
        set { defaults.set(newValue, forKey: onboardingCompletedKey) }
    }
    
    /// Mark onboarding as completed
    func completeOnboarding() {
        isOnboardingCompleted = true
    }
    
    // MARK: - Notification Preferences
    
    /// Save notification preferences
    func saveNotificationPreferences(_ prefs: NotificationPreferences) {
        do {
            let data = try encoder.encode(prefs)
            defaults.set(data, forKey: notificationPrefsKey)
        } catch {
            print("Failed to save notification preferences: \(error)")
        }
    }
    
    /// Load notification preferences
    func loadNotificationPreferences() -> NotificationPreferences {
        guard let data = defaults.data(forKey: notificationPrefsKey) else {
            return NotificationPreferences()
        }
        
        do {
            return try decoder.decode(NotificationPreferences.self, from: data)
        } catch {
            return NotificationPreferences()
        }
    }
    
    // MARK: - Utilities
    
    /// Clear all data (for testing/logout)
    func clearAllData() {
        defaults.removeObject(forKey: symptomLogsKey)
        defaults.removeObject(forKey: subscriptionStateKey)
        defaults.removeObject(forKey: lastPollenDataKey)
        defaults.removeObject(forKey: userLocationKey)
        defaults.removeObject(forKey: onboardingCompletedKey)
        defaults.removeObject(forKey: notificationPrefsKey)
    }
    
    /// Get storage usage info
    func getStorageInfo() -> (symptomLogsCount: Int, isPremium: Bool, storageVersion: Int) {
        let logs = loadSymptomLogs()
        let subscription = loadSubscriptionState()
        let version = defaults.integer(forKey: storageVersionKey)
        return (logs.count, subscription.isActive, version)
    }
    
    /// Export data as JSON (for user data portability)
    func exportData() -> Data? {
        let exportData = StorageExportData(
            symptomLogs: loadSymptomLogs(),
            subscriptionState: loadSubscriptionState(),
            notificationPreferences: loadNotificationPreferences(),
            exportDate: Date()
        )
        
        return try? encoder.encode(exportData)
    }
}

// MARK: - Supporting Types

/// Notification preferences model
struct NotificationPreferences: Codable {
    var dailyReminderEnabled: Bool = false
    var reminderTime: Date? = nil
    var highPollenAlertsEnabled: Bool = true
    
    init() {}
    
    init(dailyReminderEnabled: Bool, reminderTime: Date?, highPollenAlertsEnabled: Bool) {
        self.dailyReminderEnabled = dailyReminderEnabled
        self.reminderTime = reminderTime
        self.highPollenAlertsEnabled = highPollenAlertsEnabled
    }
}

/// Storage export data structure
struct StorageExportData: Codable {
    let symptomLogs: [SymptomLog]
    let subscriptionState: SubscriptionState
    let notificationPreferences: NotificationPreferences
    let exportDate: Date
}

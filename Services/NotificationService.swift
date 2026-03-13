//
//  NotificationService.swift
//  PollenSymptomTracker
//  Local notification service for daily symptom logging reminders
//

import Foundation
import UserNotifications
import UIKit

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    @Published var errorMessage: String?
    
    // Notification identifiers
    private let dailyReminderID = "daily_symptom_reminder"
    private let highPollenAlertID = "high_pollen_alert"
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, sound])
            isAuthorized = granted
            
            if granted {
                await scheduleDailyReminder()
            }
            
            return granted
        } catch {
            errorMessage = "Failed to request notification permission: \(error.localizedDescription)"
            return false
        }
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    /// Open system notification settings
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Daily Reminder
    
    /// Schedule daily symptom logging reminder
    func scheduleDailyReminder(time: Date? = nil) async {
        // Cancel existing daily reminder first
        await cancelDailyReminder()
        
        // Default to 8 AM if no time specified
        let reminderTime = time ?? Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!
        
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        dateComponents.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let content = UNMutableNotificationContent()
        content.title = "🌸 Track Your Symptoms"
        content.body = "Don't forget to log how you're feeling today! Understanding your pollen exposure helps you stay prepared."
        content.sound = .default
        content.badge = 1
        
        // Add category for actionable notifications
        content.categoryIdentifier = "SYMPTOM_REMINDER"
        
        let request = UNNotificationRequest(
            identifier: dailyReminderID,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("Daily reminder scheduled for \(dateComponents.hour ?? 0):\(dateComponents.minute ?? 0)")
        } catch {
            errorMessage = "Failed to schedule daily reminder: \(error.localizedDescription)"
        }
    }
    
    /// Cancel daily reminder
    func cancelDailyReminder() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])
    }
    
    // MARK: - High Pollen Alert
    
    /// Schedule high pollen alert notification
    func scheduleHighPollenAlert(pollenLevel: String, date: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ High Pollen Alert"
        content.body = "Pollen levels are forecast to be \(pollenLevel) tomorrow. Consider taking antihistamines and limiting outdoor exposure."
        content.sound = .default
        
        // Schedule for 6 AM on the target date
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = 6
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "\(highPollenAlertID)_\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule high pollen alert: \(error)")
        }
    }
    
    /// Cancel all high pollen alerts
    func cancelHighPollenAlerts() {
        notificationCenter.getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix(self.highPollenAlertID) }
                .map { $0.identifier }
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
    
    // MARK: - Notification Management
    
    /// Get all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    /// Clear all notifications (including badge)
    func clearAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    /// Set badge number
    func setBadge(_ count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }
    
    /// Clear badge
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

// MARK: - Notification Settings Storage

extension NotificationService {
    /// Save notification preferences
    func savePreferences(dailyReminderEnabled: Bool, reminderTime: Date?, highPollenAlerts: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(dailyReminderEnabled, forKey: "notification_daily_reminder_enabled")
        
        if let time = reminderTime {
            defaults.set(time, forKey: "notification_reminder_time")
        } else {
            defaults.removeObject(forKey: "notification_reminder_time")
        }
        
        defaults.set(highPollenAlerts, forKey: "notification_high_pollen_alerts")
    }
    
    /// Load notification preferences
    func loadPreferences() -> (dailyReminderEnabled: Bool, reminderTime: Date?, highPollenAlerts: Bool) {
        let defaults = UserDefaults.standard
        let dailyEnabled = defaults.bool(forKey: "notification_daily_reminder_enabled")
        let reminderTime = defaults.object(forKey: "notification_reminder_time") as? Date
        let highPollenEnabled = defaults.bool(forKey: "notification_high_pollen_alerts")
        
        return (dailyEnabled, reminderTime, highPollenEnabled)
    }
}

import Foundation
import UserNotifications

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let notificationCenter = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        notificationCenter.delegate = self
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func requestAuthorization() async throws -> Bool {
        let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        await checkAuthorizationStatus()
        return granted
    }

    // MARK: - Schedule Notifications

    func scheduleCareReminder(
        id: String,
        plantName: String,
        reminderType: String,
        dueDate: Date,
        notes: String? = nil
    ) async throws {
        guard isAuthorized else {
            print("⚠️ Notification not authorized")
            return
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "🌱 \(reminderType) Reminder"
        content.body = "Time to care for \(plantName)!"

        if let notes = notes, !notes.isEmpty {
            content.body += " \(notes)"
        }

        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "CARE_REMINDER"
        content.userInfo = [
            "reminderId": id,
            "plantName": plantName,
            "reminderType": reminderType
        ]

        // Calculate time interval from now
        let timeInterval = dueDate.timeIntervalSinceNow

        // Only schedule if the date is in the future
        guard timeInterval > 0 else {
            print("⚠️ Cannot schedule notification in the past")
            return
        }

        // Create trigger
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )

        // Create request
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        try await notificationCenter.add(request)
        print("✅ Scheduled notification for \(plantName) - \(reminderType) at \(dueDate)")
    }

    func scheduleRecurringReminder(
        id: String,
        plantName: String,
        reminderType: String,
        frequencyInDays: Int,
        startDate: Date,
        notes: String? = nil
    ) async throws {
        guard isAuthorized else {
            print("⚠️ Notification not authorized")
            return
        }

        // Schedule the first notification
        try await scheduleCareReminder(
            id: id,
            plantName: plantName,
            reminderType: reminderType,
            dueDate: startDate,
            notes: notes
        )
    }

    // MARK: - Cancel Notifications

    func cancelNotification(withId id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        print("🗑️ Cancelled notification: \(id)")
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("🗑️ Cancelled all notifications")
    }

    // MARK: - Update Notification

    func updateNotification(
        id: String,
        plantName: String,
        reminderType: String,
        newDueDate: Date,
        notes: String? = nil
    ) async throws {
        // Cancel existing notification
        cancelNotification(withId: id)

        // Schedule new notification
        try await scheduleCareReminder(
            id: id,
            plantName: plantName,
            reminderType: reminderType,
            dueDate: newDueDate,
            notes: notes
        )
    }

    // MARK: - Query Notifications

    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }

    func getDeliveredNotifications() async -> [UNNotification] {
        return await notificationCenter.deliveredNotifications()
    }

    func getPendingNotificationCount() async -> Int {
        let notifications = await getPendingNotifications()
        return notifications.count
    }

    // MARK: - Badge Management

    func setBadgeCount(_ count: Int) async {
        await notificationCenter.setBadgeCount(count)
    }

    func clearBadge() async {
        await notificationCenter.setBadgeCount(0)
    }

    // MARK: - Test Notification

    func scheduleTestNotification() async throws {
        let content = UNMutableNotificationContent()
        content.title = "🌱 Test Notification"
        content.body = "Your plant care notifications are working!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        print("✅ Scheduled test notification (will appear in 5 seconds)")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Extract reminder info
        if let reminderId = userInfo["reminderId"] as? String,
           let plantName = userInfo["plantName"] as? String,
           let reminderType = userInfo["reminderType"] as? String {

            print("📱 User tapped notification for: \(plantName) - \(reminderType)")

            // Post notification to switch to reminders tab
            Task { @MainActor in
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowReminder"),
                    object: nil,
                    userInfo: ["reminderId": reminderId]
                )
            }
        }

        completionHandler()
    }
}

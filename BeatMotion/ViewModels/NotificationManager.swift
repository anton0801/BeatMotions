import UserNotifications
import Foundation

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func checkPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    func scheduleFocusReminder(hour: Int) {
        removeNotification(id: "focusReminder")
        let content = UNMutableNotificationContent()
        content.title = "Time to Focus 🎯"
        content.body = "Start your focus session with Beat Motion."
        content.sound = .default
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "focusReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleRelaxReminder(hour: Int) {
        removeNotification(id: "relaxReminder")
        let content = UNMutableNotificationContent()
        content.title = "Time to Relax 🌙"
        content.body = "Wind down with a relaxing Beat Motion session."
        content.sound = .default
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "relaxReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleMoodCheck(hour: Int) {
        removeNotification(id: "dailyMoodCheck")
        let content = UNMutableNotificationContent()
        content.title = "Daily Mood Check ✨"
        content.body = "How are you feeling today? Set your sound mood."
        content.sound = .default
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyMoodCheck", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func removeNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func removeAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

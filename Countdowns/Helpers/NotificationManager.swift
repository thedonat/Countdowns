//
//  NotificationManager.swift
//  Countdowns
//
//  Created by Burak Donat on 1/17/26.
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let leadHoursKey = "notificationLeadHours"

    private init() {}

    func leadHours() -> Int {
        let storedValue = UserDefaults.standard.integer(forKey: leadHoursKey)
        return storedValue > 0 ? storedValue : 4
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                return granted
            } catch {
                return false
            }
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func scheduleNotification(for event: Event, leadHours: Int) {
        guard event.date > Date() else {
            return
        }

        let triggerDate = event.date.addingTimeInterval(-TimeInterval(leadHours) * 3600)
        guard triggerDate > Date() else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = LocalizationManager.localizedString("Upcoming Event")
        let hoursText = leadHours == 1
            ? LocalizationManager.localizedString("1 hour")
            : LocalizationManager.localizedFormat("%d hours", leadHours)
        content.body = LocalizationManager.localizedFormat("%@ starts in %@.", event.name, hoursText)
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: event),
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    func removeNotification(for event: Event) {
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier(for: event)])
    }

    func removeAllEventNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    private func notificationIdentifier(for event: Event) -> String {
        "event.\(event.id.uuidString)"
    }
}

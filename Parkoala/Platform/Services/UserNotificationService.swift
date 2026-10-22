//
//  UserNotificationService.swift
//  Parkoala
//
//  Created by Đức Anh on 21/10/26.
//

import Foundation
import UserNotifications

final class UserNotificationService: NotificationService {

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(
            options: [.alert, .sound, .badge]
        )
    }

    func scheduleNotification(
        id: String,
        title: String,
        body: String,
        fireDate: Date
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let timeInterval = fireDate.timeIntervalSinceNow

        guard timeInterval > 0 else {
            throw ParkingAlertError.invalidExpiryTime
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    func cancelNotifications(ids: [String]) {
        center.removePendingNotificationRequests(
            withIdentifiers: ids
        )
    }
}

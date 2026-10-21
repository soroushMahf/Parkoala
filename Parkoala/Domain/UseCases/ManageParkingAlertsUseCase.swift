//
//  ManageParkingAlertsUseCase.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 19/10/2026.
//

import Foundation

struct ManageParkingAlertsUseCase {

    static let fifteenMinuteReminderID = "parking-expiry-15"
    static let fiveMinuteReminderID = "parking-expiry-5"

    private let notificationService: NotificationService

    init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }

    func scheduleExpiryReminders(
        expiryDate: Date,
        now: Date = .now
    ) async throws {

        guard expiryDate > now else {
            throw ParkingAlertError.invalidExpiryTime
        }

        let authorized = try await notificationService.requestAuthorization()

        guard authorized else {
            throw ParkingAlertError.notificationsDenied
        }

        let notificationIDs = [
            Self.fifteenMinuteReminderID,
            Self.fiveMinuteReminderID
        ]

        notificationService.cancelNotifications(ids: notificationIDs)

        let fifteenMinuteDate = expiryDate.addingTimeInterval(-15 * 60)
        let fiveMinuteDate = expiryDate.addingTimeInterval(-5 * 60)

        if fifteenMinuteDate > now {
            try await notificationService.scheduleNotification(
                id: Self.fifteenMinuteReminderID,
                title: "Parking expires soon",
                body: "Your parking session expires in 15 minutes.",
                fireDate: fifteenMinuteDate
            )
        }

        if fiveMinuteDate > now {
            try await notificationService.scheduleNotification(
                id: Self.fiveMinuteReminderID,
                title: "Parking expires soon",
                body: "Your parking session expires in 5 minutes.",
                fireDate: fiveMinuteDate
            )
        }
    }

    func cancelExpiryReminders() {
        notificationService.cancelNotifications(
            ids: [
                Self.fifteenMinuteReminderID,
                Self.fiveMinuteReminderID
            ]
        )
    }
}

//
//  MockNotificationService.swift
//  Parkoala
//
//  Created by Đức Anh on 21/10/26.
//


import Foundation
@testable import Parkoala

final class MockNotificationService: NotificationService {

    struct ScheduledNotification: Equatable {
        let id: String
        let title: String
        let body: String
        let fireDate: Date
    }

    var authorizationGranted = true

    var scheduledNotifications: [ScheduledNotification] = []
    var cancelledIDs: [String] = []

    func requestAuthorization() async throws -> Bool {
        authorizationGranted
    }

    func scheduleNotification(
        id: String,
        title: String,
        body: String,
        fireDate: Date
    ) async throws {
        scheduledNotifications.append(
            ScheduledNotification(
                id: id,
                title: title,
                body: body,
                fireDate: fireDate
            )
        )
    }

    func cancelNotifications(ids: [String]) {
        cancelledIDs.append(contentsOf: ids)
    }
}
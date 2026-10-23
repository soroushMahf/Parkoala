//
//  NotificationService.swift
//  Parkoala
//
//  Created by Đức Anh on 21/10/26.
//


import Foundation

protocol NotificationService {
    func requestAuthorization() async throws -> Bool

    func scheduleNotification(
        id: String,
        title: String,
        body: String,
        fireDate: Date
    ) async throws

    func cancelNotifications(ids: [String])
}
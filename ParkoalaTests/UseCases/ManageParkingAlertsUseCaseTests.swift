//
//  ManageParkingAlertsUseCaseTests.swift
//  Parkoala
//
//  Created by Đức Anh on 21/10/26.
//


import XCTest
@testable import Parkoala

@MainActor
final class ManageParkingAlertsUseCaseTests: XCTestCase {

    private var mockNotificationService: MockNotificationService!
    private var useCase: ManageParkingAlertsUseCase!

    override func setUp() {
        super.setUp()

        mockNotificationService = MockNotificationService()
        useCase = ManageParkingAlertsUseCase(
            notificationService: mockNotificationService
        )
    }

    override func tearDown() {
        mockNotificationService = nil
        useCase = nil

        super.tearDown()
    }

    func testScheduleExpiryRemindersSchedules15And5MinuteAlerts() async throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let expiryDate = now.addingTimeInterval(30 * 60)

        try await useCase.scheduleExpiryReminders(
            expiryDate: expiryDate,
            now: now
        )

        XCTAssertEqual(
            mockNotificationService.scheduledNotifications.count,
            2
        )

        XCTAssertEqual(
            mockNotificationService.scheduledNotifications[0].id,
            ManageParkingAlertsUseCase.fifteenMinuteReminderID
        )

        XCTAssertEqual(
            mockNotificationService.scheduledNotifications[0].fireDate,
            now.addingTimeInterval(15 * 60)
        )

        XCTAssertEqual(
            mockNotificationService.scheduledNotifications[1].id,
            ManageParkingAlertsUseCase.fiveMinuteReminderID
        )

        XCTAssertEqual(
            mockNotificationService.scheduledNotifications[1].fireDate,
            now.addingTimeInterval(25 * 60)
        )
    }

    func testScheduleExpiryRemindersSkips15MinuteAlertWhenAlreadyPassed() async throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let expiryDate = now.addingTimeInterval(10 * 60)

        try await useCase.scheduleExpiryReminders(
            expiryDate: expiryDate,
            now: now
        )

        XCTAssertEqual(
            mockNotificationService.scheduledNotifications.count,
            1
        )

        XCTAssertEqual(
            mockNotificationService.scheduledNotifications[0].id,
            ManageParkingAlertsUseCase.fiveMinuteReminderID
        )
    }

    func testScheduleExpiryRemindersSchedulesNoAlertWhenLessThan5MinutesRemain() async throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let expiryDate = now.addingTimeInterval(4 * 60)

        try await useCase.scheduleExpiryReminders(
            expiryDate: expiryDate,
            now: now
        )

        XCTAssertTrue(
            mockNotificationService.scheduledNotifications.isEmpty
        )
    }

    func testScheduleExpiryRemindersThrowsWhenExpiryIsInPast() async {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let expiryDate = now.addingTimeInterval(-60)

        do {
            try await useCase.scheduleExpiryReminders(
                expiryDate: expiryDate,
                now: now
            )

            XCTFail("Expected invalidExpiryTime error")
        } catch {
            XCTAssertEqual(
                error as? ParkingAlertError,
                .invalidExpiryTime
            )
        }
    }

    func testScheduleExpiryRemindersThrowsWhenNotificationsDenied() async {
        mockNotificationService.authorizationGranted = false

        let now = Date(timeIntervalSince1970: 1_000_000)
        let expiryDate = now.addingTimeInterval(30 * 60)

        do {
            try await useCase.scheduleExpiryReminders(
                expiryDate: expiryDate,
                now: now
            )

            XCTFail("Expected notificationsDenied error")
        } catch {
            XCTAssertEqual(
                error as? ParkingAlertError,
                .notificationsDenied
            )
        }
    }

    func testCancelExpiryRemindersCancelsBothNotifications() {
        useCase.cancelExpiryReminders()

        XCTAssertEqual(
            mockNotificationService.cancelledIDs,
            [
                ManageParkingAlertsUseCase.fifteenMinuteReminderID,
                ManageParkingAlertsUseCase.fiveMinuteReminderID
            ]
        )
    }
}

//
//  ParkingSignFixture.swift
//  ParkoalaTests
//
//  Created by Heather
//
import Foundation
@testable import Parkoala

/// Shared setup for parking sign tests: a fixed Sydney calendar and a "2P 8am–6pm Mon–Fri" sign.
@MainActor
struct ParkingSignFixture {
    let calendar: Calendar
    let useCase: ManageParkingRestrictionsUseCase
    let twoHourWeekdaySign = ParkingRestriction.twoHourWeekdaySign

    init() {
        var sydney = Calendar(identifier: .gregorian)
        sydney.timeZone = TimeZone(identifier: "Australia/Sydney") ?? .current
        calendar = sydney
        useCase = ManageParkingRestrictionsUseCase(calendar: sydney)
    }

    /// A time on Tuesday 20 October 2026 in Sydney.
    func tuesday(hour: Int, minute: Int = 0) -> Date {
        date(day: 20, hour: hour, minute: minute)
    }

    /// A time on Saturday 24 October 2026 in Sydney.
    func saturday(hour: Int, minute: Int = 0) -> Date {
        date(day: 24, hour: hour, minute: minute)
    }

    private func date(day: Int, hour: Int, minute: Int) -> Date {
        let components = DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute)
        return calendar.date(from: components) ?? .distantPast
    }
}

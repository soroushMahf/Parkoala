//
//  ManageParkingRestrictionsUseCaseTests.swift
//  ParkoalaTests
//
//  Created by Heather

import Foundation
import Testing
@testable import Parkoala

@MainActor
@Suite("Manage parking restrictions")
struct ManageParkingRestrictionsUseCaseTests {
    let fixture = ParkingSignFixture()

    // Validate the sign

    @Test func validateSignAcceptsTypicalTwoHourWeekdaySign() {
        #expect(throws: Never.self) {
            try fixture.useCase.validateSign(fixture.twoHourWeekdaySign)
        }
    }

    @Test(arguments: [15, 30, 60, 120, 180, 240])
    func validateSignAcceptsEverySupportedTimeLimit(minutes: Int) {
        var sign = fixture.twoHourWeekdaySign
        sign.maxStay = TimeInterval(minutes * 60)
        #expect(throws: Never.self) {
            try fixture.useCase.validateSign(sign)
        }
    }

    @Test func validateSignThrowsUnsupportedSignFor45MinuteLimit() {
        var sign = fixture.twoHourWeekdaySign
        sign.maxStay = 45 * 60
        #expect(throws: ParkingRestrictionsError.unsupportedSign) {
            try fixture.useCase.validateSign(sign)
        }
    }
}

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

    @Test func validateSignThrowsInvalidHoursWhenSignStartsAfterItEnds() {
        var sign = fixture.twoHourWeekdaySign
        sign.startMinute = 18 * 60
        sign.endMinute = 8 * 60
        #expect(throws: ParkingRestrictionsError.invalidHours) {
            try fixture.useCase.validateSign(sign)
        }
    }

    @Test func validateSignThrowsInvalidHoursWhenSignStartsAndEndsTogether() {
        var sign = fixture.twoHourWeekdaySign
        sign.startMinute = 8 * 60
        sign.endMinute = 8 * 60
        #expect(throws: ParkingRestrictionsError.invalidHours) {
            try fixture.useCase.validateSign(sign)
        }
    }

    @Test func validateSignThrowsNoDaysSelectedWhenNoDayIsTicked() {
        var sign = fixture.twoHourWeekdaySign
        sign.days = []
        #expect(throws: ParkingRestrictionsError.noDaysSelected) {
            try fixture.useCase.validateSign(sign)
        }
    }
    
    // Can I park here?
    @Test func checkParkingAllowsFullLimitWhenArrivingInsideSignHours() throws {
            let verdict = try fixture.useCase.checkParking(under: fixture.twoHourWeekdaySign, at: fixture.tuesday(hour: 10))
            #expect(verdict == .timeLimitApplies(moveCarBy: fixture.tuesday(hour: 12)))
        }

}


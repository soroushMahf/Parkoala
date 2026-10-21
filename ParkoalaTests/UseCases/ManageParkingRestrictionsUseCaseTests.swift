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
        // Act + Assert
        #expect(throws: Never.self) {
            try fixture.useCase.validateSign(fixture.twoHourWeekdaySign)
        }
    }
}

//
//  MockLiveActivityService.swift
//  Parkoala
//
//  Created by Đức Anh on 22/10/26.
//


import Foundation
@testable import Parkoala

final class MockLiveActivityService: LiveActivityService {

    var startedSessionID: UUID?
    var startedExpiryDate: Date?
    var startCallCount = 0

    var endCallCount = 0

    func startActivity(
        sessionID: UUID,
        expiryDate: Date
    ) async throws {
        startedSessionID = sessionID
        startedExpiryDate = expiryDate
        startCallCount += 1
    }

    func endActivity() async {
        endCallCount += 1
    }
}
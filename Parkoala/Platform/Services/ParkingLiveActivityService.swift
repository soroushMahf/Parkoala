//
//  ParkingLiveActivityService.swift
//  Parkoala
//
//  Created by Đức Anh on 21/10/26.
//


import ActivityKit
import Foundation

final class ParkingLiveActivityService: LiveActivityService {

    private var currentActivity: Activity<ParkingActivityAttributes>?

    func startActivity(
        sessionID: UUID,
        expiryDate: Date
    ) async throws {
        let attributes = ParkingActivityAttributes(
            sessionID: sessionID
        )

        let state = ParkingActivityAttributes.ContentState(
            expiryDate: expiryDate,
            isEnded: false
        )

        let content = ActivityContent(
            state: state,
            staleDate: expiryDate
        )

        currentActivity = try Activity.request(
            attributes: attributes,
            content: content
        )
    }

    func endActivity() async {
        guard let currentActivity else {
            return
        }

        let finalState = ParkingActivityAttributes.ContentState(
            expiryDate: Date(),
            isEnded: true
        )

        let finalContent = ActivityContent(
            state: finalState,
            staleDate: nil
        )

        await currentActivity.end(
            finalContent,
            dismissalPolicy: .immediate
        )

        self.currentActivity = nil
    }
}
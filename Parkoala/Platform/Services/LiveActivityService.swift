//
//  LiveActivityService.swift
//  Parkoala
//
//  Created by Đức Anh on 21/10/26.
//


import Foundation

protocol LiveActivityService {
    func startActivity(
        sessionID: UUID,
        expiryDate: Date
    ) async throws

    func endActivity() async
}
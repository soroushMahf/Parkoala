//
//  ParkingAlertError.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 19/10/2026.
//

import Foundation

enum ParkingAlertError: Error, Equatable {
    case notificationsDenied
    case invalidExpiryTime
    case schedulingFailed
}

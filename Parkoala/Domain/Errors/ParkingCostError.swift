//
//  ParkingCostError.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 19/10/2026.
//

import Foundation

// for CalculateParkingCostsUseCase.
enum ParkingCostError: Error, Equatable {
    case invalidDuration
    case noRateSet
    case invalidRate
    case noApplicableRate
    case invalidActualCost
}

extension ParkingCostError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidDuration: "End time must be after the start time."
        case .noRateSet: "Enter a rate to see an estimated cost."
        case .invalidRate: "Check the rate details you entered."
        case .noApplicableRate: "None of the rates you entered apply to this stay."
        case .invalidActualCost: "Enter a cost of $0.00 or more."
        }
    }
}

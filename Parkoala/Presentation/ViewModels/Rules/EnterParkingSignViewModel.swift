//
//  EnterParkingSignViewModel.swift
//  Parkoala
//
//  Created by Heather
//

import Foundation
import Observation

/// State for the Enter Parking Sign sheet: the sign being copied in and any problem with it.
@MainActor
@Observable
final class EnterParkingSignViewModel {
    /// The sign as entered so far. Editing it clears the old problem message.
    var restriction: ParkingRestriction {
        didSet { problemMessage = nil }
    }
    /// What's wrong with the sign, shown under the form. nil when there's nothing to fix.
    private(set) var problemMessage: String?

    @ObservationIgnored private let useCase: ManageParkingRestrictionsUseCase

    init(
        restriction: ParkingRestriction = .twoHourWeekdaySign,
        useCase: ManageParkingRestrictionsUseCase = ManageParkingRestrictionsUseCase()
    ) {
        self.restriction = restriction
        self.useCase = useCase
    }

    /// Returns the sign when it can be used; otherwise sets `problemMessage` and returns nil.
    func signReadyToSave() -> ParkingRestriction? {
        do {
            try useCase.validateSign(restriction)
            problemMessage = nil
            return restriction
        } catch let error as ParkingRestrictionsError {
            problemMessage = ParkingRestrictionsMessages.message(for: error)
            return nil
        } catch {
            problemMessage = ParkingRestrictionsMessages.unexpectedProblem
            return nil
        }
    }
}

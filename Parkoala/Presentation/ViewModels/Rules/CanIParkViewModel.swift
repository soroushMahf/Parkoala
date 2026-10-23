//
//  CanIParkViewModel.swift
//  Parkoala
//
//  Created by Heather
//
import Foundation
import Observation

/// State for "Can I park here?": the sign being checked and the answer for the driver.
@MainActor
@Observable
final class CanIParkViewModel {
    /// The sign as entered. Changing it clears the old answer, which would be wrong for the new sign.
    var restriction = ParkingRestriction.twoHourWeekdaySign {
        didSet {
            verdict = nil
            problemMessage = nil
        }
    }
    /// The latest answer, or nil before the first check or when the sign has a problem.
    private(set) var verdict: ParkingVerdict?
    /// What's wrong with the sign, if anything.
    private(set) var problemMessage: String?

    @ObservationIgnored private let useCase: ManageParkingRestrictionsUseCase

    init(useCase: ManageParkingRestrictionsUseCase? = nil) { 
        self.useCase = useCase ?? ManageParkingRestrictionsUseCase()
    }

    /// Checks the sign for a driver parking at `arrival` (now, unless a test passes a time).
    func checkParking(at arrival: Date = .now) {
        do {
            verdict = try useCase.checkParking(under: restriction, at: arrival)
            problemMessage = nil
        } catch let error as ParkingRestrictionsError {
            verdict = nil
            problemMessage = ParkingRestrictionsMessages.message(for: error)
        } catch {
            verdict = nil
            problemMessage = ParkingRestrictionsMessages.unexpectedProblem
        }
    }

    // Answer for the driver (never claims legal certainty)

    /// Headline, e.g. "Yes, until 12:00 pm".
    var answerHeadline: String? {
        guard let verdict else { return nil }
        switch verdict {
        case .timeLimitApplies(let moveCarBy):
            return ParkingRestrictionsMessages.parkUntil(moveCarBy)
        case .noTimeLimitNow:
            return ParkingRestrictionsMessages.noTimeLimitNow
        }
    }

    /// One line under the headline that says what the answer is based on.
    var answerExplanation: String? {
        guard let verdict else { return nil }
        switch verdict {
        case .timeLimitApplies:
            return ParkingRestrictionsMessages.basedOnSign(restriction.signWording)
        case .noTimeLimitNow(let limitStartsAt?):
            return ParkingRestrictionsMessages.limitStarts(restriction.timeLimitLabel, at: limitStartsAt)
        case .noTimeLimitNow(.none):
            return ParkingRestrictionsMessages.signDoesNotApplyToday
        }
    }
}

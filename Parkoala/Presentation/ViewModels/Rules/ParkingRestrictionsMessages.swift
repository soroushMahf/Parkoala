//
//  Parkoala
//
//  Created by Heather
//

import Foundation

/// Localised words the driver sees for parking signs: problems with a sign and the
/// "Can I park here?" answer. Each problem says what's wrong and what to do next.
enum ParkingRestrictionsMessages {
    static func message(for error: ParkingRestrictionsError) -> String {
        switch error {
        case .invalidHours:
            String(localized: "The sign’s start time must be before its end time. Check the times on the sign and try again.")
        case .noDaysSelected:
            String(localized: "Choose at least one day. Most signs show the days under the times, such as Mon–Fri.")
        case .unsupportedSign:
            String(localized: "Parkoala can time signs from ¼P to 4P. For a No Parking, No Stopping or zone sign, follow what the sign says.")
        }
    }

    /// For an error that isn't a sign problem. It shouldn't happen, but the driver still gets a next step.
    static var unexpectedProblem: String {
        String(localized: "Parkoala couldn’t check this sign. Try again, and follow what the sign says.")
    }

    //Can I park here?

    static func parkUntil(_ moveCarBy: Date) -> String {
        String(localized: "Yes, until \(moveCarBy.formatted(date: .omitted, time: .shortened))")
    }

    static var noTimeLimitNow: String {
        String(localized: "Yes, no time limit right now")
    }

    static func basedOnSign(_ signWording: String) -> String {
        String(localized: "Based on the \(signWording) sign you entered. Always check the sign itself and any other signs nearby.")
    }

    static func limitStarts(_ timeLimitLabel: String, at limitStartsAt: Date) -> String {
        String(localized: "The \(timeLimitLabel) limit starts at \(limitStartsAt.formatted(date: .omitted, time: .shortened)). Always check the sign itself.")
    }

    static var signDoesNotApplyToday: String {
        String(localized: "The sign you entered doesn’t apply for the rest of today. Always check the sign itself and any other signs nearby.")
    }
}

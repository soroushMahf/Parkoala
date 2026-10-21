// Loads finished parking sessions and groups them by month for the history list.

import Foundation

@MainActor
@Observable
final class SessionHistoryViewModel {

    struct MonthGroup: Identifiable {
        let month: Date
        let sessions: [ParkingSession]

        var id: Date { month }
    }

    private let useCase: ManageParkingSessionUseCase

    private(set) var months: [MonthGroup] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var isEmpty: Bool { months.isEmpty }

    init(useCase: ManageParkingSessionUseCase) {
        self.useCase = useCase
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let sessions = try await useCase.recentSessions()
            months = Self.groupByMonth(sessions)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Sessions come in newest first, so the months stay newest first too
    private static func groupByMonth(_ sessions: [ParkingSession]) -> [MonthGroup] {
        let calendar = Calendar.current
        var groups: [MonthGroup] = []

        for session in sessions {
            let month = calendar.dateInterval(of: .month, for: session.startDate)?.start ?? session.startDate

            if let last = groups.last, last.month == month {
                groups[groups.count - 1] = MonthGroup(month: month, sessions: last.sessions + [session])
            } else {
                groups.append(MonthGroup(month: month, sessions: [session]))
            }
        }
        return groups
    }
}

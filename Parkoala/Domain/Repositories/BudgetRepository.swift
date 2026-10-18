import Foundation

protocol BudgetRepository {
    func budget(forMonthOf date: Date) async throws -> Budget?
    func save(_ budget: Budget) async throws
}

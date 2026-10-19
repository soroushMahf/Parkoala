import Foundation

// Thrown by every repository. Use cases turn these into messages for the user.
enum RepositoryError: Error, Equatable {
    case saveFailed
    case fetchFailed
    case notFound
}

extension RepositoryError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .saveFailed: "Your changes couldn't be saved. Please try again."
        case .fetchFailed: "Your parking data couldn't be loaded. Please try again."
        case .notFound: "That item no longer exists."
        }
    }
}

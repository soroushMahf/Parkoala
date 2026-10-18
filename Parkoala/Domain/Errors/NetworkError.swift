import Foundation

// Thrown by the remote clients, such as the TfNSW Car Park API.
enum NetworkError: Error, Equatable {
    case offline
    case rateLimited
    case unauthorized
    case badResponse
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .offline: "You're offline. Showing the last saved information."
        case .rateLimited: "Too many requests right now. Please try again in a minute."
        case .unauthorized: "The live car park data couldn't be reached. Check the API key."
        case .badResponse: "The live car park data came back in an unexpected format."
        }
    }
}

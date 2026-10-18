import Foundation

// Creates the repositories and services once and hands them to the use cases.
// Views and view models get what they need from here, never by creating
// SwiftData or network objects themselves.
@Observable
final class AppContainer {
    // Repositories are added here as the Data layer is built.
}

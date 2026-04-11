import Foundation

enum AppError: LocalizedError, Equatable {
    // Persistence
    case persistenceSaveFailed(String)
    case persistenceFetchFailed(String)
    case entityNotFound(String)

    // Validation
    case validationFailed(String)
    case subjectNameEmpty
    case subjectNameDuplicate(String)
    case invalidDuration

    // Notifications
    case notificationPermissionDenied
    case notificationSchedulingFailed

    // Timer
    case timerAlreadyRunning
    case noSubjectSelected

    // Auth & Sync
    case authFailed(String)
    case syncFailed(String)

    // Groups
    case groupError(String)

    var errorDescription: String? {
        switch self {
        case .persistenceSaveFailed(let detail):
            "Failed to save data: \(detail)"
        case .persistenceFetchFailed(let detail):
            "Failed to load data: \(detail)"
        case .entityNotFound(let entity):
            "\(entity) not found"
        case .validationFailed(let detail):
            "Validation error: \(detail)"
        case .subjectNameEmpty:
            "Subject name cannot be empty"
        case .subjectNameDuplicate(let name):
            "A subject named \"\(name)\" already exists"
        case .invalidDuration:
            "Duration must be greater than zero"
        case .notificationPermissionDenied:
            "Notification permission is required for timer alerts. Please enable it in Settings."
        case .notificationSchedulingFailed:
            "Failed to schedule notification"
        case .timerAlreadyRunning:
            "A timer is already running. Stop it before starting a new one."
        case .noSubjectSelected:
            "Please select a subject before starting the timer"
        case .authFailed(let detail):
            "Authentication error: \(detail)"
        case .syncFailed(let detail):
            "Sync error: \(detail)"
        case .groupError(let detail):
            "Group error: \(detail)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notificationPermissionDenied:
            "Open Settings > StudyForge > Notifications and enable alerts."
        case .subjectNameDuplicate:
            "Choose a different name or edit the existing subject."
        default:
            nil
        }
    }
}

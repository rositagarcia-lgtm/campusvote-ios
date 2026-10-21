import Foundation

extension Notification.Name {
    /// La sesión del jurado ya no es válida. SessionStore vuelve al login.
    static let campusVoteSessionExpired = Notification.Name("campusvote.session.expired")
}

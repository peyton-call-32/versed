import Foundation

/// Whether the app follows the phone's light/dark setting or always uses one.
enum Appearance: String, CaseIterable, Identifiable, Sendable {
    case matchPhone
    case light
    case dark

    /// The `@AppStorage` key the reader's choice is saved under.
    static let storageKey = "appearance"

    var id: Self { self }

    var label: String {
        switch self {
        case .matchPhone: "Match Phone"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

import SwiftData
import SwiftUI

@main
struct VersedApp: App {
    /// Everything the app stores on the phone.
    static let storedModels: [any PersistentModel.Type] = [SavedVerse.self, ReadingPosition.self, ReadingDay.self]

    /// UI tests launch with this argument so each run starts fresh and never touches real data.
    static let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: Self.storedModels, inMemory: Self.isUITesting)
    }
}

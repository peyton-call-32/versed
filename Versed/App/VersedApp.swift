import SwiftData
import SwiftUI

@main
struct VersedApp: App {
    /// Everything the app stores on the phone.
    static let storedModels: [any PersistentModel.Type] = [SavedVerse.self, ReadingPosition.self, ReadingDay.self]

    /// UI tests launch with this argument so each run starts fresh and never touches real data.
    static let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")

    init() {
        // UI tests skip the first-time intro unless they launch with `-show-intro` to test it.
        if Self.isUITesting {
            let showsIntro = ProcessInfo.processInfo.arguments.contains("-show-intro")
            UserDefaults.standard.set(!showsIntro, forKey: IntroView.hasSeenKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: Self.storedModels, inMemory: Self.isUITesting)
    }
}

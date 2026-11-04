import SwiftData
import SwiftUI
import UIKit

@main
struct VersedApp: App {
    /// Everything the app stores on the phone.
    static let storedModels: [any PersistentModel.Type] = [SavedVerse.self, ReadingPosition.self, ReadingDay.self]

    /// UI tests launch with this argument so each run starts fresh and never touches real data.
    nonisolated static let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")

    /// Today's date for picking this week's reading. UI tests pass `-today yyyy-MM-dd` so they
    /// see the same week on every run instead of whatever week it really is.
    nonisolated static var today: Date {
        let arguments = ProcessInfo.processInfo.arguments
        guard isUITesting,
              let index = arguments.firstIndex(of: "-today"), arguments.indices.contains(index + 1),
              let date = try? Date(arguments[index + 1] + "T12:00:00Z", strategy: .iso8601)
        else { return .now }
        return date
    }

    init() {
        Self.useVersedScreenTitles()

        // UI tests skip the first-time intro unless they launch with `-show-intro` to test it.
        if Self.isUITesting {
            let showsIntro = ProcessInfo.processInfo.arguments.contains("-show-intro")
            UserDefaults.standard.set(!showsIntro, forKey: IntroView.hasSeenKey)
        }
    }

    /// Screen titles like "Browse" and "Saved" use the same typeface as the book names, in navy ink.
    /// A full appearance is set for each bar state, so iOS doesn't swap in its own title font
    /// when a bar changes state, such as after coming back from another screen.
    private static func useVersedScreenTitles() {
        let ink = UIColor(named: "AccentColor") ?? .label
        func titled(_ appearance: UINavigationBarAppearance) -> UINavigationBarAppearance {
            if let large = UIFont(name: Font.Bundled.title, size: 40) {
                appearance.largeTitleTextAttributes = [
                    .font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: large),
                    .foregroundColor: ink,
                ]
            }
            if let inline = UIFont(name: Font.Bundled.title, size: 21) {
                appearance.titleTextAttributes = [
                    .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: inline),
                    .foregroundColor: ink,
                ]
            }
            return appearance
        }

        let atTop = UINavigationBarAppearance()
        atTop.configureWithTransparentBackground()
        let scrolled = UINavigationBarAppearance()
        scrolled.configureWithDefaultBackground()

        let navigationBar = UINavigationBar.appearance()
        navigationBar.scrollEdgeAppearance = titled(atTop)
        navigationBar.standardAppearance = titled(scrolled)
        navigationBar.compactAppearance = titled(scrolled)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: Self.storedModels, inMemory: Self.isUITesting)
    }
}

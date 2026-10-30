import SwiftData
import SwiftUI

@main
struct VersedApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: SavedVerse.self)
    }
}

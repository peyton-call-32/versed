import SwiftUI

/// A feed pushed onto a tab's stack, with the chapter menu in its top bar and a back arrow.
struct PagedReadingView: View {
    let library: ScriptureLibrary
    let items: [FeedItem]
    var startingAt: FeedItem.ID? = nil
    var showsFirstPageOnResume = false
    var menuOptions: ChapterMenu.Options? = nil
    var closingActions = ReadingClosingCard.Actions()
    let onPageChange: (FeedItem.ID) -> Void

    @Environment(ReadingChrome.self) private var chrome
    @State private var navigation = FeedNavigation()

    var body: some View {
        FeedView(
            items: items,
            startingAt: startingAt,
            showsFirstPageOnResume: showsFirstPageOnResume,
            navigation: navigation,
            closingActions: closingActions,
            onPageChange: onPageChange
        )
        .toolbar {
            PlainToolbarItem(placement: .principal) {
                // A chapter opening already says where the reader is, so its menu waits for a tap.
                let hidesMenu = chrome.isOnCover && chrome.hidesControls
                ChapterMenu(library: library, items: items, navigation: navigation, options: menuOptions, isOnCover: chrome.isOnCover)
                    .opacity(hidesMenu ? 0 : 1)
                    .allowsHitTesting(!hidesMenu)
                    .accessibilityHidden(hidesMenu)
            }
        }
        // Keeps the back button readable: cream on a navy chapter opening.
        .versedBackButton(color: chrome.isOnCover ? .onCover : .brand)
        // The menu and title cards already say where the reader is, so the bar has no title.
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

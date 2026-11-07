import SwiftUI

/// The words at the top of a feed. They say where the reader is, and open a sheet for moving
/// to another chapter, back to the start of the reading, or to another week.
struct ChapterMenu: View {
    /// What the sheet offers in a reading with opening and closing cards, which a whole book's feed doesn't have.
    struct Options {
        /// What VoiceOver says for the menu on the opening and closing cards, such as "Week of Nov 2–8".
        let spokenPlace: String
        /// "Back to Week's Start" or "Back to Reading's Start".
        var backToStartTitle = "Back to Week's Start"
        /// The weekly schedule and what to do with a week picked from it, if "Other Weeks" should show.
        var otherWeeks: OtherWeeks? = nil
        /// Opens the plan's details, if this reading belongs to a plan.
        var planDetails: (() -> Void)? = nil
    }

    struct OtherWeeks {
        let schedule: ReadingSchedule
        let open: (ReadingWeek.ID) -> Void
    }

    let library: ScriptureLibrary
    let items: [FeedItem]
    let navigation: FeedNavigation
    var options: Options? = nil
    /// Whether the menu sits on a navy chapter opening, so it needs cream type.
    var isOnCover = false

    @State private var showsSheet = false

    private var currentChapter: ChapterID? {
        navigation.visibleItemID.flatMap(FeedItem.chapterID(of:))
    }

    /// "Ezekiel 2", or nil on a week's opening and closing cards.
    private var reference: String? {
        currentChapter.flatMap { chapter in
            library.book(id: chapter.bookID)?.reference(chapter: chapter.chapter)
        }
    }

    var body: some View {
        Button {
            showsSheet = true
        } label: {
            HStack(spacing: 6) {
                // A week's opening and closing cards already show its dates, so the menu just says what it does.
                Text(reference ?? "Chapters")
                    .font(.versedDetail)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .contentTransition(.opacity)
                GlyphView(.chevronDown, size: 9)
            }
            .foregroundStyle(isOnCover ? Color.onCover : Color.brand)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.2), value: reference)
        }
        .buttonStyle(ChapterMenuButtonStyle())
        .accessibilityLabel(reference ?? options?.spokenPlace ?? "Chapters")
        .accessibilityHint("Moves to another chapter.")
        .accessibilityIdentifier("Chapter menu")
        .sheet(isPresented: $showsSheet) {
            ChapterMenuSheet(
                groups: library.chapterGroups(in: items),
                currentChapter: currentChapter,
                showsBackToStart: options != nil && navigation.visibleItemID != items.first?.id,
                navigation: navigation,
                options: options
            )
            .versedSheet()
        }
    }
}

private struct ChapterMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .pressEffect(configuration.isPressed)
    }
}

private struct ChapterMenuSheet: View {
    let groups: [ChapterGroup]
    let currentChapter: ChapterID?
    let showsBackToStart: Bool
    let navigation: FeedNavigation
    let options: ChapterMenu.Options?

    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: Hardcover.sectionSpacing) {
                        if showsBackToStart {
                            Ledger {
                                Button {
                                    navigation.goToStart()
                                    dismiss()
                                } label: {
                                    LedgerRowLabel(title: options?.backToStartTitle ?? "Back to Start", symbol: .arrowUp)
                                }
                                .buttonStyle(.ledgerRow)
                            }
                        }
                        ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                            VStack(alignment: .leading, spacing: 10) {
                                SmallCapsLabel(group.book.name)
                                    .accessibilityAddTraits(.isHeader)
                                chapterGrid(for: group)
                            }
                        }
                        if options?.otherWeeks != nil || options?.planDetails != nil {
                            moreOptions
                        }
                    }
                    .versedPage()
                }
                .versedScreen()
                .onAppear {
                    // A long book opens at the current chapter. A reading's few chapters stay
                    // at the top, so "Back to Week's Start" doesn't slide under the title bar.
                    if options == nil, let currentChapter {
                        proxy.scrollTo(currentChapter, anchor: .center)
                    }
                }
            }
            .navigationTitle("Go To")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DoneToolbarItem { dismiss() }
            }
        }
    }

    private var moreOptions: some View {
        Ledger {
            if let otherWeeks = options?.otherWeeks {
                NavigationLink {
                    ReadingScheduleView(schedule: otherWeeks.schedule) { weekID in
                        dismiss()
                        otherWeeks.open(weekID)
                    }
                } label: {
                    LedgerRowLabel(title: "Other Weeks")
                }
                .buttonStyle(.ledgerRow)
            }
            if let planDetails = options?.planDetails {
                Button {
                    dismiss()
                    planDetails()
                } label: {
                    LedgerRowLabel(title: "Plan Details")
                }
                .buttonStyle(.ledgerRow)
            }
        }
    }

    private func chapterGrid(for group: ChapterGroup) -> some View {
        ChapterGrid(chapters: group.chapters) { chapter in
            let id = ChapterID(bookID: group.book.id, chapter: chapter)
            let isCurrent = id == currentChapter
            Button {
                navigation.go(to: id)
                dismiss()
            } label: {
                ChapterCellLabel(chapter: chapter, isCurrent: isCurrent)
            }
            .buttonStyle(ChapterCellButtonStyle())
            .accessibilityLabel(group.book.reference(chapter: chapter))
            .accessibilityAddTraits(isCurrent ? .isSelected : [])
            .id(id)
        }
    }
}

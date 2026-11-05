import SwiftUI

/// The words at the top of a feed. They say where the reader is, and open a sheet for moving
/// to another chapter, back to the start of the week, or to another week.
struct ChapterMenu: View {
    /// What the sheet offers in a week's feed, which Browse's feed doesn't have.
    struct WeekOptions {
        let schedule: ReadingSchedule
        /// The week's dates, shown in VoiceOver on pages outside any chapter.
        let dates: String
        /// Shows a week on the This Week tab: `nil` for this week, or any week from the schedule.
        let openWeek: (ReadingWeek.ID?) -> Void
    }

    let library: ScriptureLibrary
    let items: [FeedItem]
    let navigation: FeedNavigation
    var weekOptions: WeekOptions? = nil
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
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .regular))
            }
            .foregroundStyle(isOnCover ? Color.onCover : Color.brand)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.2), value: reference)
        }
        .buttonStyle(ChapterMenuButtonStyle())
        .accessibilityLabel(reference ?? "Week of \(weekOptions?.dates ?? "")")
        .accessibilityHint("Moves to another chapter.")
        .accessibilityIdentifier("Chapter menu")
        .sheet(isPresented: $showsSheet) {
            ChapterMenuSheet(
                groups: library.chapterGroups(in: items),
                currentChapter: currentChapter,
                showsBackToStart: weekOptions != nil && navigation.visibleItemID != items.first?.id,
                navigation: navigation,
                weekOptions: weekOptions
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
    let weekOptions: ChapterMenu.WeekOptions?

    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 22) {
                        if showsBackToStart {
                            Ledger {
                                Button {
                                    navigation.goToStart()
                                    dismiss()
                                } label: {
                                    LedgerRowLabel(title: "Back to Week's Start", symbol: "arrow.up")
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
                        if let weekOptions {
                            Ledger {
                                NavigationLink {
                                    ReadingScheduleView(schedule: weekOptions.schedule) { weekID in
                                        weekOptions.openWeek(weekID)
                                        dismiss()
                                    }
                                } label: {
                                    LedgerRowLabel(title: "Other Weeks")
                                }
                                .buttonStyle(.ledgerRow)
                            }
                        }
                    }
                    .versedPage()
                }
                .versedScreen()
                .onAppear {
                    // A long book opens at the current chapter. A week's few chapters stay
                    // at the top, so "Back to Week's Start" doesn't slide under the title bar.
                    if weekOptions == nil, let currentChapter {
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
            .buttonStyle(.ledgerRow)
            .accessibilityLabel(group.book.reference(chapter: chapter))
            .accessibilityAddTraits(isCurrent ? .isSelected : [])
            .id(id)
        }
    }
}

import SwiftUI

/// The pill at the top of a feed. It says where the reader is, and opens a sheet for moving
/// to another chapter, back to the start of the week, or to another week.
struct ChapterMenu: View {
    /// What the sheet offers in a week's feed, which Browse's feed doesn't have.
    struct WeekOptions {
        let schedule: ReadingSchedule
        /// The week's dates, which the pill shows on pages outside any chapter.
        let dates: String
        /// Shows a week on the This Week tab: `nil` for this week, or any week from the schedule.
        let openWeek: (ReadingWeek.ID?) -> Void
    }

    let library: ScriptureLibrary
    let items: [FeedItem]
    let navigation: FeedNavigation
    var weekOptions: WeekOptions? = nil

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
                Text(reference ?? weekOptions?.dates ?? "")
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Image(systemName: "chevron.down")
                    .imageScale(.small)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.brand)
            .padding(.horizontal, 15)
            .frame(minHeight: 44)
            .pillBackground()
        }
        .buttonStyle(.plain)
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
        }
    }
}

private struct ChapterMenuSheet: View {
    let groups: [ChapterGroup]
    let currentChapter: ChapterID?
    let showsBackToStart: Bool
    let navigation: FeedNavigation
    let weekOptions: ChapterMenu.WeekOptions?

    @Environment(\.dismiss) private var dismiss
    /// Grows with the reader's text size so big chapter numbers still fit.
    @ScaledMetric(relativeTo: .body) private var cellSize = 46.0

    private var columns: [GridItem] { [GridItem(.adaptive(minimum: cellSize), spacing: 8)] }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 22) {
                        if showsBackToStart {
                            Card {
                                Button {
                                    navigation.goToStart()
                                    dismiss()
                                } label: {
                                    CardRowLabel(title: "Back to Week's Start", symbol: "arrow.up")
                                }
                                .buttonStyle(.cardRow)
                            }
                        }
                        ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                            CardSection(title: group.book.name) {
                                chapterGrid(for: group)
                            }
                        }
                        if let weekOptions {
                            Card {
                                NavigationLink {
                                    ReadingScheduleView(schedule: weekOptions.schedule) { weekID in
                                        weekOptions.openWeek(weekID)
                                        dismiss()
                                    }
                                } label: {
                                    CardRowLabel(title: "Other Weeks")
                                }
                                .buttonStyle(.cardRow)
                            }
                        }
                    }
                    .versedPage()
                }
                .background(Color.appBackground)
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func chapterGrid(for group: ChapterGroup) -> some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(group.chapters, id: \.self) { chapter in
                let id = ChapterID(bookID: group.book.id, chapter: chapter)
                let isCurrent = id == currentChapter
                Button("\(chapter)") {
                    navigation.go(to: id)
                    dismiss()
                }
                .buttonStyle(.chapterCell(isCurrent: isCurrent))
                .frame(minHeight: cellSize)
                .accessibilityLabel(group.book.reference(chapter: chapter))
                .accessibilityAddTraits(isCurrent ? .isSelected : [])
                .id(id)
            }
        }
        .padding(12)
    }
}

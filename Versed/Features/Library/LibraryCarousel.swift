import SwiftUI

/// The books in the reader's library as covers facing them. Swiping, or tapping a neighbor, brings
/// a book to the middle, and the Library tab lists what's inside it underneath.
struct LibraryCarousel: View {
    /// The book in the middle is saved on the phone, so the Library reopens on it.
    static let storageKey = "library.openBook"

    let books: [LibraryBook]
    @Binding var selection: String

    @ScaledMetric(relativeTo: .title) private var scaledWidth = 150.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let spacing: CGFloat = 16
    /// Room around the covers for their shadow, which a scrolling row would otherwise cut off.
    private static let shadowRoom: CGFloat = 22
    private static let neighborScale: CGFloat = 0.9
    /// Covers grow with the reader's text size, but always leave room to see the next one.
    private static let largestWidth: CGFloat = 220

    private var coverWidth: CGFloat { min(scaledWidth, Self.largestWidth) }
    private var coverHeight: CGFloat { coverWidth * 1.41 }

    var body: some View {
        VStack(spacing: 2) {
            GeometryReader { space in
                ScrollView(.horizontal) {
                    HStack(spacing: Self.spacing) {
                        ForEach(books) { book in
                            cover(for: book, pageCenter: space.size.width / 2)
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, max((space.size.width - coverWidth) / 2, 0), for: .scrollContent)
                .contentMargins(.vertical, Self.shadowRoom, for: .scrollContent)
                .scrollPosition(id: scrollSelection, anchor: .center)
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
            }
            .frame(height: coverHeight + Self.shadowRoom * 2)
            .accessibilityIdentifier("Library Covers")
            pageMarks
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    /// iOS clears the scroll position while a swipe is between covers, so the last one stays selected.
    private var scrollSelection: Binding<String?> {
        Binding(
            get: { selection },
            set: { if let id = $0 { selection = id } }
        )
    }

    private func cover(for book: LibraryBook, pageCenter: CGFloat) -> some View {
        let isSelected = book.id == selection
        return Button {
            guard !isSelected else { return }
            withAnimation(reduceMotion ? nil : .versed) { selection = book.id }
        } label: {
            BookCover(book: book)
                .frame(width: coverWidth, height: coverHeight)
        }
        .buttonStyle(CoverButtonStyle())
        // Covers shrink a little as they leave the middle, following the finger.
        .visualEffect { [coverWidth] content, proxy in
            // Measured on the whole screen, because the scroll view's own measure leaves out its margins.
            let distance = abs(proxy.frame(in: .global).midX - pageCenter)
            let progress = min(distance / (coverWidth + Self.spacing), 1)
            return content.scaleEffect(1 - (1 - Self.neighborScale) * progress)
        }
        .accessibilityLabel(book.fullName)
        .accessibilityHint(isSelected ? "" : "Shows what's inside.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("Cover \(book.title)")
    }

    /// A short line for each book. The open one is longer and in solid ink, and grows as it's reached.
    private var pageMarks: some View {
        HStack(spacing: 5) {
            ForEach(books) { book in
                let isSelected = book.id == selection
                SwelledRuleShape()
                    .fill(isSelected ? Color.brand : Color.secondaryText.opacity(0.6))
                    .frame(width: isSelected ? 26 : 12, height: isSelected ? 2.4 : 1.6)
                    .frame(height: 3)
            }
        }
        .animation(reduceMotion ? nil : .versed, value: selection)
        .accessibilityHidden(true)
    }
}

/// One book's front cover, made like the real thing: navy cloth with a groove along the hinge,
/// a stamped frame, a pressed-in title, and the page block just showing past its edge.
private struct BookCover: View {
    let book: LibraryBook

    /// Where the hinge's groove runs, in from the spine.
    private static let hinge: CGFloat = 10

    var body: some View {
        ZStack {
            CoverFrame(notch: 7)
                .padding(.vertical, 9)
                .padding(.leading, Self.hinge + 7)
                .padding(.trailing, 9)
            VStack(spacing: 11) {
                // A second line under the title leaves less room, so the title steps down to keep to two lines.
                Text(book.title)
                    .font(.versedTitle(size: book.subtitle == nil ? 30 : 27, relativeTo: .title))
                    .foregroundStyle(.onCover)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                    .stampedIntoCloth()
                Ornament(color: .onCover, lineLength: 15)
                if let subtitle = book.subtitle {
                    Text(subtitle)
                        .font(.versedNote)
                        .foregroundStyle(.onCover)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(.leading, Self.hinge + 13)
            .padding(.trailing, 14)
            .padding(.vertical, 20)
        }
        .background { ClothSurface().clipShape(Hardcover.corner) }
        .overlay(alignment: .leading) { hingeGroove }
        // Edged with a fine line so the cover still stands out on the navy page in dark mode.
        .overlay(Hardcover.corner.strokeBorder(Color.onCover.opacity(0.14), lineWidth: 0.5))
        .background {
            // The pages, just showing past the cover's lower right edge.
            Rectangle()
                .fill(Color.onCover)
                .overlay { Rectangle().strokeBorder(Color.black.opacity(0.14), lineWidth: 0.5) }
                .offset(x: 2, y: 2)
                .padding(.vertical, 2)
                .padding(.leading, Self.hinge)
        }
        .restingShadow()
    }

    private var hingeGroove: some View {
        HStack(spacing: 0) {
            Color.black.opacity(0.1).frame(width: Self.hinge)
            Color.black.opacity(0.32).frame(width: 1)
            Color.white.opacity(0.09).frame(width: 0.75)
        }
        .clipShape(Hardcover.corner)
        .allowsHitTesting(false)
    }
}

private struct CoverButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .pressEffect(configuration.isPressed)
    }
}

/// The books in the volume on show, or its sections when it's a single book like the
/// Doctrine and Covenants, with the way to make a plan for it underneath.
struct VolumeContents: View {
    let volume: Volume
    let startVolumePlan: () -> Void
    let startBookPlan: (Book) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    private var singleBook: Book? { volume.books.count == 1 ? volume.books.first : nil }

    var body: some View {
        VStack(alignment: .leading, spacing: Hardcover.sectionSpacing) {
            if let singleBook {
                sections(of: singleBook)
            } else {
                books
            }
            Ledger {
                if let singleBook {
                    Button { startBookPlan(singleBook) } label: {
                        LedgerRowLabel(title: "Make a Plan for This Book")
                    }
                    .buttonStyle(.ledgerRow)
                } else {
                    Button(action: startVolumePlan) {
                        LedgerRowLabel(title: "Make a Plan for All \(volume.books.count) Books")
                    }
                    .buttonStyle(.ledgerRow)
                }
            }
        }
    }

    private var books: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SmallCapsLabel("\(volume.books.count) Books")
                // At the largest text sizes there's only room for one label without breaking a word.
                if !typeSize.isAccessibilitySize {
                    Spacer(minLength: 8)
                    SmallCapsLabel("Chapters")
                }
            }
            .padding(.bottom, 8)
            .accessibilityElement(children: .combine)
            Rule()
                .padding(.bottom, 4)
            ForEach(volume.books) { book in
                NavigationLink(value: route(for: book)) {
                    BookRow(book: book)
                }
                .buttonStyle(.ledgerRow)
            }
        }
    }

    private func sections(of book: Book) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SmallCapsLabel("\(book.chapterCount) \(book.chapterWord)s")
            ChapterGrid(chapters: Array(1...book.chapterCount)) { chapter in
                NavigationLink(value: LibraryView.Route.reading(ChapterID(bookID: book.id, chapter: chapter))) {
                    ChapterCellLabel(chapter: chapter)
                }
                .buttonStyle(ChapterCellButtonStyle())
                .accessibilityLabel(book.reference(chapter: chapter))
            }
        }
    }

    /// A book with one chapter (like Enos) opens straight to its reading.
    private func route(for book: Book) -> LibraryView.Route {
        book.chapterCount == 1
            ? .reading(ChapterID(bookID: book.id, chapter: 1))
            : .book(book.id)
    }
}

/// A book's name, with dots leading to how many chapters it has, like a table of contents.
private struct BookRow: View {
    let book: Book

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(book.name)
                .font(.versedRow)
                .foregroundStyle(.brand)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            LeaderDots().alignmentGuide(.firstTextBaseline) { $0[.bottom] }
            Text("\(book.chapterCount)")
                .font(.versedNumber(size: 22, relativeTo: .body))
                .foregroundStyle(.secondaryText)
        }
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(book.name)
        .accessibilityValue("\(book.chapterCount)")
    }
}

/// A year of the weekly schedule: this week first when it's in that year, then every week,
/// each opening its reading with no plan needed.
struct CourseContents: View {
    let schedule: ReadingSchedule
    let course: String
    let openWeek: (ReadingWeek.ID) -> Void

    private var weeks: [ReadingWeek] { schedule.weeks.filter { $0.course == course } }

    var body: some View {
        let weeks = weeks
        VStack(alignment: .leading, spacing: Hardcover.sectionSpacing) {
            if let thisWeek = schedule.currentWeek(), thisWeek.course == course {
                VStack(alignment: .leading, spacing: 8) {
                    SmallCapsLabel("This Week")
                    WeekRow(week: thisWeek, isThisWeek: true) { openWeek(thisWeek.id) }
                }
            }
            LedgerSection(title: "\(weeks.count) Weeks") {
                ForEach(weeks) { week in
                    WeekRow(week: week, isThisWeek: false) { openWeek(week.id) }
                }
            }
            Text(WeeklyPlanName.notice)
                .font(.versedNote)
                .foregroundStyle(.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

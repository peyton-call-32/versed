import SwiftData
import SwiftUI

/// Opens to this week's reading. A header row sits on top: the streak on the left, a menu to
/// pick another week in the middle, and Settings on the right.
///
/// Each week opens on its opening card. Swiping up goes to the page where the reader left off,
/// or to the start once the week has been read to its closing card.
struct WeeklyReadingView: View {
    let library: ScriptureLibrary
    let schedule: ReadingSchedule

    @Environment(\.modelContext) private var modelContext
    @State private var showsSettings = false

    /// The week picked from the menu or the schedule in Browse, or `nil` to show this week.
    @Binding var selectedWeekID: ReadingWeek.ID?

    private var thisWeek: ReadingWeek? { schedule.currentWeek() }

    private var selectedWeek: ReadingWeek? {
        schedule.weeks.first { $0.id == selectedWeekID } ?? thisWeek
    }

    var body: some View {
        if let week = selectedWeek {
            let positions = ReadingPositionStore(context: modelContext)
            FeedView(
                items: [.weekIntro(week)] + library.feedItems(for: week.passages) + [.weekEnd(week)],
                startingAt: positions.position(in: .week(week.id)),
                showsFirstPageOnResume: true,
                onPageChange: { itemID in
                    // Reaching the closing card finishes the week, so next time it starts over.
                    if itemID == FeedItem.weekEnd(week).id {
                        positions.clearPosition(in: .week(week.id))
                    } else {
                        positions.setPosition(itemID, in: .week(week.id))
                    }
                }
            )
            // A new identity per week reopens each week's feed at its own saved page.
            .id(week.id)
            .overlay(alignment: .top) {
                header(selected: week)
            }
            .sheet(isPresented: $showsSettings) {
                SettingsView()
            }
        } else {
            ContentUnavailableView("No reading schedule", systemImage: "calendar")
        }
    }

    /// The streak, the week menu, and Settings in one row. The menu stays centered even when
    /// the streak is hidden; see `HeaderRowLayout`.
    private func header(selected: ReadingWeek) -> some View {
        HeaderRowLayout {
            StreakBadge()
                .headerRowSlot(.leading)
            weekMenu(selected: selected)
                .headerRowSlot(.middle)
            SettingsButton { showsSettings = true }
                .headerRowSlot(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func weekMenu(selected: ReadingWeek) -> some View {
        Menu {
            ForEach(schedule.weeks) { week in
                Button {
                    selectedWeekID = week.id
                } label: {
                    let dates = week.id == thisWeek?.id ? "\(week.dateRangeText()) · This week" : week.dateRangeText()
                    if week.id == selected.id {
                        Label(dates, systemImage: "checkmark")
                    } else {
                        Text(dates)
                    }
                    Text(week.displayLabel)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selected.dateRangeText())
                Image(systemName: "chevron.down")
                    .imageScale(.small)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .pillBackground()
        }
        // Plain ink, not the accent color, so the pill stays quiet like the streak badge.
        .tint(.primary)
        .accessibilityLabel("Week of \(selected.dateRangeText())")
        .accessibilityHint("Picks another week's reading.")
    }
}

/// The gear at the right of the header. It's its own view so its size follows the header's
/// text size cap; a size worked out in `WeeklyReadingView` itself would ignore the cap.
private struct SettingsButton: View {
    let action: () -> Void

    /// Matches the height of the week and streak pills as text grows.
    @ScaledMetric(relativeTo: .subheadline) private var size = 36.0

    var body: some View {
        Button(action: action) {
            Label("Settings", systemImage: "gearshape")
                .labelStyle(.iconOnly)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: size, height: size)
                .pillBackground()
                // A slightly bigger tap area than the circle, so it's easy to hit.
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Lays out up to three items in a row: one on the left, one centered, one on the right.
/// Each item says where it goes with `.headerRowSlot(_:)`.
///
/// The middle item is centered on the screen, not just between its neighbors, so it doesn't
/// shift when the left item is hidden (a hidden view isn't in the row at all). At large text sizes,
/// when there isn't room to center it, it slides over just enough to clear its neighbors.
private struct HeaderRowLayout: Layout {
    enum Slot {
        case leading, middle, trailing
    }

    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let naturalWidth = sizes.map(\.width).reduce(0, +) + spacing * CGFloat(max(sizes.count - 1, 0))
        return CGSize(width: proposal.width ?? naturalWidth, height: sizes.map(\.height).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let leading = subviews.first { $0[HeaderRowSlotKey.self] == .leading }
        let middle = subviews.first { $0[HeaderRowSlotKey.self] == .middle }
        let trailing = subviews.first { $0[HeaderRowSlotKey.self] == .trailing }

        // The room between the side items, leaving a gap next to any item that's showing.
        let leadingWidth = leading.map { $0.sizeThatFits(.unspecified).width + spacing } ?? 0
        let trailingWidth = trailing.map { $0.sizeThatFits(.unspecified).width + spacing } ?? 0
        let minX = bounds.minX + leadingWidth
        let maxX = bounds.maxX - trailingWidth

        leading?.place(at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading, proposal: .unspecified)
        trailing?.place(at: CGPoint(x: bounds.maxX, y: bounds.midY), anchor: .trailing, proposal: .unspecified)
        if let middle {
            let width = min(middle.sizeThatFits(.unspecified).width, maxX - minX)
            let x = min(max(bounds.midX - width / 2, minX), maxX - width)
            middle.place(at: CGPoint(x: x, y: bounds.midY), anchor: .leading, proposal: ProposedViewSize(width: width, height: nil))
        }
    }
}

private struct HeaderRowSlotKey: LayoutValueKey {
    static let defaultValue = HeaderRowLayout.Slot.middle
}

private extension View {
    /// Where this view sits in a `HeaderRowLayout`.
    func headerRowSlot(_ slot: HeaderRowLayout.Slot) -> some View {
        layoutValue(key: HeaderRowSlotKey.self, value: slot)
    }
}

#Preview {
    @Previewable @State var selectedWeekID: ReadingWeek.ID?
    WeeklyReadingView(library: try! ScriptureLibrary.loadBundled(), schedule: try! ReadingSchedule.loadBundled(), selectedWeekID: $selectedWeekID)
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}

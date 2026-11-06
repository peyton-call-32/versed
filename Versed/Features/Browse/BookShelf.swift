import SwiftUI

/// Which of the five volumes are on the reader's shelf, saved on the phone as their IDs in order.
/// New readers start with the two testaments and add the others from "Your Shelf".
enum Shelf {
    static let storageKey = "shelf.volumes"
    static let starting = "ot,nt"

    static func volumeIDs(from stored: String) -> [Volume.ID] {
        stored.split(separator: ",").map(String.init)
    }

    /// Adds or removes a volume, keeping the books in their canonical order.
    static func toggling(_ id: Volume.ID, in stored: String) -> String {
        var ids = Set(volumeIDs(from: stored))
        if !ids.insert(id).inserted { ids.remove(id) }
        return ScriptureLibrary.volumeIDs.filter(ids.contains).joined(separator: ",")
    }
}

/// The reader's volumes standing on a shelf, sized a little differently like real books.
/// Tapping a spine opens that volume. A dashed gap at the end adds another.
struct BookShelf: View {
    let volumes: [Volume]
    let onOpen: (Volume) -> Void
    let onAdd: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How wide and how tall each book stands, as parts of the shelf.
    private static let sizes: [Volume.ID: (width: CGFloat, height: CGFloat)] = [
        "ot": (76, 1), "nt": (64, 0.93), "bofm": (72, 0.965), "dc": (66, 0.9), "pgp": (52, 0.83),
    ]
    private static let gap: CGFloat = 2
    private static let slotWidth: CGFloat = 52
    private static let slotGap: CGFloat = 10

    private var hasRoom: Bool { volumes.count < ScriptureLibrary.volumeIDs.count }

    var body: some View {
        GeometryReader { space in
            let scale = widthScale(available: space.size.width)
            HStack(alignment: .bottom, spacing: Self.gap) {
                ForEach(volumes) { volume in
                    let size = Self.sizes[volume.id] ?? (64, 0.9)
                    Button {
                        onOpen(volume)
                    } label: {
                        BookSpine(title: volume.title)
                            .frame(width: size.width * scale, height: space.size.height * size.height)
                    }
                    .buttonStyle(SpineButtonStyle())
                    .accessibilityLabel(volume.title)
                    .accessibilityHint("Opens this book.")
                    .accessibilityIdentifier("Spine \(volume.title)")
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .move(edge: .bottom),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                }
                if hasRoom {
                    Button(action: onAdd) {
                        EmptySlot()
                            .frame(width: Self.slotWidth * scale, height: space.size.height * 0.83)
                    }
                    .buttonStyle(.ledgerRow)
                    .padding(.leading, volumes.isEmpty ? 0 : Self.slotGap - Self.gap)
                    .accessibilityLabel("Add a Book")
                }
                Spacer(minLength: 0)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .animation(reduceMotion ? nil : .versed, value: volumes.map(\.id))
        }
    }

    /// Books keep their proportions but narrow together when all of them plus the gap wouldn't fit.
    private func widthScale(available: CGFloat) -> CGFloat {
        let books = volumes.reduce(CGFloat.zero) { $0 + (Self.sizes[$1.id]?.width ?? 64) }
        let gaps = CGFloat(max(volumes.count - 1, 0)) * Self.gap
        let slot = hasRoom ? Self.slotWidth + Self.slotGap : 0
        return min(1.05, (available - gaps - slot) / max(books, 1))
    }
}

/// One book seen from its spine: raised bands at the head and foot, and the title reading downward.
private struct BookSpine: View {
    let title: String

    var body: some View {
        GeometryReader { space in
            ZStack {
                UnevenRoundedRectangle(topLeadingRadius: 2, topTrailingRadius: 2, style: .continuous)
                    .fill(.cover)
                VStack(spacing: 0) {
                    bands.padding(.top, 22)
                    Spacer()
                    bands.padding(.bottom, 22)
                }
                Text(title)
                    .font(.custom(Font.Bundled.title, fixedSize: 25))
                    .foregroundStyle(.onCover)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    // Set for the spine's length before turning, so long names shrink instead of cutting off.
                    .frame(width: max(space.size.height - 76, 40))
                    .rotationEffect(.degrees(90))
                    .frame(width: space.size.width, height: space.size.height)
            }
        }
    }

    private var bands: some View {
        VStack(spacing: 3) {
            Rule(color: Color.onCover.opacity(0.75))
            Rule(color: Color.onCover.opacity(0.75))
        }
    }
}

/// The gap on the shelf where another book can go.
private struct EmptySlot: View {
    var body: some View {
        ZStack {
            UnevenRoundedRectangle(topLeadingRadius: 2, topTrailingRadius: 2, style: .continuous)
                .strokeBorder(Color.brand.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            VStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .light))
                Text("Add a Book")
                    .font(.custom(Font.Bundled.title, fixedSize: 21))
                    .lineLimit(1)
                    .fixedSize()
                    .rotationEffect(.degrees(90))
                    .frame(width: 24, height: 110)
            }
            .foregroundStyle(.brand)
        }
        .contentShape(Rectangle())
    }
}

/// A book rises from the shelf under the finger, like starting to pull it out.
private struct SpineButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed && !reduceMotion ? -12 : 0)
            .opacity(configuration.isPressed && reduceMotion ? 0.7 : 1)
            .animation(.spring(duration: 0.3, bounce: 0.25), value: configuration.isPressed)
    }
}

/// Adds and removes books from the shelf.
struct ShelfEditorView: View {
    let volumes: [Volume]
    @Binding var stored: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Removing a book never erases your progress or saved verses.")
                        .font(.versedNote)
                        .foregroundStyle(.secondaryText)
                    Ledger {
                        ForEach(volumes) { volume in
                            if volume.id != volumes.first?.id { LedgerRule() }
                            row(for: volume)
                        }
                    }
                }
                .versedPage()
            }
            .versedScreen()
            .navigationTitle("Your Shelf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DoneToolbarItem { dismiss() }
            }
        }
        // Just tall enough for all five books, so the shelf stays in view above as it changes.
        .presentationDetents([typeSize.isAccessibilitySize ? .large : .height(460)])
        .presentationBackground(Color.appBackground)
        .presentationDragIndicator(.hidden)
    }

    private func row(for volume: Volume) -> some View {
        let isOnShelf = Shelf.volumeIDs(from: stored).contains(volume.id)
        // Stacked at the largest text sizes, so a long name never breaks in the middle of a word.
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout())
        return layout {
            Text(volume.title)
                .font(.versedRow)
                .foregroundStyle(.brand)
                .fixedSize(horizontal: false, vertical: true)
            if !typeSize.isAccessibilitySize { Spacer(minLength: 8) }
            if isOnShelf {
                Button("Remove") { stored = Shelf.toggling(volume.id, in: stored) }
                    .buttonStyle(.plainWord)
                    .accessibilityLabel("Remove \(volume.title)")
            } else {
                Button("+ Add") { stored = Shelf.toggling(volume.id, in: stored) }
                    .buttonStyle(ShelfAddButtonStyle())
                    .accessibilityLabel("Add \(volume.title)")
            }
        }
        .padding(.vertical, typeSize.isAccessibilitySize ? 10 : 0)
        .frame(minHeight: 60)
    }
}

/// The small solid button for putting a book on the shelf.
private struct ShelfAddButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.versedDetail)
            .foregroundStyle(Color("ProminentButtonLabel"))
            .frame(minWidth: 72, minHeight: 40)
            .background(Color("ProminentButton"), in: Hardcover.corner)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .pressEffect(configuration.isPressed)
    }
}

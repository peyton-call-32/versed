import SwiftUI

/// Chooses what a new plan will read: a whole volume, or one book inside it.
struct PlanPickerView: View {
    let engine: PlanEngine
    let onPick: (PlanSource) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                Ledger {
                    Button {
                        onPick(.weeklySchedule(course: nil))
                    } label: {
                        LedgerRowLabel(title: WeeklyPlanName.title, detail: "Weekly schedule")
                    }
                    .buttonStyle(.ledgerRow)
                    ForEach(engine.library.volumes) { volume in
                        if volume.books.count == 1 {
                            pickRow(title: volume.title, source: .volume(volume.id))
                        } else {
                            NavigationLink {
                                books(of: volume)
                            } label: {
                                LedgerRowLabel(title: volume.title)
                            }
                            .buttonStyle(.ledgerRow)
                            // Tells this row apart from the cover of the same name behind the sheet.
                            .accessibilityIdentifier("Pick \(volume.title)")
                        }
                    }
                }
                Text(WeeklyPlanName.notice)
                    .font(.versedNote)
                    .foregroundStyle(.secondaryText)
                }
                .versedPage()
            }
            .versedScreen()
            .navigationTitle("Choose What to Read")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DoneToolbarItem(title: "Cancel") { dismiss() }
            }
        }
    }

    private func books(of volume: Volume) -> some View {
        ScrollView {
            Ledger {
                pickRow(title: "All of the \(volume.title)", source: .volume(volume.id))
                ForEach(volume.books) { book in
                    pickRow(title: book.name, source: .book(book.id))
                }
            }
            .versedPage()
        }
        .versedScreen()
        .navigationTitle(volume.title)
        .navigationBarTitleDisplayMode(.inline)
        .versedBackButton()
    }

    private func pickRow(title: String, source: PlanSource) -> some View {
        Button {
            onPick(source)
        } label: {
            LedgerRowLabel(title: title)
        }
        .buttonStyle(.ledgerRow)
    }
}

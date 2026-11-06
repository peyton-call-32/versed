import SwiftData
import SwiftUI

/// Sets the order of the plans on Today by dragging the handle on the right of each one.
struct ReorderPlansView: View {
    let engine: PlanEngine

    @Query(sort: \ReadingPlan.createdAt) private var plans: [ReadingPlan]
    @Environment(\.modelContext) private var modelContext

    private var ordered: [ReadingPlan] { plans.sorted(by: ReadingPlan.comesFirst) }

    var body: some View {
        List {
            Section {
                ForEach(ordered) { plan in
                    Text(engine.title(of: plan.state.source))
                        .font(.versedTitle(size: 28, relativeTo: .title2))
                        .foregroundStyle(.brand)
                        .frame(minHeight: 52)
                        .listRowBackground(Color.appBackground)
                        .listRowSeparatorTint(.hairline)
                        .listRowInsets(EdgeInsets(top: 0, leading: Hardcover.margin, bottom: 0, trailing: Hardcover.margin))
                }
                .onMove(perform: move)
                .deleteDisabled(true)
            } header: {
                Text("The top plan opens first on Today.")
                    .font(.versedDetail)
                    .foregroundStyle(.secondaryText)
                    .textCase(nil)
                    .listRowInsets(EdgeInsets(top: 0, leading: Hardcover.margin, bottom: 10, trailing: Hardcover.margin))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
        .versedScreen()
        .tint(Color.brand)
        .navigationTitle("Reorder Plans")
        .versedBackButton()
    }

    private func move(from source: IndexSet, to destination: Int) {
        var plans = ordered
        plans.move(fromOffsets: source, toOffset: destination)
        for (index, plan) in plans.enumerated() {
            plan.sortOrder = index
        }
        try? modelContext.save()
    }
}

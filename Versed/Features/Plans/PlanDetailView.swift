import SwiftData
import SwiftUI

/// One plan's page: how far along it is, what's coming up, its pace, and a way to remove it.
struct PlanDetailView: View {
    let engine: PlanEngine
    let plan: ReadingPlan
    let openSchedule: () -> Void
    let onRemoved: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var confirmsRemoval = false

    private var store: ReadingPlanStore { ReadingPlanStore(context: modelContext, engine: engine) }
    private var state: PlanState { plan.state }

    var body: some View {
        let status = engine.status(of: state)
        let upcoming = engine.upcoming(for: state)
        ScrollView {
            VStack(spacing: 22) {
                LedgerSection(title: "Progress") {
                    LedgerRowLabel(title: status.periodText, detail: "\(Int((status.progress * 100).rounded()))% read", symbol: nil)
                    if let reading = status.reading {
                        LedgerRule()
                        LedgerRowLabel(title: reading.displayLabel, detail: status.doneText ?? "Up next", symbol: nil)
                    }
                }

                if !upcoming.isEmpty {
                    LedgerSection(title: "Coming Up") {
                        ForEach(upcoming, id: \.self) { item in
                            if item != upcoming.first { LedgerRule() }
                            LedgerRowLabel(title: item.when, detail: item.label, symbol: nil)
                        }
                    }
                }

                if !status.isFinished {
                    LedgerSection(title: "Read By") {
                        BlockPicker(options: PlanPace.allCases, selection: paceBinding) { $0.label }
                    }
                }

                if state.finishDay != nil, !status.isFinished {
                    LedgerSection(title: "Finish", footer: "Change the date anytime. The reading left spreads across the days left.") {
                        DatePicker("Finish By", selection: finishBinding, in: VersedApp.today..., displayedComponents: .date)
                            .font(.versedRow)
                            .foregroundStyle(.brand)
                            .padding(.vertical, 6)
                    }
                }

                if state.source.isWeeklySchedule {
                    Ledger {
                        Button(action: openSchedule) {
                            LedgerRowLabel(title: "Reading Schedule")
                        }
                        .buttonStyle(.ledgerRow)
                    }
                }

                Button {
                    confirmsRemoval = true
                } label: {
                    Text("Remove Plan").frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary)

                if state.source.isWeeklySchedule {
                    Text(WeeklyCover.notice)
                        .font(.versedNote)
                        .foregroundStyle(.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .versedPage()
        }
        .versedScreen()
        .tint(Color.brand)
        .navigationTitle(engine.title(of: state.source))
        .navigationBarTitleDisplayMode(.inline)
        .versedBackButton()
        .confirmationDialog("Remove this plan?", isPresented: $confirmsRemoval, titleVisibility: .visible) {
            Button("Remove Plan", role: .destructive) {
                store.remove(plan)
                onRemoved()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your saved verses and streak stay.")
        }
    }

    private var paceBinding: Binding<PlanPace> {
        Binding { state.pace } set: { store.setPace($0, of: plan) }
    }

    private var finishBinding: Binding<Date> {
        Binding {
            state.finishDay.flatMap { ReadingDay.date(forKey: $0, calendar: engine.dates.calendar) } ?? VersedApp.today
        } set: {
            store.setFinish($0, of: plan)
        }
    }
}

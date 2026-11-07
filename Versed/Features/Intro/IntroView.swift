import SwiftUI

/// A few short pages shown the first time the app opens, and again from Settings.
/// The last page offers the daily reminder, with a clear way to say no.
struct IntroView: View {
    /// The `@AppStorage` key for whether the reader has finished or skipped the intro.
    static let hasSeenKey = "hasSeenIntro"

    /// Called when the reader finishes or skips.
    let onFinish: () -> Void

    @AppStorage(DailyReminder.isOnKey) private var reminderIsOn = false
    @AppStorage(DailyReminder.minuteOfDayKey) private var reminderMinuteOfDay = DailyReminder.defaultMinuteOfDay
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Page {
        let glyph: Glyph
        let title: String
        let message: String
    }

    private let pages = [
        Page(
            glyph: .arrowUp,
            title: "Swipe Up for the Next Verse",
            message: "Versed shows one verse at a time. Swipe up to keep reading."
        ),
        Page(
            glyph: .heart,
            title: "Double-Tap to Save",
            message: "Double-tap a verse, or tap the heart, to keep it in your Saved tab."
        ),
        Page(
            glyph: .ribbon,
            title: "Read at Your Own Pace",
            message: "Pick a book or the weekly schedule and how long to take. Versed breaks it into days or weeks, and you can follow more than one."
        ),
    ]

    private var isLastPage: Bool { page == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                SmallCapsLabel("Step \(page + 1) of \(pages.count)")
                Spacer()
                if !isLastPage {
                    Button("Skip", action: onFinish)
                        .buttonStyle(.plainWord)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                }
            }
            .frame(minHeight: 52)
            .padding(.horizontal, Hardcover.margin)

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index], offersReminder: index == pages.count - 1)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            if !isLastPage {
                Button {
                    // Slides to the next page, or just switches with Reduce Motion on.
                    withAnimation(reduceMotion ? nil : .default) { page += 1 }
                } label: {
                    Text("Next").frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
                .padding(.horizontal, Hardcover.margin)
                .padding(.vertical, 20)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            }
        }
        .background { PaperSurface() }
        .tint(Color.brand)
    }

    /// One page. Every page starts at the same height, so nothing jumps between them.
    /// At the largest text sizes it scrolls, so nothing is cut off.
    private func pageView(_ page: Page, offersReminder: Bool) -> some View {
        GeometryReader { proxy in
            ScrollView {
                // Never squeezed, so long pages scroll.
                pageContent(page, offersReminder: offersReminder)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: proxy.size.height, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    /// The last page also offers the reminder, in the same column so its buttons
    /// stay reachable at the largest text sizes.
    private func pageContent(_ page: Page, offersReminder: Bool) -> some View {
        VStack(spacing: 20) {
            GlyphView(page.glyph, size: 34, lineWidth: 1)
                .foregroundStyle(.brand)
                .frame(height: 44)

            Text(page.title)
                .font(.versedTitle(size: 42, relativeTo: .title))
                .foregroundStyle(.brand)
                .accessibilityAddTraits(.isHeader)

            Ornament()

            Text(page.message)
                .font(.versedRow)
                .foregroundStyle(.secondaryText)

            if offersReminder {
                reminderOffer
                    .padding(.top, 24)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Hardcover.margin)
        .padding(.top, 36)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
    }

    private var reminderOffer: some View {
        VStack(spacing: 12) {
            Text("Want a gentle reminder to read each day?")
                .font(.versedRow)
                .foregroundStyle(.brand)

            Button {
                Task { await turnOnReminder() }
            } label: {
                Text("Remind Me Daily at \(DailyReminder.date(minuteOfDay: reminderMinuteOfDay).formatted(date: .omitted, time: .shortened))")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)

            Button(action: onFinish) {
                Text("Not Now").frame(maxWidth: .infinity)
            }
            .buttonStyle(.secondary)

            Text("You can change this anytime in Settings.")
                .font(.versedNote)
                .foregroundStyle(.secondaryText)

            Text(AboutSection.independenceNotice)
                .font(.versedNote)
                .foregroundStyle(.secondaryText)
                .padding(.top, 16)
        }
    }

    /// Asks for permission and schedules the reminder. If the reader says no to
    /// notifications, the reminder just stays off; the intro never asks twice.
    private func turnOnReminder() async {
        reminderIsOn = await DailyReminderScheduler().turnOn(minuteOfDay: reminderMinuteOfDay)
        onFinish()
    }
}

#Preview {
    IntroView {}
}

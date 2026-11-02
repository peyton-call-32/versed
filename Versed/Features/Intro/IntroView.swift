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
        let symbol: String
        let title: String
        let message: String
    }

    private let pages = [
        Page(
            symbol: "hand.draw",
            title: "Swipe Up for the Next Verse",
            message: "Versed shows one verse at a time. Swipe up to keep reading."
        ),
        Page(
            symbol: "heart",
            title: "Double-Tap to Save",
            message: "Double-tap a verse, or tap the heart, to keep it in your Saved tab."
        ),
        Page(
            symbol: "calendar",
            title: "This Week's Reading, Ready",
            message: "Versed opens to this week's reading. Tap the dates at the top, or open Browse, to pick another week."
        ),
    ]

    private var isLastPage: Bool { page == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if !isLastPage {
                    Button("Skip", action: onFinish)
                        .padding()
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                }
            }
            .frame(minHeight: 52)

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index], offersReminder: index == pages.count - 1)
                        .tag(index)
                }
            }
            // The page dots get their own row below, so long text never slides under them.
            .tabViewStyle(.page(indexDisplayMode: .never))

            pageDots

            if !isLastPage {
                nextButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            }
        }
        .background(Color(.systemBackground))
    }

    /// One page, centered when it fits. At the largest text sizes it scrolls instead,
    /// starting from the top so nothing is cut off.
    private func pageView(_ page: Page, offersReminder: Bool) -> some View {
        GeometryReader { proxy in
            ScrollView {
                // Full height so short pages sit centered; never squeezed, so long pages scroll.
                pageContent(page, offersReminder: offersReminder)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    /// The last page also offers the reminder, in the same column so its buttons
    /// stay reachable at the largest text sizes.
    private func pageContent(_ page: Page, offersReminder: Bool) -> some View {
        VStack(spacing: 20) {
            Image(systemName: page.symbol)
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text(page.title)
                .font(.system(.title, design: .serif, weight: .semibold))
                .accessibilityAddTraits(.isHeader)

            Text(page.message)
                .font(.body)
                .foregroundStyle(.secondaryText)

            if offersReminder {
                reminderOffer
                    .padding(.top, 24)
            }
        }
        .multilineTextAlignment(.center)
        .padding(32)
        .frame(maxWidth: .infinity)
    }

    /// Shows which page the reader is on. VoiceOver reads it as "Page 1 of 3".
    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Circle()
                    .fill(index == page ? Color.primary : Color.secondaryText.opacity(0.4))
                    .frame(width: 8, height: 8)
            }
        }
        // Room around the dots, and big enough to meet the minimum touch size.
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement()
        .accessibilityLabel("Page \(page + 1) of \(pages.count)")
        .accessibilityIdentifier("Intro page dots")
    }

    private var reminderOffer: some View {
        VStack(spacing: 12) {
            Text("Want a gentle reminder to read each day?")
                .font(.headline)

            Button {
                Task { await turnOnReminder() }
            } label: {
                Text("Remind Me Daily at \(DailyReminder.date(minuteOfDay: reminderMinuteOfDay).formatted(date: .omitted, time: .shortened))")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            // A darker blue than the dark-mode accent, so the white label stays easy to read.
            .tint(Color("ProminentButton"))

            Button("Not Now", action: onFinish)
                .controlSize(.large)

            Text("You can change this anytime in Settings.")
                .font(.footnote)
                .foregroundStyle(.secondaryText)

            Text(AboutSection.independenceNotice)
                .font(.footnote)
                .foregroundStyle(.secondaryText)
                .padding(.top, 16)
        }
    }

    private var nextButton: some View {
        Button {
            // Slides to the next page, or just switches with Reduce Motion on.
            withAnimation(reduceMotion ? nil : .default) { page += 1 }
        } label: {
            Text("Next")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(Color("ProminentButton"))
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

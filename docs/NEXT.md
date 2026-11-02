# Where we left off

Updated Nov 2, 2026.

## App Store (steps 20–21)

- **Now:** Finishing step 20 in App Store Connect: privacy ("Data Not Collected"), age rating (4+), pricing (Free), and App Review information.
- **Waiting:** Content Rights stays blank until BYU's Copyright Office answers about the 2013 edition fixes in the scripture text. Apple only needs this when submitting for review.
- **Next:** Step 21. Upload a build to TestFlight and test it on Peyton's iPhone. Run the full test suite before uploading.

## UI redesign (done Nov 2)

A simpler, classier look, closer to the Origin app:

- **Colors:** navy and cream to match the app icon. Off-white page with white cards in light mode, deep navy with lighter navy cards in dark mode. Serif screen titles. All colors and button styles live in `Versed/Features/Shared/AppColors.swift`.
- **This Week header:** one row with the streak on the left, the week picker centered, and a Settings gear on the right. Settings now opens only from here; the gear is gone from Browse.
- **Week card:** a small label on top ("THIS WEEK · NOV 2–8", or just the dates for other weeks), then each book's name in big serif with its chapters on a smaller gray line below ("1–3 · 33–34 · 36–37 · 47"). Books read whole and "Christmas" / "Easter Week" show just the name. The split lives in `ReadingWeek.readingByBook`, with unit tests that check every week.
- **Tab bar:** the selected tab is navy. Graying the other tabs and lightening the highlight behind the selected tab aren't possible on iOS 27's glass tab bar with standard settings, so they were left as iOS draws them.

## Still open

- **Accessibility failures** (from the new colors, on screens not changed since): `AccessibilityUITests` flags
  - Browse: the "SCRIPTURES" header doesn't grow with text size.
  - Reading Schedule: "NEW TESTAMENT 2027" header contrast is too low.
  - Dark mode: the serif screen titles ("Browse", "Reading Schedule", "Saved") fail contrast.
- **Flaky or failing UI tests:** `testFinishedWeekStartsOverFromTheFirstVerse` fails every run (the Reading Schedule list hasn't loaded when the test taps it). `testThisWeekPicksUpWhereTheReaderStopped` failed once and passed twice. Fix these before the full test run for TestFlight.
- **Screenshots show the old blue look:** the App Store screenshots in `docs/app-store/screenshots/` and the README screenshots need retaking.

## Good to know

- To screenshot in light or dark without changing Settings, launch with `-appearance light` or `-appearance dark` (plus `-ui-testing -today 2026-10-28` for the usual test week).
- If a UI test stops partway, the app's appearance setting can stay stuck on Light or Dark on the simulator. Relaunching with `-appearance matchPhone`, or picking Match Phone in Settings, puts it back.
- The full UI test suite takes over 10 minutes.

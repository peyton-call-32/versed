# Where we left off

Updated Nov 3, 2026.

## App Store (steps 20–21)

- **Now:** Finishing step 20 in App Store Connect: privacy ("Data Not Collected"), age rating (4+), pricing (Free), and App Review information.
- **Waiting:** Content Rights stays blank until BYU's Copyright Office answers about the 2013 edition fixes in the scripture text. Apple only needs this when submitting for review.
- **Next:** Step 21. Upload a build to TestFlight and test it on Peyton's iPhone. Run the full test suite before uploading.

## UI redesign "Quiet" (done Nov 3)

Simple and classy, but modern. Mocks: https://claude.ai/artifact/AgFoBWJQgBvXQicM4zfzM5 (page "Simple + Modern"). The details are in the Design section of `CLAUDE.md`.

- **New look on every screen:** bundled book-style fonts, even numbers, soft raised cards, a small floating tab bar.
- **Small changes:** a Start Reading button (Continue Reading when partway through), the date on the This Week card, a plain-text streak, and Settings moved to the gear on Browse.
- **The App Store and README screenshots are retaken** in the new look.

## Still open

- **Occasional test failure:** `testReadingSavingBrowsingAndResuming` failed once, then passed on every other run. Its reason wasn't saved. Watch for it in the full test run before TestFlight.
- **Not yet seen on a real iPhone:** check the faint shadows and fonts on Peyton's phone during TestFlight (step 21).

## Good to know

- To screenshot in light or dark without changing Settings, launch with `-appearance light` or `-appearance dark` (plus `-ui-testing -today 2026-10-28` for the usual test week).
- If a UI test stops partway, the app's appearance setting can stay stuck on Light or Dark on the simulator. Relaunching with `-appearance matchPhone`, or picking Match Phone in Settings, puts it back.
- The full UI test suite takes over 10 minutes.

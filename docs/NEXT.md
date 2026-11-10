# Where we left off

Updated Nov 9, 2026.

## App Store (steps 20–21)

- **Now:** Finishing step 20 in App Store Connect: privacy ("Data Not Collected"), age rating (4+), pricing (Free), and App Review information.
- **Before submitting:** Peyton answers Content Rights in App Store Connect. Peyton decided on Nov 5 not to wait for BYU's Copyright Office: the app uses the base text, with no Church headings, summaries, or footnotes.
- **Next:** Step 21. Build 2 (version 1.0) was uploaded on Nov 9 from `design-polish`, with the full test suite passing. Build 1 went up on Nov 5. Peyton adds themself as an internal tester if not done yet, then checks it on their iPhone in the TestFlight app. The next upload needs build 3 (`CURRENT_PROJECT_VERSION` in `project.yml`).
- **How to upload:** this Mac has no registered iPhone, so archive with `CODE_SIGNING_ALLOWED=NO`, then run `xcodebuild -exportArchive -allowProvisioningUpdates` with method `app-store-connect` and destination `upload`. Xcode signs it for distribution during that step.

## Design reset (done Nov 5)

After criticism on X, every screen was reset to one typeset-book look. The details are in the Design section of `CLAUDE.md`, and the audit tools in its Design audit section. App Store and README screenshots are retaken.

## Still open

- **Occasional test failure:** `testReadingSavingBrowsingAndResuming` failed once, then passed on every other run. Its reason wasn't saved. Watch for it in the full test run before TestFlight.
- **Not yet seen on a real iPhone:** check the thin lines, fonts, and page motion on Peyton's phone during TestFlight (step 21).
- **Not yet tested:** iOS 17 and 18 (only the iOS 27 simulator is installed), dark-mode transitions, and whether the plain back button still swipes back on those versions.

## Good to know

- To screenshot in light or dark without changing Settings, launch with `-appearance light` or `-appearance dark` (plus `-ui-testing -today 2026-10-28` for the usual test week).
- If a UI test stops partway, the app's appearance setting can stay stuck on Light or Dark on the simulator. Relaunching with `-appearance matchPhone`, or picking Match Phone in Settings, puts it back.
- The full UI test suite takes over 10 minutes.

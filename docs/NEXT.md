# Where we left off

Updated Nov 5, 2026.

## App Store (steps 20–21)

- **Now:** Finishing step 20 in App Store Connect: privacy ("Data Not Collected"), age rating (4+), pricing (Free), and App Review information.
- **Waiting:** Content Rights stays blank until BYU's Copyright Office answers about the 2013 edition fixes in the scripture text. Apple only needs this when submitting for review.
- **Next:** Step 21. Version 1.0, build 1 was uploaded on Nov 5 with the full test suite passing. Peyton adds themself as an internal tester, then checks it on their iPhone. The next upload needs a higher build number (`CURRENT_PROJECT_VERSION` in `project.yml`).
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

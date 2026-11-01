# Versed

## About me
- I'm Peyton (GitHub: peyton-call-32). I'm not very technical.
- Explain things in plain, normal language. If you use a technical word, explain it in one simple sentence.
- Work in small steps. After each step, tell me what changed, why, and how to see it in the iPhone simulator.
- Check with me before big decisions.
- Save to GitHub as you go, with clear commit messages.
- This is a portfolio piece recruiters will see, so keep the code clean and well organized.

## What this is
- An iPhone app that shows scripture one verse per screen. Swipe up for the next verse, like a short-video feed.
- For Latter-day Saints who want to read a little every day.
- Version 1 is for one person on their own phone: no accounts, no internet.
- Later: families and Sunday School classes read the same week together. Organize data so groups can be added without starting over.

### Version 1 features
1. Feed: one verse per screen, swipe up for the next, a title card at the start of each chapter.
2. Opens to this week's Come, Follow Me reading, with a menu to pick another week.
3. Browse any book and chapter (Old Testament, New Testament, Book of Mormon, Doctrine and Covenants, Pearl of Great Price).
4. Save verses (double-tap or heart) and a Saved tab.
5. Remembers where I left off.
6. Daily reading streak.

### Tech
- SwiftUI, iOS 17.
- Scripture text bundled in the app from github.com/bcbooks/scriptures-json.
- XcodeGen builds `Versed.xcodeproj` from `project.yml`. It's installed at `~/.local/xcodegen-dl/xcodegen/bin/xcodegen` (no Homebrew on this Mac). Rerun it after adding/removing files or changing `project.yml`.
- Weekly schedule: one file per year in `Versed/Resources/Schedules/schedule-YYYY.json`. Weeks run Monday–Sunday. To add a year, add a new file and rerun XcodeGen. 2026 currently covers Oct 26–Dec 27 only (from the Manna prototype, plus the Christmas week).
- Christmas 2026 has no official reading block. It uses the passages the official lesson cites: Old Testament promises in lesson order, then other cited scriptures, ending with the Nativity (Luke 1, Matthew 1, Luke 2, Matthew 2). Exodus 12 is trimmed to 12:5.
- 2027 (New Testament) covers all 52 weeks, Dec 28, 2026 – Dec 26, 2027, from the official 2027 manual's table of contents.
- Each week in a schedule file has a `lessonURL` (its official lesson on churchofjesuschrist.org), and each file has a `manualURL` (the manual's table of contents) used when a week has none. Links only, never lesson text. In 2027, Easter week is lesson 14 and the week after is lesson 13, as in the official manual. A wrong lesson number still loads (the manual's cover page), so check each page's title when adding links.
- Easter 2027 (Mar 22–28) and Christmas 2027 (Dec 20–26) have no official reading block either:
  - Easter uses the passages the lesson cites, in lesson order (Palm Sunday through the Resurrection and 3 Nephi 11). The opening quote (Matthew 28:6) is left to its place in Matthew 28:1–10.
  - Christmas follows the 2026 pattern: prophecies, then other cited scriptures, ending with the Nativity in story order (Luke 1, Matthew 1, Luke 2, Matthew 2).

## Build plan
Done:
1. Project guide, README, gitignore
2. Xcode project with a placeholder home screen
3. Bundle the scriptures and a library to read them
4. Swipe-up verse feed with chapter title cards
5. Open to this week's reading, with a week picker
6. Browse tab for any book and chapter
7. Save verses and a Saved tab
8. Remember where I left off
9. Daily reading streak
10. Finish version 1: app icon, screenshots in the README, and a final check that everything works

Version 1 is complete.

Before the App Store (done):
11. Daily reminder: off by default, gentle wording, never guilt about streaks. Ask for notification permission only when turned on. On/off switch and time picker in Settings. Nothing leaves the phone.
12. "Open this week's lesson" button on each week's intro card. Real link per week stored in the schedule files (manual table of contents if a week's link can't be found). Opens in Gospel Library if installed. Link only, no lesson text.
13. First-time intro: 2–3 short screens (swipe up, double-tap to save, opens to this week). Last screen offers the daily reminder with a clear "Not now". Shown once, with Skip. Can be replayed from Settings.
14. About section in Settings: independent-app disclaimer, scripture text credit, privacy policy link (PRIVACY.md), contact email (ask Peyton which), app version.
15. Text size and accessibility: Dynamic Type up to the largest sizes, VoiceOver labels (verse + reference), readable colors in light and dark, respect Reduce Motion, tests where useful.

App Store release (in progress). Peyton's Apple Developer account is approved and signed in to Xcode. Go step by step and explain each step in plain language:
16. Privacy policy URL: https://github.com/peyton-call-32/versed/blob/main/PRIVACY.md (same link as in Settings).
17. App Store listing draft in `docs/app-store/listing.md`: subtitle, description, keywords, what's new. No Church name or "Come, Follow Me" in the app name, and nothing that looks official.
18. App Store screenshots from the simulator at the sizes Apple requires, saved in `docs/app-store/screenshots/`.
19. Signing with Peyton's developer account (team set in `project.yml`), and mark that the app uses no special encryption (`ITSAppUsesNonExemptEncryption = NO`) so Apple doesn't ask on every upload.
20. Walk Peyton through App Store Connect: create the app, fill in the listing, answer the privacy questions ("Data Not Collected"), and set the age rating.
21. Walk Peyton through uploading a build to TestFlight and testing it on their own iPhone before submitting for review.

## Rules
- Scripture text must come from a public-domain source. The current text is from github.com/bcbooks/scriptures-json (public domain). Don't use the Church's 2013 edition text, footnotes, or chapter summaries without a license.
- Don't use the Church's name, logo, or "Come, Follow Me" as the app name, and nothing should look like an official Church app.
- Youth safety: youth groups need two adult leaders, parents can see group activity, and there are no private messages between adults and youth.
- Collect as little user data as possible.
- Accessibility: feed pages use `ShrinkToFit` so text grows with the iPhone's text size but each page still fits on one screen. Use `.secondaryText` (not `.secondary`) for gray text so it stays readable. Respect Reduce Motion for any new animation. `AccessibilityUITests` runs Apple's accessibility audit on every screen in light and dark mode.

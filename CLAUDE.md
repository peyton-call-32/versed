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
2. Opens to this week's reading, with a chapter menu to move around the week or pick another week. Browse has a weekly reading cover and a Reading Schedule of every week.
3. Browse any book and chapter (Old Testament, New Testament, Book of Mormon, Doctrine and Covenants, Pearl of Great Price).
4. Save verses (double-tap or heart) and a Saved tab.
5. Remembers where I left off.
6. Daily reading streak, with a calendar of the days read.

### Tech
- SwiftUI, iOS 17.
- Scripture text bundled in the app from github.com/bcbooks/scriptures-json.
- XcodeGen builds `Versed.xcodeproj` from `project.yml`. It's installed at `~/.local/xcodegen-dl/xcodegen/bin/xcodegen` (no Homebrew on this Mac). Rerun it after adding/removing files or changing `project.yml`.
- Weekly schedule: one file per year in `Versed/Resources/Schedules/schedule-YYYY.json`. Weeks run Monday–Sunday. To add a year, add a new file and rerun XcodeGen. 2026 currently covers Oct 26–Dec 27 only (from the Manna prototype, plus the Christmas week).
- Christmas 2026 has no official reading block. It uses the passages the official lesson cites: Old Testament promises in lesson order, then other cited scriptures, ending with the Nativity (Luke 1, Matthew 1, Luke 2, Matthew 2). Exodus 12 is trimmed to 12:5.
- 2027 (New Testament) covers all 52 weeks, Dec 28, 2026 – Dec 26, 2027, from the official 2027 manual's table of contents.
- Schedule files hold only each week's dates, chapters (`label`, `readings`), and lesson link. No lesson titles: those are the Church's, so they never appear in the app.
- UI tests launch with `-today 2026-10-28` so "this week" is always the Jeremiah week and the tests don't break every Monday.
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
12. "Open this week's lesson" button on the card after each week's last verse (moved there from the opening card, so people see it when they finish). Real link per week stored in the schedule files (manual table of contents if a week's link can't be found). Opens in Gospel Library if installed. Link only, no lesson text.
13. First-time intro: 2–3 short screens (swipe up, double-tap to save, opens to this week). Last screen offers the daily reminder with a clear "Not now". Shown once, with Skip. Can be replayed from Settings.
14. About section in Settings: independent-app disclaimer, scripture text credit, privacy policy link (PRIVACY.md), contact email (ask Peyton which), app version.
15. Text size and accessibility: Dynamic Type up to the largest sizes, VoiceOver labels (verse + reference), readable colors in light and dark, respect Reduce Motion, tests where useful.

App Store release (in progress; 16–19 done). Peyton's Apple Developer account is approved and signed in to Xcode. Go step by step and explain each step in plain language:
16. Privacy policy URL: https://peyton-call-32.github.io/versed/privacy/ (same link as in Settings). Support URL: https://peyton-call-32.github.io/versed/support/. Both are plain webpages in `docs/` (`docs/privacy/index.html`, `docs/support/index.html`), served by GitHub Pages from the `docs` folder on `main`.
17. App Store listing draft in `docs/app-store/listing.md`: subtitle, description, keywords, what's new. No Church name or "Come, Follow Me" in the app name, and nothing that looks official.
18. App Store screenshots from the simulator at the sizes Apple requires, saved in `docs/app-store/screenshots/`.
19. Signing with Peyton's developer account (team set in `project.yml`), and mark that the app uses no special encryption (`ITSAppUsesNonExemptEncryption = NO`) so Apple doesn't ask on every upload.
20. Walk Peyton through App Store Connect: create the app, fill in the listing, answer the privacy questions ("Data Not Collected"), and set the age rating.
21. Walk Peyton through uploading a build to TestFlight and testing it on their own iPhone before submitting for review.

## Design
- The look is called "Hardcover": every screen is set like a page of a fine bound book. Navy ink on warm paper (cream on deep navy in dark mode), one family of serif type, thin ruled lines instead of cards, and nearly square corners. Nothing floats, glows, or fades. No gradients, frosted panels, pills, or card shadows, and no extra colors.
- None of iOS's glass: buttons in a top bar use `PlainToolbarItem`, `DoneToolbarItem`, and `.versedBackButton()`; scrolling screens use `.versedScreen()`, which removes the blur strips iOS draws at the edges. Swiping from the edge still goes back (`VersedToolbar.swift`).
- Every screen shares one set of margins (`Hardcover.margin`) and titles, rows, and buttons all line up to it. Every sheet uses `.versedSheet()`.
- Chapter openings are solid navy with a thin double frame, in light and dark mode. The frame stops short of the bands at the top and bottom, so controls never cross it. Verse pages are paper in light mode and deep navy in dark mode, so each chapter feels like a new moment. Centered verses, a thin line-and-diamond `Ornament`, small spaced capitals for references and labels.
- Three bundled fonts, free under the Open Font License (licenses in `Versed/Resources/Fonts`, listed in `Versed/App/Info.plist`): Newsreader for verses and all small text (`.versedRow`, `.versedDetail`, `.versedNote`, `SmallCapsLabel`), Cormorant Medium for titles, and Cormorant Light for numbers (the bundled files are set so its numbers are all one even height). The iPhone's own font is not used for words. Words in all capitals in a verse, like LORD, are set in small capitals (`VerseText.swift`).
- Small labels stay easy to read, with full-strength color (never faded) on navy.
- The tab bar (`VersedTabBar.swift`) is a solid band across the foot of the page under a ruled line, not a floating bar, so lists stop at it and never run underneath. A short line marks the open tab. It turns navy on chapter openings. It slides rather than fades, so it never leaves a pale band.
- While reading (`ReadingChrome.swift`), the tab bar and status bar step aside. The same band then holds a thin progress line ("3 of 40"), or the arrow on a chapter opening. The heart never moves. One tap on the page brings the controls back until the next swipe. With VoiceOver or Switch Control on, nothing ever hides.
- Browse (`VolumeCarousel.swift`) shows six navy hardcovers with a groove at the spine, swiped through with the edges of the neighbors showing, and dots below: the weekly reading cover (`WeeklyCover`) first, then the five volumes. It opens on the last book read (from `ReadingPosition`), or the weekly cover with nothing read yet. Tapping an edge brings that book forward; tapping the middle one opens it with a plain slide. iOS's zoom was tried and removed because it shows a double image for several frames.
- Lists (`Ledger`, `LedgerSection`, `LedgerRowLabel`) are ruled rows on the page. A volume's books read like a table of contents, with dotted leaders. Chapter numbers (`ChapterGrid`) are ruled rows of Cormorant numerals, used by Browse and Go To.
- Motion and touch: chapter openings move as one solid piece. Verses and week cards drift and fade as they move (`pageDepth`), fading fast enough to be gone before they reach the top controls. Buttons give under the finger (`pressEffect`), the signature spring is `Animation.versed`, and haptics stay soft and rare: saving a verse, reaching a new chapter, finishing a week, changing a book cover. All motion respects Reduce Motion.
- Colors: warm paper in light mode, deep navy in dark mode, navy covers in both.
- This Week shows the date in its small label, and the way forward ("Swipe up...") sits in one fixed place above the tab bar. When a week has several books they sit close together as one group. A book's name sits right above its chapter sections, which are underlined numbers that jump to where they start.
- Moving around a feed: the words at the top (`ChapterMenu.swift`) say where the reader is ("Ezekiel 2", or "Chapters" on a week's opening and closing cards; it waits for a tap on a chapter opening) and open a "Go To" sheet: every chapter in the feed, plus "Back to Week's Start" and "Other Weeks" in a week's feed. Back to the start keeps the reader's place underneath, so swiping up continues. Tapping the tab that's already open goes back to that tab's start. Browse's feed holds the whole book, so earlier chapters are reachable.
- Streak: the flame at the top right of This Week (`StreakBadge.swift`, drawn as `FlameMark`) shows the count, or just the flame with no streak going, so the calendar is always reachable. It opens "Your Streak" (`StreakCalendarView.swift`): the big count, a month calendar where days in a row join into one band, best streak, and days read. Past months go back to the first day read. Everything comes from the saved days on the phone. Gentle wording only, never guilt about a lost streak.
- All colors, fonts, and shared pieces live in `Versed/Features/Shared/AppColors.swift`. The tab bar is `VersedTabBar.swift`, chapter numbers are `ChapterGrid.swift`, and top bar buttons are `VersedToolbar.swift`. New screens use these. Don't add new colors or one-off styles; if something's missing, add it there.

## Design audit
- `DesignAuditUITests` walks every screen and saves full-size pictures, in light or dark and at any text size. It only runs when `TEST_RUNNER_VERSED_AUDIT_DIR` is set, so it stays out of the normal test run.
- `test6Motion` runs through the app's motion for a screen recording (`xcrun simctl io <device> recordVideo`). `Scripts/contact_sheet.swift` lays a recording's frames side by side, to check a transition frame by frame.
- After a design change, check the pictures and the frames, not just the code.

## Testing
- After a change, only run the tests related to it, then save to GitHub.
- Don't run the full test suite unless Peyton asks for it, or right before uploading a build to TestFlight or the App Store.
- Only take largest-text-size and dark-mode screenshots when a change affects how a screen looks, not for every change.

## Rules
- Scripture text is the base text only, from github.com/bcbooks/scriptures-json. It includes the 2013 edition's small spelling and punctuation fixes, which Peyton reviewed and decided to keep on Nov 5, 2026. Don't add the Church's footnotes, chapter summaries, or chapter and section headings without a license.
- Don't use the Church's name, logo, or "Come, Follow Me" as the app name, and nothing should look like an official Church app.
- "Come, Follow Me" is a Church trademark. Never use it as the name of a tab, button, screen, or feature, with one exception Peyton chose on Nov 5, 2026, knowing the Church or Apple could ask for a change: the Browse cover (`WeeklyCover`) is titled "Come, Follow Me" with "Weekly Reading Schedule" under it, and always carries "Versed is an independent app, not made or endorsed by The Church of Jesus Christ of Latter-day Saints." Its words live in one place, so they're quick to change. Otherwise it appears only in one descriptive line (`AboutSection.independenceNotice`), shown in the About section and on the last page of the first-time intro: "This Week follows the Come, Follow Me reading schedule. Versed is an independent app and is not made, approved, or endorsed by The Church of Jesus Christ of Latter-day Saints." The lesson links (which contain "come-follow-me" in the web address) are fine.
- Youth safety: youth groups need two adult leaders, parents can see group activity, and there are no private messages between adults and youth.
- Collect as little user data as possible.
- Accessibility: feed pages use `ShrinkToFit` so text grows with the iPhone's text size but each page still fits on one screen. Use `.secondaryText` (not `.secondary`) for gray text so it stays readable. Respect Reduce Motion for any new animation. `AccessibilityUITests` runs Apple's accessibility audit on every screen in light and dark mode; anything it flags by mistake is listed, with the reason, in `isKnownException`.

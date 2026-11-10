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
2. Study plans (added after version 1, decided Nov 5, 2026): Today lists every plan with what to read next. A plan covers the weekly schedule, a volume, or a book, read by day or by week, and any number can run at once. New readers start with no plan, so nothing defaults to the weekly schedule. Plans live on Today; "+ Add a Plan" chooses one, and the Reading Schedule of every week is under the weekly plan's details.
3. The Library: any book and chapter (Old Testament, New Testament, Book of Mormon, Doctrine and Covenants, Pearl of Great Price).
4. Save verses (double-tap or heart) and a Saved tab.
5. Remembers where I left off.
6. Daily reading streak, with a calendar of the days read.

### Tech
- SwiftUI, iOS 17.
- Scripture text bundled in the app from github.com/bcbooks/scriptures-json.
- XcodeGen builds `Versed.xcodeproj` from `project.yml`. It's installed at `~/.local/xcodegen-dl/xcodegen/bin/xcodegen` (no Homebrew on this Mac). Rerun it after adding/removing files or changing `project.yml`.
- Weekly schedule: one file per year in `Versed/Resources/Schedules/schedule-YYYY.json`. Weeks run Monday–Sunday. To add a year, add a new file and rerun XcodeGen. 2026 covers all 52 weeks, Dec 29, 2025 – Dec 27, 2026, from the official 2026 manual's table of contents.
- The first week of 2026 ("Introduction") and Easter 2026 (Mar 30–Apr 5) have no official reading block. Both use the passages the lesson cites in its home and church section, in lesson order. Children's sections and the background mention of Genesis 1–6 are left out.
- Christmas 2026 has no official reading block. It uses the passages the official lesson cites: Old Testament promises in lesson order, then other cited scriptures, ending with the Nativity (Luke 1, Matthew 1, Luke 2, Matthew 2). Exodus 12 is trimmed to 12:5.
- 2027 (New Testament) covers all 52 weeks, Dec 28, 2026 – Dec 26, 2027, from the official 2027 manual's table of contents.
- Schedule files hold only each week's dates, chapters (`label`, `readings`), and lesson link. No lesson titles: those are the Church's, so they never appear in the app.
- UI tests launch with `-today 2026-10-28` so "this week" is always the Jeremiah week and the tests don't break every Monday. `-seed-weekly-plan` and `-seed-book-plan` start plans, so tests needn't set them up each time.
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

## Study plans
- `ReadingPlan` stores only the choices and a count of chapters read. `PlanEngine` works out each reading from them, so nothing is stored ahead of time and a missed day just spreads across the days left. No wording ever says "behind". Past the finish date, a plan keeps its original pace rather than asking for everything at once.
- `PlanPacer` splits chapters: readings end at the end of a chapter, and long chapters count for more, so days come out about even.
- Weeks run Monday to Sunday. A plan started midweek gets a smaller first week.
- Three kinds of plan: a book or volume with a finish date; the weekly schedule following the calendar ("Join This Week", moves to the next year on its own); and one year of the schedule from its first week ("Start from the Beginning"), where a week waits until it's finished and the row says "Week 3 of 52".
- Today's reading doesn't move once read: the row says "Done today" and tapping it reads ahead. There's one streak for the whole app.
- Reading a chapter from the Library never needs a plan.

## Design
- The look is called "Hardcover": every screen is set like a page of a fine bound book. Navy ink on warm paper (cream on deep navy in dark mode), one family of serif type, and nearly square corners. Nothing glows. No gradients, frosted panels, pills, or cards, and no extra colors.
- Materials (polish pass, Nov 6, 2026, `Materials.swift`): depth comes from real bookbinding, not effects. Pages have a faint paper grain (drawn by `Scripts/make_textures.swift`). Navy surfaces are smooth, with no weave or pattern (Peyton removed the woven cloth on Nov 9, 2026; keep it off). Type on cloth is pressed in (`stampedIntoCloth`). Only real objects cast a shadow (book covers, the ribbon, the open plan, the paper bands at the top of Today and the foot of the page), kept tight so it reads as an edge, not a fade.
- Lines: rows sit on the page like a table of contents, with open space between them and one fine line only under a section's label (`LedgerSection`). On Today, each closed plan is ruled above and below with a firmer line (`Rule.defined`), none beside the open band, so each plan reads as its own row (Nov 9, 2026). Dotted leaders (`LeaderDots`) carry the eye across a row where a number or detail sits at the far end.
- Icons are hand-drawn in `Glyphs.swift` (`GlyphView`) so their fine line matches the type: don't use SF Symbols for new icons, add a glyph there. The mark between parts of a page is a printer's swelled rule (`Ornament`, `SwelledRuleShape`), which replaced the line-and-diamond.
- Controls: main buttons are flat, solid plates (`SolidPlate`, Nov 9, 2026): one color, nearly square corners, no grain, raised edge, or shadow (Peyton removed the raised plate as looking generic; keep it flat). Pressing darkens it a touch. Rows shade under the finger, `BlockPicker`'s plate slides, the reminder switch is `HardcoverToggleStyle` (still a real switch to VoiceOver), and dates and times open in place (`DateRow`, `TimeRow`).
- None of iOS's glass: buttons in a top bar use `PlainToolbarItem`, `DoneToolbarItem`, and `.versedBackButton()`; scrolling screens use `.versedScreen()`, which removes the blur strips iOS draws at the edges. Swiping from the edge still goes back (`VersedToolbar.swift`).
- Every screen shares one set of margins (`Hardcover.margin`) and titles, rows, and buttons all line up to it. Every sheet uses `.versedSheet()`.
- Chapter openings are smooth navy with a stamped frame with cut-in corners (`CoverFrame`), in light and dark mode. The frame stops short of the bands at the top and bottom, so controls never cross it. Verse pages are paper in light mode and deep navy in dark mode, so each chapter feels like a new moment. Centered verses, a swelled-rule `Ornament`, small spaced capitals for references and labels.
- Three bundled fonts, free under the Open Font License (licenses in `Versed/Resources/Fonts`, listed in `Versed/App/Info.plist`): Newsreader for verses and all small text (`.versedRow`, `.versedDetail`, `.versedNote`, `SmallCapsLabel`), Cormorant Medium for titles, and Cormorant Light for numbers (the bundled files are set so its numbers are all one even height). The iPhone's own font is not used for words. Words in all capitals in a verse, like LORD, are set in small capitals (`VerseText.swift`).
- Small labels stay easy to read, with full-strength color (never faded) on navy.
- The tab bar (`VersedTabBar.swift`) is a solid band across the foot of the page with a tight shadow along its top edge, not a floating bar, so lists stop at it and never run underneath. A small swelled rule under the label marks the open tab. It turns navy on chapter openings. It slides rather than fades, so it never leaves a pale band.
- While reading (`ReadingChrome.swift`), the tab bar and status bar step aside. The same band then holds a thin progress line ("3 of 40"), or the arrow on a chapter opening. The heart never moves. One tap on the page brings the controls back until the next swipe. With VoiceOver or Switch Control on, nothing ever hides.
- Library (`LibraryView.swift`, `LibraryCarousel.swift`, `LibraryBooks.swift`), the second tab, has one job: open any book, no plan needed. The books a reader keeps are smooth navy covers facing them, with a rounded spine and hinge groove, a stamped frame, and the page block showing past the right and lower edges with its leaves drawn (`PageBlock`). Titles stack like a title page (`CoverTitle`): "of" and "and" small on their own line, phrases like "Great Price" kept whole, one size per title (Nov 9, 2026). Swiping, or tapping a neighbor, brings a cover to the middle and the page lists what's inside. The list waits until the covers come to rest, then fades from one book to the next, so a swipe past several covers changes it once (Nov 9, 2026). The + opens "Your Library" to add or remove any book, and a library can hold as many or as few as the reader wants, even none. Removing a book never touches progress or saved verses. New readers start with every book. A year of the weekly schedule is a book too, and its list is set like the others (Nov 9, 2026): "Make a Plan for Come, Follow Me" first (opens the weekly plan if one is running), then "This Week" as a plain row under its own label (no navy block), then every week, ending with the short notice. Next year's isn't added for anyone: add it to `Library.offeredCourses` and readers add it themselves (the 2027 schedule is in the app, just not offered yet). The Library reopens on the last book shown. Short lines under the covers mark which one is open. "Make a Plan" is the first row under a cover, named for what it plans ("Make a Plan for the Old Testament", "Make a Plan for Alma"), Nov 9, 2026. The magnifying glass finds any book or chapter, in the library or not. "Continue: Alma 32:21" sits in one small line above the covers once there's a place to return to.
- Lists (`Ledger`, `LedgerSection`, `LedgerRowLabel`) are open rows on the page. Chapter numbers (`ChapterGrid`) are open rows of Cormorant numerals, used by the Library and Go To.
- Motion and touch: chapter openings move as one solid piece. Verses and week cards drift and fade as they move (`pageDepth`), fading fast enough to be gone before they reach the top controls. Buttons give under the finger (`pressEffect`), the signature spring is `Animation.versed`, and haptics stay soft: saving a verse, reaching a new chapter, finishing a week, changing a book cover, pressing a main button, and changing a choice, a switch, or a month. All motion respects Reduce Motion.
- Colors: warm paper in light mode, deep navy in dark mode, navy covers in both.
- Today (`TodayView.swift`, `TodayMarks.swift`) hangs from a strip of paper at the top of the page: the "Today" title and the date on the left, level with the other tabs' titles, and a ribbon bookmark with the streak on the right. The Versed V isn't on any tab (decided Nov 6, 2026). Plans start lower, with open space under the date. Each closed plan is its name, set large, with a small "Today" or "This Week" label (by the plan's pace) and its reading under it, one book per line (a long week shows two books and "and N more books"). One plan is open at a time, as a band of navy cloth across the page (cream on navy in light and dark mode), with its name stepped down to a small label and the reading set large, how long it takes, and one button ("Start Reading", "Continue Reading", or "Read Ahead" once done). Any plan can be closed, and all can be closed. The first plan with reading left opens when the app opens and on returning from a reading. A finished reading shows a small check beside the name. "Details" beside the time opens the plan's details (`PlanDetailView.swift`). The order is set in Settings > Reorder Plans (`ReorderPlansView.swift`), shown only with two or more plans. `RevealLayout` opens a plan so everything below moves in step, with no bounce. With no plans it asks "What would you like to read?". Dates use `DateRow`, set in the page's own type.
- Settings is the fourth tab. Words stay few: no instructions on Today or the Library.
- A reading's opening card shows when it's for in its small label, and the way forward ("Swipe up...") sits in one fixed place above the tab bar. When a week has several books they sit close together as one group. A book's name sits right above its chapter sections, which are underlined numbers that jump to where they start.
- Moving around a feed: the words at the top (`ChapterMenu.swift`) say where the reader is ("Ezekiel 2", or "Chapters" on a week's opening and closing cards; it waits for a tap on a chapter opening) and open a "Go To" sheet: every chapter in the feed, plus "Back to Week's Start" (or "Back to Reading's Start") in any reading, "Other Weeks" for weekly readings, and "Plan Details" in a plan. Back to the start keeps the reader's place underneath, so swiping up continues. Tapping the tab that's already open goes back to that tab's start. The Library's feed holds the whole book, so earlier chapters are reachable.
- Streak: the ribbon on Today (`StreakRibbon`) shows the count, or a small diamond with no streak going, so the calendar is always reachable. It opens "Your Streak" (`StreakCalendarView.swift`): the big count, a month calendar where days in a row join into one band, best streak, and days read. Past months go back to the first day read. Everything comes from the saved days on the phone. Gentle wording only, never guilt about a lost streak.
- All colors, fonts, and shared pieces live in `Versed/Features/Shared/AppColors.swift`, with surfaces in `Materials.swift` and icons in `Glyphs.swift`. The tab bar is `VersedTabBar.swift`, chapter numbers are `ChapterGrid.swift`, and top bar buttons are `VersedToolbar.swift`. New screens use these. Don't add new colors or one-off styles; if something's missing, add it there.

## Design audit
- `DesignAuditUITests` walks every screen and saves full-size pictures, in light or dark and at any text size. It only runs when `TEST_RUNNER_VERSED_AUDIT_DIR` is set, so it stays out of the normal test run.
- `test7LibrarySwipes` swipes through the Library's covers and back, for recording the change between books.
- `test6Motion` runs through the app's motion for a screen recording (`xcrun simctl io <device> recordVideo`). `Scripts/contact_sheet.swift` lays a recording's frames side by side, to check a transition frame by frame.
- After a design change, check the pictures and the frames, not just the code.

## Testing
- After a change, only run the tests related to it, then save to GitHub.
- Don't run the full test suite unless Peyton asks for it, or right before uploading a build to TestFlight or the App Store.
- Only take largest-text-size and dark-mode screenshots when a change affects how a screen looks, not for every change.

## Rules
- Scripture text is the base text only, from github.com/bcbooks/scriptures-json. It includes the 2013 edition's small spelling and punctuation fixes, which Peyton reviewed and decided to keep on Nov 5, 2026. Don't add the Church's footnotes, chapter summaries, or chapter and section headings without a license.
- Don't use the Church's name, logo, or "Come, Follow Me" as the app name, and nothing should look like an official Church app.
- "Come, Follow Me" is a Church trademark. Never use it as the name of a tab, button, or feature, with exceptions Peyton chose on Nov 5, 2026, knowing the Church or Apple could ask for a change. They look more official than before, and that's accepted:
  - The weekly plan is named "Come, Follow Me" (`WeeklyPlanName`) on Today, its setup screen, the plan picker, its details screen, and the Library's cover and "Your Library" (added Nov 6, 2026). The short notice ("Versed is an independent app, not made or endorsed by The Church of Jesus Christ of Latter-day Saints.") stays on setup, the picker, details, the end of the Library's week list, and "Your Library". Peyton chose on Nov 5, 2026 to take it off Today, knowing that shows the name large with no notice on that screen.
  - Those words live in `WeeklyPlanName`, so they're quick to change. Otherwise it appears only in one descriptive line (`AboutSection.independenceNotice`), shown in the About section of Settings and on the last page of the first-time intro: "The Come, Follow Me plan follows the published reading schedule of The Church of Jesus Christ of Latter-day Saints. Versed is an independent app and is not made, approved, or endorsed by The Church of Jesus Christ of Latter-day Saints." The lesson links (which contain "come-follow-me" in the web address) are fine.
- Youth safety: youth groups need two adult leaders, parents can see group activity, and there are no private messages between adults and youth.
- Collect as little user data as possible.
- Accessibility: feed pages use `ShrinkToFit` so text grows with the iPhone's text size but each page still fits on one screen. Use `.secondaryText` (not `.secondary`) for gray text so it stays readable. Respect Reduce Motion for any new animation. `AccessibilityUITests` runs Apple's accessibility audit on every screen in light and dark mode; anything it flags by mistake is listed, with the reason, in `isKnownException`. The audit misreads any grain behind text as poor contrast, so it runs with `-plain-surfaces` (colors only), and `TextureContrastTests` checks that text stays above 4.5:1 at the textures' strongest pixels.

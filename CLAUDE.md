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

Remaining:
9. Daily reading streak
10. Finish version 1: app icon, screenshots in the README, and a final check that everything works

## Rules
- Scripture text must come from a public-domain source. The current text is from github.com/bcbooks/scriptures-json (public domain). Don't use the Church's 2013 edition text, footnotes, or chapter summaries without a license.
- Don't use the Church's name, logo, or "Come, Follow Me" as the app name, and nothing should look like an official Church app.
- Youth safety: youth groups need two adult leaders, parents can see group activity, and there are no private messages between adults and youth.
- Collect as little user data as possible.

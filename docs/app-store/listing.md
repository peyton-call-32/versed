# App Store listing (draft)

Everything to paste into App Store Connect. Character limits are Apple's; counts are in brackets.

## App name [30 max]
**Versed: Scripture Feed** [22] (already created in App Store Connect)

## Subtitle [30 max]
Scripture, one verse at a time [30]

## Promotional text [170 max]
*Shown above the description. It can be changed anytime without a new version.*

Read a little every day. Swipe up for the next verse, save the ones you love, and pick up right where you left off. [115]

## Description [4,000 max]

Versed shows scripture one verse per screen. Swipe up for the next verse, like scrolling a feed, but with something worth reading.

It's made for Latter-day Saints who want to read a little every day. Versed opens straight to this week's reading from the weekly home-study schedule, so there's nothing to look up.

READ
• One verse per screen, with a title card at the start of each chapter
• Opens to this week's reading, or pick any other week from the menu
• See the full reading schedule, with each week's dates and chapters
• Browse every book and chapter of the Old Testament, New Testament, Book of Mormon, Doctrine and Covenants, and Pearl of Great Price
• Open each week's lesson in Gospel Library with one tap

KEEP GOING
• Double-tap a verse, or tap the heart, to save it
• Picks up right where you left off
• A daily reading streak
• An optional gentle daily reminder at the time you choose. It's off until you turn it on.

MADE FOR EVERYONE
• Works with the largest text sizes, VoiceOver, and Reduce Motion
• Light and dark mode

PRIVATE BY DESIGN
• No account, no ads, no tracking
• Reading works without the internet
• Everything stays on your phone

Versed is an independent app. It is not affiliated with, made, approved, or endorsed by The Church of Jesus Christ of Latter-day Saints. Scripture text is in the public domain.

## Keywords [100 max] — this list: 96
*Commas, no spaces. Words already in the name and subtitle count automatically, so they're left out.*

LDS,Book of Mormon,Bible,Doctrine and Covenants,Pearl of Great Price,KJV,devotional,study,gospel

Left out on purpose: "Come Follow Me" and the Church's name, which are the Church's trademarks. Apple can reject keywords that use other people's trademarks. The listing never uses "Come, Follow Me" as a name; the app mentions it only in one descriptive line (see the trademark rule in CLAUDE.md).

## What's New [4,000 max]
*Apple doesn't show this for a first version. Use it for 1.0.1 and later.*

First release: read scripture one verse at a time, with this week's reading ready when you open the app.

## Other fields
- **Primary category:** Reference
- **Secondary category:** Books
- **Privacy policy URL:** https://peyton-call-32.github.io/versed/privacy/
- **Support URL:** https://peyton-call-32.github.io/versed/support/
- **Copyright:** 2026 Peyton Call
- **Price:** Free
- **App Privacy:** Data Not Collected
- **Age rating:** 4+ (answer "None" or "No" to every question)

## Notes for the App Review team
Versed is an independent app. It is not affiliated with, made, approved, or endorsed by The Church of Jesus Christ of Latter-day Saints. It has no account or login, and works offline. To see the main features: swipe up on This Week to read, double-tap a verse to save it, then open the Saved tab. The gear on the Browse tab opens Settings. "Open This Week's Lesson", on the card after each week's last verse, links to the matching public lesson page on churchofjesuschrist.org. The scripture text is public domain (github.com/bcbooks/scriptures-json).

## Screenshots
In `screenshots/`, 1320 × 2868 (the 6.9-inch iPhone size Apple requires; it shrinks them for smaller iPhones). Upload in this order:
1. `1-verse.png`: a verse, with the heart to save it
2. `2-this-week.png`: this week's intro card
3. `3-browse.png`: Browse
4. `4-saved.png`: the Saved tab

To retake them: run `testCapturingAppStoreScreenshots` on the iPhone 18 Pro Max simulator with `TEST_RUNNER_SCREENSHOT_DIR` set to this folder, and the status bar set to 9:41 with a full battery (`xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --cellularMode active --cellularBars 4 --wifiBars 3`).

# Versed

An iPhone app for reading scripture one verse at a time. Swipe up for the next verse, like a short-video feed.

Built for Latter-day Saints who want to read a little every day. It opens straight to this week's Come, Follow Me reading.

> Status: in development.

## Features (version 1)
- One verse per screen, with a title card at the start of each chapter
- Opens to this week's reading; pick any other week from a menu
- Browse any book and chapter of the standard works
- Save verses with a double-tap or the heart button
- Picks up where you left off
- Daily reading streak

Everything stays on your phone. No account, no internet needed.

## Built with
- SwiftUI (iOS 17)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): the Xcode project is generated from `project.yml`

## Running it
Open `Versed.xcodeproj` in Xcode, pick an iPhone simulator, and press Run (⌘R).

After changing `project.yml`, run `xcodegen` to rebuild the project.

## Credits
Scripture text is public domain, from [bcbooks/scriptures-json](https://github.com/bcbooks/scriptures-json).

Versed is an independent project and is not affiliated with or endorsed by The Church of Jesus Christ of Latter-day Saints.

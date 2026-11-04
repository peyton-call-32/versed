import SwiftUI

/// Scripture text, with words printed in capitals set the way a printed Bible sets them:
/// "LORD" keeps a full-size L, and the rest of the word is in small capitals.
struct VerseText: View {
    private let text: AttributedString

    init(_ verse: String, size: CGFloat, relativeTo style: Font.TextStyle) {
        text = Self.styled(
            verse,
            font: .versedVerse(size: size, relativeTo: style),
            smallCapsFont: .versedVerse(size: size * Self.smallCapsScale, relativeTo: style)
        )
    }

    var body: some View {
        Text(text)
    }

    /// How large a small capital is next to a full capital.
    private static let smallCapsScale = 0.76

    /// Finds the parts of a verse to set in small capitals: every letter after the first of a word
    /// in all capitals. So "the LORD GOD" gives "ORD" and "OD".
    nonisolated static func smallCapsRanges(in verse: String) -> [Range<String.Index>] {
        verse.matches(of: /\b[A-Z]([A-Z]+)\b/).map(\.output.1).map { $0.startIndex..<$0.endIndex }
    }

    private static func styled(_ verse: String, font: Font, smallCapsFont: Font) -> AttributedString {
        var result = AttributedString()
        var position = verse.startIndex
        for range in smallCapsRanges(in: verse) {
            var plain = AttributedString(verse[position..<range.lowerBound])
            plain.font = font
            var small = AttributedString(verse[range])
            small.font = smallCapsFont
            small.tracking = 0.5
            result += plain
            result += small
            position = range.upperBound
        }
        var rest = AttributedString(verse[position...])
        rest.font = font
        result += rest
        return result
    }
}

#Preview {
    VerseText("The LORD hath appeared of old unto me.", size: 33, relativeTo: .title)
        .padding()
}

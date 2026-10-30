import SwiftUI

/// One verse, filling the screen.
struct VerseCard: View {
    let verse: Verse

    var body: some View {
        VStack(spacing: 20) {
            Text(verse.text)
                .font(.system(textStyle, design: .serif))
                .lineSpacing(6)
                .minimumScaleFactor(0.6)

            Text(verse.reference)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .padding(.vertical, 96)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Shorter verses get bigger text so every verse fills the screen comfortably.
    private var textStyle: Font.TextStyle {
        switch verse.text.count {
        case ..<160: .title
        case ..<360: .title2
        case ..<600: .title3
        default: .body
        }
    }
}

#Preview {
    VerseCard(verse: Verse(
        id: VerseID(bookID: "1-ne", chapter: 3, verse: 7),
        bookName: "1 Nephi",
        text: "And it came to pass that I, Nephi, said unto my father: I will go and do the things which the Lord hath commanded, for I know that the Lord giveth no commandments unto the children of men, save he shall prepare a way for them that they may accomplish the thing which he commandeth them."
    ))
}

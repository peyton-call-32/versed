import SwiftUI

/// The About part of Settings: who made the app, where the text comes from, privacy, and contact.
struct AboutSection: View {
    static let scriptureSourceURL = URL(string: "https://github.com/bcbooks/scriptures-json")!
    static let privacyPolicyURL = URL(string: "https://peyton-call-32.github.io/versed/privacy/")!
    static let contactEmail = "peytoncall32@icloud.com"

    /// The only place the app names the Come, Follow Me schedule: a plain description, never a name
    /// for a tab, button, screen, or feature. Also shown on the last page of the first-time intro.
    static let independenceNotice = "This Week follows the Come, Follow Me reading schedule. Versed is an independent app and is not made, approved, or endorsed by The Church of Jesus Christ of Latter-day Saints."

    /// "1.0 (1)": the version people see in the App Store, then the build number.
    static func versionText(bundle: Bundle = .main) -> String {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(version) (\(build))"
    }

    var body: some View {
        CardSection(
            title: "About",
            footer: "Scripture text is in the public domain. Versed collects no data: everything stays on your phone, with no accounts, ads, or tracking."
        ) {
            Text(Self.independenceNotice)
                .font(.footnote)
                .foregroundStyle(.secondaryText)
                .cardRowPadding()

            CardDivider()
            Link(destination: Self.scriptureSourceURL) {
                CardRowLabel(title: "Scripture Text", detail: "bcbooks/scriptures-json", symbol: CardRowLabel.externalLinkSymbol)
            }
            .buttonStyle(.cardRow)
            .accessibilityHint("Public domain. Opens the source in Safari.")

            CardDivider()
            Link(destination: Self.privacyPolicyURL) {
                CardRowLabel(title: "Privacy Policy", symbol: CardRowLabel.externalLinkSymbol)
            }
            .buttonStyle(.cardRow)

            CardDivider()
            Link(destination: URL(string: "mailto:\(Self.contactEmail)")!) {
                CardRowLabel(title: "Contact", detail: Self.contactEmail, symbol: CardRowLabel.externalLinkSymbol)
            }
            .buttonStyle(.cardRow)

            CardDivider()
            CardRowLabel(title: "Version", detail: Self.versionText(), symbol: nil)
        }
    }
}

#Preview {
    ScrollView { AboutSection().padding() }
}

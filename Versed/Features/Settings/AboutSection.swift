import SwiftUI

/// The About part of Settings: who made the app, where the text comes from, privacy, and contact.
struct AboutSection: View {
    static let scriptureSourceURL = URL(string: "https://github.com/bcbooks/scriptures-json")!
    static let privacyPolicyURL = URL(string: "https://peyton-call-32.github.io/versed/privacy/")!
    static let contactEmail = "peytoncall32@icloud.com"

    /// A plain description of the Come, Follow Me plan. Also shown on the last page of the first-time
    /// intro. The other places the app uses the name are the weekly plan (`WeeklyPlanName`) and the
    /// plan's own title, which come with the cover's short notice.
    static let independenceNotice = "The Come, Follow Me plan follows the published reading schedule of The Church of Jesus Christ of Latter-day Saints. Versed is an independent app and is not made, approved, or endorsed by The Church of Jesus Christ of Latter-day Saints."

    /// "1.0 (1)": the version people see in the App Store, then the build number.
    static func versionText(bundle: Bundle = .main) -> String {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(version) (\(build))"
    }

    var body: some View {
        LedgerSection(
            title: "About",
            footer: "Scripture text is in the public domain. Versed collects no data: everything stays on your phone, with no accounts, ads, or tracking."
        ) {
            Text(Self.independenceNotice)
                .font(.versedNote)
                .foregroundStyle(.secondaryText)
                .ledgerRowPadding()

            LedgerRule()
            Link(destination: Self.scriptureSourceURL) {
                LedgerRowLabel(title: "Scripture Text", detail: "bcbooks/scriptures-json", symbol: LedgerRowLabel.externalLinkSymbol)
            }
            .buttonStyle(.ledgerRow)
            .accessibilityHint("Public domain. Opens the source in Safari.")

            LedgerRule()
            Link(destination: Self.privacyPolicyURL) {
                LedgerRowLabel(title: "Privacy Policy", symbol: LedgerRowLabel.externalLinkSymbol)
            }
            .buttonStyle(.ledgerRow)

            LedgerRule()
            Link(destination: URL(string: "mailto:\(Self.contactEmail)")!) {
                LedgerRowLabel(title: "Contact", detail: Self.contactEmail, symbol: LedgerRowLabel.externalLinkSymbol)
            }
            .buttonStyle(.ledgerRow)

            LedgerRule()
            LedgerRowLabel(title: "Version", detail: Self.versionText(), symbol: nil)
        }
    }
}

#Preview {
    ScrollView { AboutSection().padding() }
}

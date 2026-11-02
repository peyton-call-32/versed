import SwiftUI

/// The small arrow at the end of a list row, for rows that are buttons rather than links
/// but still take the reader somewhere.
struct DisclosureChevron: View {
    var body: some View {
        Image(systemName: "chevron.forward")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondaryText)
            .accessibilityHidden(true)
    }
}

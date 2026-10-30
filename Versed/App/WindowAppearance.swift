import SwiftUI
import UIKit

extension View {
    /// Forces light or dark mode on the whole window, including sheets, or follows the phone.
    ///
    /// SwiftUI's `preferredColorScheme` doesn't reach sheets reliably and can get stuck after
    /// switching back to `nil`, so this sets the window's style directly.
    func windowAppearance(_ appearance: Appearance) -> some View {
        onChange(of: appearance, initial: true) { _, appearance in
            let windows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
            for window in windows {
                window.overrideUserInterfaceStyle = appearance.interfaceStyle
            }
        }
    }
}

private extension Appearance {
    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .matchPhone: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }
}

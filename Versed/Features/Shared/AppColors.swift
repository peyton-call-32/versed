import SwiftUI

extension ShapeStyle where Self == Color {
    /// Gray for less important text. Darker than the system's secondary gray in light mode
    /// (and lighter in dark mode) so small text stays easy to read.
    static var secondaryText: Color { Color("SecondaryText") }
}

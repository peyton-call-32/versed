import SwiftUI

/// Chapter numbers set in ruled rows, used by the Library and by the Go To sheet.
/// Grows with the reader's text size so big numbers still fit.
struct ChapterGrid<Cell: View>: View {
    let chapters: [Int]
    @ViewBuilder let cell: (Int) -> Cell

    @ScaledMetric(relativeTo: .title2) private var cellSize = 54.0

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: cellSize), spacing: 0)], spacing: 0) {
            ForEach(chapters, id: \.self) { chapter in
                cell(chapter)
                    .frame(minHeight: cellSize)
                    .overlay(alignment: .bottom) { Rule() }
            }
        }
        .overlay(alignment: .top) { Rule() }
    }
}

/// One chapter number. The current chapter is a solid navy block.
struct ChapterCellLabel: View {
    let chapter: Int
    var isCurrent = false

    var body: some View {
        Text("\(chapter)")
            .font(.versedNumber(size: 25, relativeTo: .title2))
            .foregroundStyle(isCurrent ? Color("ProminentButtonLabel") : .brand)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if isCurrent {
                    Hardcover.corner.fill(Color("ProminentButton")).padding(4)
                }
            }
            .contentShape(Rectangle())
    }
}

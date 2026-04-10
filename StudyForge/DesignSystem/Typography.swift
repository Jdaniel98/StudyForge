import SwiftUI

enum Typography {
    static let caption = Font.system(.caption, design: .default)
    static let captionBold = Font.system(.caption, design: .default).bold()

    static let footnote = Font.system(.footnote, design: .default)

    static let body = Font.system(.body, design: .default)
    static let bodyBold = Font.system(.body, design: .default).bold()

    static let title3 = Font.system(.title3, design: .default)
    static let title3Bold = Font.system(.title3, design: .default).bold()

    static let title2 = Font.system(.title2, design: .default)
    static let title2Bold = Font.system(.title2, design: .default).bold()

    static let title = Font.system(.title, design: .default).bold()

    static let largeTitle = Font.system(.largeTitle, design: .default).bold()

    /// Monospaced font for the timer countdown display
    static let monoTimer = Font.system(size: 64, weight: .light, design: .monospaced)

    /// Smaller monospaced font for secondary timer displays (menu bar, compact views)
    static let monoTimerCompact = Font.system(size: 28, weight: .medium, design: .monospaced)

    /// Monospaced for stats numbers
    static let monoStats = Font.system(size: 20, weight: .semibold, design: .monospaced)
}

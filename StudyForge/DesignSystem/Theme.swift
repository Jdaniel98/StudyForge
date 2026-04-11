import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Semantic Color Tokens

enum Theme {
    // MARK: Surfaces
    static let surfacePrimary = adaptive(light: "FFFFFF", dark: "0F172A")
    static let surfaceSecondary = adaptive(light: "F8FAFC", dark: "1E293B")
    static let surfaceTertiary = adaptive(light: "F1F5F9", dark: "334155")

    // MARK: Accents
    static let accentFocus = Color(hex: "3B82F6")
    static let accentBreak = Color(hex: "10B981")
    static let accentWarning = Color(hex: "F59E0B")
    static let accentDestructive = Color(hex: "EF4444")

    // MARK: Text
    static let textPrimary = adaptive(light: "0F172A", dark: "F8FAFC")
    static let textSecondary = adaptive(light: "475569", dark: "CBD5E1")
    static let textMuted = adaptive(light: "94A3B8", dark: "64748B")

    // MARK: Borders
    static let borderSubtle = adaptive(light: "E2E8F0", dark: "1E293B")
    static let borderStrong = adaptive(light: "CBD5E1", dark: "475569")

    // MARK: Corner Radii
    static let radiusSmall: CGFloat = 6
    static let radiusMedium: CGFloat = 8
    static let radiusLarge: CGFloat = 12
    static let radiusXLarge: CGFloat = 20

    // MARK: Shadows
    static let shadowColor = Color.black.opacity(0.15)
    static let shadowRadius: CGFloat = 8
    static let shadowY: CGFloat = 2

    // MARK: - Adaptive Color Helper

    private static func adaptive(light lightHex: String, dark darkHex: String) -> Color {
        #if os(iOS)
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? darkHex : lightHex
            var rgb: UInt64 = 0
            Scanner(string: hex).scanHexInt64(&rgb)
            return UIColor(
                red: CGFloat((rgb >> 16) & 0xFF) / 255,
                green: CGFloat((rgb >> 8) & 0xFF) / 255,
                blue: CGFloat(rgb & 0xFF) / 255,
                alpha: 1
            )
        })
        #else
        Color(nsColor: NSColor(name: nil) { appearance in
            let hex = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? darkHex : lightHex
            var rgb: UInt64 = 0
            Scanner(string: hex).scanHexInt64(&rgb)
            return NSColor(
                red: CGFloat((rgb >> 16) & 0xFF) / 255,
                green: CGFloat((rgb >> 8) & 0xFF) / 255,
                blue: CGFloat(rgb & 0xFF) / 255,
                alpha: 1
            )
        })
        #endif
    }
}

// MARK: - Legacy Fallback Aliases (forward to adaptive static properties)

extension Theme {
    static func surfacePrimaryFallback(for _: ColorScheme) -> Color { surfacePrimary }
    static func surfaceSecondaryFallback(for _: ColorScheme) -> Color { surfaceSecondary }
    static func surfaceTertiaryFallback(for _: ColorScheme) -> Color { surfaceTertiary }
    static func textPrimaryFallback(for _: ColorScheme) -> Color { textPrimary }
    static func textSecondaryFallback(for _: ColorScheme) -> Color { textSecondary }
    static func textMutedFallback(for _: ColorScheme) -> Color { textMuted }
    static func borderSubtleFallback(for _: ColorScheme) -> Color { borderSubtle }
}

// MARK: - Subject Color Palette

enum SubjectColor: String, CaseIterable, Identifiable {
    case blue = "3B82F6"
    case amber = "F59E0B"
    case emerald = "10B981"
    case violet = "8B5CF6"
    case rose = "F43F5E"
    case cyan = "06B6D4"
    case orange = "F97316"
    case lime = "84CC16"
    case pink = "EC4899"
    case indigo = "6366F1"
    case teal = "14B8A6"
    case yellow = "EAB308"

    var id: String { rawValue }

    var color: Color { Color(hex: rawValue) }

    var name: String {
        switch self {
        case .blue: "Blue"
        case .amber: "Amber"
        case .emerald: "Emerald"
        case .violet: "Violet"
        case .rose: "Rose"
        case .cyan: "Cyan"
        case .orange: "Orange"
        case .lime: "Lime"
        case .pink: "Pink"
        case .indigo: "Indigo"
        case .teal: "Teal"
        case .yellow: "Yellow"
        }
    }

    /// Default color for a given category
    static func defaultColor(for category: SubjectCategory) -> SubjectColor {
        switch category {
        case .mathematics: .blue
        case .csTheory: .amber
        case .finance: .emerald
        case .machineLearning: .violet
        case .systemsProgramming: .rose
        case .languageLearning: .cyan
        case .science: .teal
        case .humanities: .pink
        case .custom: .indigo
        }
    }
}

// MARK: - Subject Categories

enum SubjectCategory: String, CaseIterable, Identifiable {
    case mathematics = "Mathematics"
    case csTheory = "CS Theory"
    case finance = "Finance"
    case machineLearning = "Machine Learning"
    case systemsProgramming = "Systems Programming"
    case languageLearning = "Language Learning"
    case science = "Science"
    case humanities = "Humanities"
    case custom = "Custom"

    var id: String { rawValue }

    var defaultIcon: String {
        switch self {
        case .mathematics: "function"
        case .csTheory: "cpu"
        case .finance: "chart.line.uptrend.xyaxis"
        case .machineLearning: "brain"
        case .systemsProgramming: "terminal"
        case .languageLearning: "character.book.closed"
        case .science: "atom"
        case .humanities: "text.book.closed"
        case .custom: "book.fill"
        }
    }
}

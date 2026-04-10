import SwiftUI

// MARK: - Semantic Color Tokens

enum Theme {
    // MARK: Surfaces
    static let surfacePrimary = Color("SurfacePrimary")
    static let surfaceSecondary = Color("SurfaceSecondary")
    static let surfaceTertiary = Color("SurfaceTertiary")

    // MARK: Accents
    static let accentFocus = Color("AccentFocus")
    static let accentBreak = Color("AccentBreak")
    static let accentWarning = Color("AccentWarning")
    static let accentDestructive = Color("AccentDestructive")

    // MARK: Text
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textMuted = Color("TextMuted")

    // MARK: Borders
    static let borderSubtle = Color("BorderSubtle")
    static let borderStrong = Color("BorderStrong")

    // MARK: Corner Radii
    static let radiusSmall: CGFloat = 6
    static let radiusMedium: CGFloat = 8
    static let radiusLarge: CGFloat = 12
    static let radiusXLarge: CGFloat = 20

    // MARK: Shadows
    static let shadowColor = Color.black.opacity(0.15)
    static let shadowRadius: CGFloat = 8
    static let shadowY: CGFloat = 2
}

// MARK: - Fallback Colors (used until Asset Catalog is set up)

extension Theme {
    static func surfacePrimaryFallback(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "0F172A") : Color(hex: "FFFFFF")
    }

    static func surfaceSecondaryFallback(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1E293B") : Color(hex: "F8FAFC")
    }

    static func surfaceTertiaryFallback(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "334155") : Color(hex: "F1F5F9")
    }

    static func textPrimaryFallback(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "F8FAFC") : Color(hex: "0F172A")
    }

    static func textSecondaryFallback(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "CBD5E1") : Color(hex: "475569")
    }

    static func textMutedFallback(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "64748B") : Color(hex: "94A3B8")
    }

    static func borderSubtleFallback(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1E293B") : Color(hex: "E2E8F0")
    }
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

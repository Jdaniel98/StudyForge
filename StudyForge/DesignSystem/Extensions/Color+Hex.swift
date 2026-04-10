import SwiftUI

extension Color {
    /// Creates a Color from a hex string (e.g. "3B82F6" or "#3B82F6")
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }

    /// Returns the hex string representation of this color
    func toHex() -> String? {
        guard let components = cgColor?.components, components.count >= 3 else {
            return nil
        }

        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)

        return String(format: "%02X%02X%02X", r, g, b)
    }
}

#if canImport(UIKit)
import UIKit

extension Color {
    var cgColor: CGColor? {
        UIColor(self).cgColor
    }
}
#elseif canImport(AppKit)
import AppKit

extension Color {
    var cgColor: CGColor? {
        NSColor(self).cgColor
    }
}
#endif

//
//  Color+Hex.swift
//  minimalist_todo
//
//  Hex <-> Color conversion utilities used by the accent-color and
//  category-color systems. Keeps colour persistence simple: we store a
//  hex string in Core Data / UserDefaults and rehydrate a `Color`.
//

import SwiftUI

extension Color {
    /// Creates a colour from a hex string such as `#0A84FF`, `0A84FF`,
    /// `#FFF`, or an 8-digit ARGB value. Falls back to clear on bad input.
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: sanitized).scanHexInt64(&rgb) else {
            self = .clear
            return
        }

        let r, g, b, a: Double
        switch sanitized.count {
        case 3: // RGB (12-bit)
            r = Double((rgb >> 8) & 0xF) / 15
            g = Double((rgb >> 4) & 0xF) / 15
            b = Double(rgb & 0xF) / 15
            a = 1
        case 6: // RRGGBB (24-bit)
            r = Double((rgb >> 16) & 0xFF) / 255
            g = Double((rgb >> 8) & 0xFF) / 255
            b = Double(rgb & 0xFF) / 255
            a = 1
        case 8: // AARRGGBB (32-bit)
            a = Double((rgb >> 24) & 0xFF) / 255
            r = Double((rgb >> 16) & 0xFF) / 255
            g = Double((rgb >> 8) & 0xFF) / 255
            b = Double(rgb & 0xFF) / 255
        default:
            self = .clear
            return
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Serialises the colour back to a `#RRGGBB` string for persistence.
    var hexString: String {
        let resolved = UIColor(self).resolvedColor(with: .current)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X",
                      Int(round(r * 255)),
                      Int(round(g * 255)),
                      Int(round(b * 255)))
    }
}

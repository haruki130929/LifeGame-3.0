import SwiftUI

extension Color {
    init(hex: String, fallback: Color = .gray) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        
        guard cleaned.count == 6,
              let value = Int(cleaned, radix: 16) else {
            self = fallback
            return
        }
        
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}

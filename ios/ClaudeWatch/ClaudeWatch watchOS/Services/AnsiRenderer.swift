import SwiftUI

/// Turns a terminal screen containing ANSI SGR escape codes into an
/// AttributedString so the watch shows the real TUI colors (Claude Code's
/// coral banner, blue menu entries, etc). Foreground + bold only — that's
/// what reads at wrist size; unknown sequences are stripped.
enum AnsiRenderer {
    static func render(_ text: String) -> AttributedString {
        var out = AttributedString()
        var currentColor: Color? = nil
        var currentBold = false

        var plain = ""
        func flush() {
            guard !plain.isEmpty else { return }
            var chunk = AttributedString(plain)
            chunk.foregroundColor = currentColor ?? Color.white.opacity(0.9)
            if currentBold {
                chunk.font = .system(size: 9, weight: .bold, design: .monospaced)
            }
            out += chunk
            plain = ""
        }

        var i = text.startIndex
        while i < text.endIndex {
            let ch = text[i]
            if ch == "\u{1B}" {
                // Escape sequence: CSI ... final-byte
                var j = text.index(after: i)
                if j < text.endIndex, text[j] == "[" {
                    j = text.index(after: j)
                    var params = ""
                    while j < text.endIndex, text[j].isNumber || text[j] == ";" {
                        params.append(text[j])
                        j = text.index(after: j)
                    }
                    if j < text.endIndex {
                        if text[j] == "m" {
                            flush()
                            apply(params, color: &currentColor, bold: &currentBold)
                        }
                        i = text.index(after: j) // skip any CSI, rendered or not
                        continue
                    }
                }
                i = text.index(after: i) // lone ESC — drop it
                continue
            }
            plain.append(ch)
            i = text.index(after: i)
        }
        flush()
        return out
    }

    private static func apply(_ params: String, color: inout Color?, bold: inout Bool) {
        let codes = params.split(separator: ";").compactMap { Int($0) }
        var idx = 0
        if codes.isEmpty { color = nil; bold = false; return } // ESC[m == reset
        while idx < codes.count {
            let c = codes[idx]
            switch c {
            case 0: color = nil; bold = false
            case 1: bold = true
            case 22: bold = false
            case 30...37: color = standard[c - 30]
            case 39: color = nil
            case 90...97: color = bright[c - 90]
            case 38 where idx + 2 < codes.count && codes[idx + 1] == 5:
                color = xterm256(codes[idx + 2])
                idx += 2
            case 38 where idx + 4 < codes.count && codes[idx + 1] == 2:
                color = Color(
                    red: Double(codes[idx + 2]) / 255.0,
                    green: Double(codes[idx + 3]) / 255.0,
                    blue: Double(codes[idx + 4]) / 255.0
                )
                idx += 4
            case 48: // background — swallow its color argument, don't render
                if idx + 2 < codes.count && codes[idx + 1] == 5 { idx += 2 }
                else if idx + 4 < codes.count && codes[idx + 1] == 2 { idx += 4 }
            default: break
            }
            idx += 1
        }
    }

    private static let standard: [Color] = [
        Color(white: 0.2), Color(red: 0.8, green: 0.25, blue: 0.25),
        Color(red: 0.3, green: 0.75, blue: 0.4), Color(red: 0.85, green: 0.75, blue: 0.3),
        Color(red: 0.35, green: 0.55, blue: 0.95), Color(red: 0.75, green: 0.45, blue: 0.85),
        Color(red: 0.3, green: 0.75, blue: 0.8), Color(white: 0.85),
    ]
    private static let bright: [Color] = [
        Color(white: 0.5), Color(red: 1.0, green: 0.4, blue: 0.4),
        Color(red: 0.45, green: 0.9, blue: 0.55), Color(red: 1.0, green: 0.9, blue: 0.45),
        Color(red: 0.5, green: 0.7, blue: 1.0), Color(red: 0.9, green: 0.6, blue: 1.0),
        Color(red: 0.45, green: 0.9, blue: 0.95), .white,
    ]

    private static func xterm256(_ n: Int) -> Color {
        switch n {
        case 0...7: return standard[n]
        case 8...15: return bright[n - 8]
        case 16...231:
            let v = n - 16
            let levels: [Double] = [0, 95, 135, 175, 215, 255]
            return Color(
                red: levels[v / 36] / 255.0,
                green: levels[(v / 6) % 6] / 255.0,
                blue: levels[v % 6] / 255.0
            )
        case 232...255:
            let g = Double(8 + (n - 232) * 10) / 255.0
            return Color(red: g, green: g, blue: g)
        default: return .white
        }
    }
}

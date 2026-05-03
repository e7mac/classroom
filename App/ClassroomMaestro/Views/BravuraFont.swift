import SwiftUI
import CoreText
#if os(macOS)
import AppKit
#else
import UIKit
#endif

enum BravuraFont {
    static let name = "Bravura"

    enum Glyph {
        static let trebleClef    = "\u{E050}"
        static let bassClef      = "\u{E062}"
        static let sharp         = "\u{E262}"
        static let flat          = "\u{E260}"
        static let natural       = "\u{E261}"
        static let doubleSharp   = "\u{E263}"
        static let doubleFlat    = "\u{E264}"
        static let noteheadBlack = "\u{E0A4}"
    }

    /// Translate a unicode music-symbol char (♯/♭/♮/𝄪/𝄫) to the SMuFL equivalent.
    /// Falls back to the input if not recognized.
    static func smufl(forAccidentalSymbol symbol: String) -> String {
        switch symbol {
        case "♯": return Glyph.sharp
        case "♭": return Glyph.flat
        case "♮": return Glyph.natural
        case "𝄪": return Glyph.doubleSharp
        case "𝄫": return Glyph.doubleFlat
        default:  return symbol
        }
    }

    /// Idempotent. Info.plist's ATSApplicationFontsPath (macOS) and UIAppFonts (iOS)
    /// handle bundle font loading for the app at launch, but Xcode previews can
    /// miss that — register manually.
    static func registerIfNeeded() {
        #if os(macOS)
        let alreadyRegistered = NSFontManager.shared.availableFonts.contains(name)
        #else
        let alreadyRegistered = UIFont.familyNames.contains(name)
            || UIFont.fontNames(forFamilyName: name).contains(name)
        #endif
        guard !alreadyRegistered else { return }
        guard let url = Bundle.main.url(forResource: name, withExtension: "otf") else { return }
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
    }
}

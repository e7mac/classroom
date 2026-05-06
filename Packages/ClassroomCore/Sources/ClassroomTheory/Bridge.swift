@_exported import MusicTheory

/// Back-compat alias — Classroom historically used `Note` for what
/// MusicCore calls `Pitch`. Field-for-field identical.
public typealias Note = Pitch

public extension Accidental {
    /// Full Unicode glyph for engraving accidentals on a staff —
    /// includes `♮` for explicit naturals. MusicCore's
    /// `.displaySymbol` returns "" for natural (correct for ordinary
    /// pitch labels like "C4"); use `.engravingSymbol` when rendering
    /// staff accidentals where the natural sign is visible.
    var engravingSymbol: String {
        self == .natural ? "♮" : displaySymbol
    }
}

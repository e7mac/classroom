import Foundation
import CoreGraphics

public enum WidgetKind: String, CaseIterable, Sendable, Codable, Identifiable, Hashable {
    case staff
    case keyboard
    case analysis
    case grandStaff
    case combo

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .staff:      return "Staff"
        case .keyboard:   return "Keyboard"
        case .analysis:   return "Analysis"
        case .grandStaff: return "Grand Staff"
        case .combo:      return "Combo"
        }
    }

    public var defaultSize: CGSize {
        switch self {
        case .staff:      return CGSize(width: 320, height: 160)
        case .keyboard:   return CGSize(width: 400, height: 100)
        case .analysis:   return CGSize(width: 200, height: 80)
        case .grandStaff: return CGSize(width: 320, height: 220)
        case .combo:      return CGSize(width: 320, height: 280)
        }
    }

    public var minSize: CGSize {
        switch self {
        case .staff:      return CGSize(width: 200, height: 100)
        case .keyboard:   return CGSize(width: 200, height: 60)
        case .analysis:   return CGSize(width: 120, height: 60)
        case .grandStaff: return CGSize(width: 200, height: 140)
        case .combo:      return CGSize(width: 200, height: 200)
        }
    }

    public var sfSymbol: String {
        switch self {
        case .staff:      return "music.note"
        case .keyboard:   return "pianokeys"
        case .analysis:   return "text.magnifyingglass"
        case .grandStaff: return "music.note.list"
        case .combo:      return "rectangle.split.1x2"
        }
    }
}

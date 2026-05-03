import Foundation

public struct RomanNumeral: Hashable, Sendable {
    public let symbol: String
    public let inversionFigure: String?
    public let qualityModifier: String?

    public init(symbol: String, qualityModifier: String? = nil, inversionFigure: String? = nil) {
        self.symbol = symbol
        self.qualityModifier = qualityModifier
        self.inversionFigure = inversionFigure
    }

    public var displayString: String {
        var result = symbol
        if let qualityModifier {
            result += qualityModifier
        }
        if let inversionFigure {
            result += inversionFigure
        }
        return result
    }
}

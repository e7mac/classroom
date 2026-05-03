import SwiftUI
import AppKit
import MusicRendering
import AppCore

public struct KeyboardView: View {
    public let pressedMIDI: Set<Int>
    public let staccatoMIDI: Set<Int>
    public let handPosition: HandPosition?
    public let lowMIDI: Int
    public let highMIDI: Int
    public let pressedColor: Color
    public let isHidden: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        pressedMIDI: Set<Int> = [],
        staccatoMIDI: Set<Int> = [],
        handPosition: HandPosition? = nil,
        lowMIDI: Int = 48,
        highMIDI: Int = 84,
        pressedColor: Color = .accentColor,
        isHidden: Bool = false
    ) {
        self.pressedMIDI = pressedMIDI
        self.staccatoMIDI = staccatoMIDI
        self.handPosition = handPosition
        self.lowMIDI = lowMIDI
        self.highMIDI = highMIDI
        self.pressedColor = pressedColor
        self.isHidden = isHidden
    }

    public var body: some View {
        if isHidden {
            emptyPlaceholder
                .accessibilityLabel(accessibilityDescription)
        } else {
            GeometryReader { proxy in
                let availableWidth = proxy.size.width
                let availableHeight = proxy.size.height
                let intrinsicWidth = computedKeyboardWidth(forHeight: availableHeight)
                let needsScroll = intrinsicWidth > availableWidth

                if needsScroll {
                    ScrollView(.horizontal, showsIndicators: false) {
                        keyboardCanvas(width: intrinsicWidth, height: availableHeight)
                            .frame(width: intrinsicWidth, height: availableHeight)
                    }
                } else {
                    keyboardCanvas(width: availableWidth, height: availableHeight)
                }
            }
            .frame(minHeight: 80)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityDescription)
        }
    }

    // White-key aspect ratio: ~1:5 (height:width) for a tighter on-screen
    // appearance than the real-world ~1:6.4 ratio.
    private func computedKeyboardWidth(forHeight height: CGFloat) -> CGFloat {
        let whiteCount = KeyboardLayout.whiteKeyCount(from: lowMIDI, to: highMIDI)
        let whiteWidth = max(20, height / 5)
        return CGFloat(whiteCount) * whiteWidth
    }

    @ViewBuilder
    private func keyboardCanvas(width: CGFloat, height: CGFloat) -> some View {
        Canvas(rendersAsynchronously: false) { context, size in
            drawKeyboard(in: &context, size: size)
        }
        .frame(width: width, height: height)
        .background(keyboardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 2)
        .animation(.reduceMotionAware(.easeOut(duration: 0.08), reduceMotion: reduceMotion), value: pressedMIDI)
        .animation(.reduceMotionAware(.easeOut(duration: 0.08), reduceMotion: reduceMotion), value: staccatoMIDI)
    }

    // MARK: - Theme-aware colors

    private var keyboardBackground: Color {
        // Dark "felt strip" sliver visible above the keys (the rest is hidden by the keys).
        Color(NSColor.black).opacity(0.7)
    }

    private var whiteKeyTopColor: Color { Color(white: 1.0) }
    private var whiteKeyBottomColor: Color { Color(red: 0.96, green: 0.95, blue: 0.92) }   // warm ivory
    private var whiteKeyPressedTopColor: Color { Color(red: 0.86, green: 0.90, blue: 0.98) }
    private var whiteKeyPressedBottomColor: Color { Color(red: 0.72, green: 0.80, blue: 0.94) }
    private var whiteKeySeparatorColor: Color { Color.black.opacity(0.18) }

    private var blackKeyTopColor: Color { Color(white: 0.18) }
    private var blackKeyBottomColor: Color { Color(white: 0.04) }
    private var blackKeyPressedTopColor: Color { Color(red: 0.30, green: 0.45, blue: 0.65) }
    private var blackKeyPressedBottomColor: Color { Color(red: 0.10, green: 0.20, blue: 0.40) }
    private var blackKeyHighlightColor: Color { Color.white.opacity(0.18) }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        if isHidden { return "Keyboard hidden" }
        if pressedMIDI.isEmpty { return "Keyboard, no keys pressed" }
        let names = pressedMIDI.sorted().map(midiName).joined(separator: ", ")
        return "Keyboard, pressed: \(names)"
    }

    private func midiName(_ midi: Int) -> String {
        let pc = midi % 12
        let octave = midi / 12 - 1
        let names = ["C", "C-sharp", "D", "E-flat", "E", "F", "F-sharp", "G", "A-flat", "A", "B-flat", "B"]
        return "\(names[pc])\(octave)"
    }

    private func drawKeyboard(in context: inout GraphicsContext, size: CGSize) {
        let totalWidth = size.width
        let totalHeight = size.height

        // White keys first.
        for midi in lowMIDI...highMIDI {
            guard !KeyboardLayout.isBlackKey(midi) else { continue }
            let rect = KeyboardLayout.keyRect(
                for: midi,
                lowMIDI: lowMIDI,
                highMIDI: highMIDI,
                totalWidth: totalWidth,
                totalHeight: totalHeight
            )
            drawWhiteKey(rect: rect, midi: midi, in: &context)
        }

        // Then black keys on top.
        for midi in lowMIDI...highMIDI {
            guard KeyboardLayout.isBlackKey(midi) else { continue }
            let rect = KeyboardLayout.keyRect(
                for: midi,
                lowMIDI: lowMIDI,
                highMIDI: highMIDI,
                totalWidth: totalWidth,
                totalHeight: totalHeight
            )
            drawBlackKey(rect: rect, midi: midi, in: &context)
        }

        if let handPosition,
           let bracketRect = KeyboardLayout.handPositionBracket(
                startMIDI: handPosition.startMIDI,
                fingerCount: handPosition.fingerCount,
                lowMIDI: lowMIDI,
                highMIDI: highMIDI,
                totalWidth: totalWidth,
                totalHeight: totalHeight
           )
        {
            drawHandBracket(in: &context, rect: bracketRect, fingerCount: handPosition.fingerCount)
        }

        drawOctaveLabels(in: &context, size: size)
    }

    private func drawWhiteKey(rect: CGRect, midi: Int, in context: inout GraphicsContext) {
        let isPressed = pressedMIDI.contains(midi)
        let isStaccato = staccatoMIDI.contains(midi)

        // Thin gap between adjacent white keys for the felt-strip look.
        let inset = rect.insetBy(dx: 0.5, dy: 0)
        let bodyShape = RoundedRectangle(cornerRadius: 3, style: .continuous)
        let path = bodyShape.path(in: inset)

        let topColor = isPressed ? whiteKeyPressedTopColor : whiteKeyTopColor
        let bottomColor = isPressed ? whiteKeyPressedBottomColor : whiteKeyBottomColor

        let gradient = Gradient(colors: [topColor, bottomColor])
        context.fill(
            path,
            with: .linearGradient(
                gradient,
                startPoint: CGPoint(x: inset.midX, y: inset.minY),
                endPoint: CGPoint(x: inset.midX, y: inset.maxY)
            )
        )

        // Subtle pressed-in shadow at the top edge.
        if isPressed {
            let shadowRect = CGRect(x: inset.minX, y: inset.minY, width: inset.width, height: 4)
            context.fill(Path(shadowRect), with: .color(.black.opacity(0.18)))
        }

        // Staccato glow overlay.
        if isStaccato && !isPressed {
            context.fill(path, with: .color(pressedColor.opacity(0.35)))
        }

        // Vertical separator on the right edge.
        var sep = Path()
        sep.move(to: CGPoint(x: rect.maxX - 0.5, y: rect.minY))
        sep.addLine(to: CGPoint(x: rect.maxX - 0.5, y: rect.maxY))
        context.stroke(sep, with: .color(whiteKeySeparatorColor), lineWidth: 0.5)
    }

    private func drawBlackKey(rect: CGRect, midi: Int, in context: inout GraphicsContext) {
        let isPressed = pressedMIDI.contains(midi)
        let isStaccato = staccatoMIDI.contains(midi)

        // Black keys are slightly inset and have rounded bottom corners.
        let inset = rect.insetBy(dx: 0.5, dy: 0)
        let bodyShape = UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: 0,
                bottomLeading: 3,
                bottomTrailing: 3,
                topTrailing: 0
            ),
            style: .continuous
        )
        let path = bodyShape.path(in: inset)

        let topColor = isPressed ? blackKeyPressedTopColor : blackKeyTopColor
        let bottomColor = isPressed ? blackKeyPressedBottomColor : blackKeyBottomColor

        let gradient = Gradient(colors: [topColor, bottomColor])
        context.fill(
            path,
            with: .linearGradient(
                gradient,
                startPoint: CGPoint(x: inset.midX, y: inset.minY),
                endPoint: CGPoint(x: inset.midX, y: inset.maxY)
            )
        )

        // Specular highlight on the top face for the bevel feel.
        let highlightRect = CGRect(
            x: inset.minX + 1,
            y: inset.minY,
            width: inset.width - 2,
            height: max(2, inset.height * 0.06)
        )
        context.fill(Path(highlightRect), with: .color(blackKeyHighlightColor))

        // Soft shadow under the key onto the white keys below.
        let shadowRect = CGRect(
            x: rect.minX,
            y: rect.maxY - 1,
            width: rect.width,
            height: 2
        )
        context.fill(Path(shadowRect), with: .color(.black.opacity(0.25)))

        if isStaccato && !isPressed {
            context.fill(path, with: .color(pressedColor.opacity(0.4)))
        }
    }

    private func drawHandBracket(in context: inout GraphicsContext, rect: CGRect, fingerCount: Int) {
        let strokeColor = Color.orange.opacity(0.85)
        let fillColor = Color.orange.opacity(0.10)

        let shape = RoundedRectangle(cornerRadius: 4)
        let path = shape.path(in: rect)
        context.fill(path, with: .color(fillColor))
        context.stroke(path, with: .color(strokeColor), lineWidth: 2)

        let whiteWidth = rect.width / CGFloat(fingerCount)
        for i in 0..<fingerCount {
            let centerX = rect.minX + whiteWidth * (CGFloat(i) + 0.5)
            let label = "\(i + 1)"
            let txt = context.resolve(
                Text(label)
                    .font(.system(size: min(14, rect.height * 0.12), weight: .semibold))
                    .foregroundColor(.orange)
            )
            context.draw(txt, at: CGPoint(x: centerX, y: rect.minY + 8), anchor: .top)
        }
    }

    private func drawOctaveLabels(in context: inout GraphicsContext, size: CGSize) {
        for midi in lowMIDI...highMIDI {
            guard midi % 12 == 0 else { continue }
            let rect = KeyboardLayout.keyRect(
                for: midi,
                lowMIDI: lowMIDI,
                highMIDI: highMIDI,
                totalWidth: size.width,
                totalHeight: size.height
            )
            let octave = midi / 12 - 1
            let label = "C\(octave)"
            // 0.45 keeps the C-label comfortably narrower than the white key.
            let fontSize = min(11, rect.width * 0.45)
            guard fontSize >= 8 else { return }
            let txt = context.resolve(
                Text(label)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(Color(white: 0.35))
            )
            context.draw(txt, at: CGPoint(x: rect.midX, y: rect.maxY - 6), anchor: .bottom)
        }
    }

    private var emptyPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.secondary.opacity(0.08))
            .overlay(
                Text("Keyboard hidden")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14, weight: .medium))
            )
            .frame(minHeight: 80)
    }
}

#Preview("Empty 3-octave") {
    KeyboardView()
        .frame(width: 600, height: 120)
        .padding()
}

#Preview("C major triad pressed") {
    KeyboardView(pressedMIDI: [60, 64, 67])
        .frame(width: 600, height: 120)
        .padding()
}

#Preview("Staccato + pressed mix") {
    KeyboardView(
        pressedMIDI: [60, 64],
        staccatoMIDI: [67, 70]
    )
    .frame(width: 600, height: 120)
    .padding()
}

#Preview("Hand position C major") {
    KeyboardView(
        pressedMIDI: [60],
        handPosition: HandPosition(startMIDI: 60, fingerCount: 5)
    )
    .frame(width: 600, height: 120)
    .padding()
}

#Preview("Hidden (quiz mode)") {
    KeyboardView(pressedMIDI: [60, 64, 67], isHidden: true)
        .frame(width: 600, height: 120)
        .padding()
}

#Preview("Full piano (scrollable)") {
    KeyboardView(
        pressedMIDI: [21, 60, 108],
        lowMIDI: 21,
        highMIDI: 108
    )
    .frame(width: 600, height: 120)
    .padding()
}

#Preview("Custom color (red, dark mode)") {
    KeyboardView(
        pressedMIDI: [60, 64, 67],
        pressedColor: .red
    )
    .frame(width: 600, height: 120)
    .padding()
    .preferredColorScheme(.dark)
}

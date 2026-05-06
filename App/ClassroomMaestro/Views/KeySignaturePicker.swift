import SwiftUI
import ClassroomTheory

public struct KeySignaturePicker: View {
    @Binding public var selection: KeySignature
    public let onPick: (() -> Void)?

    public init(selection: Binding<KeySignature>, onPick: (() -> Void)? = nil) {
        self._selection = selection
        self.onPick = onPick
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 16) {
            column(title: "Major", keys: KeySignature.all15Major)
            column(title: "Minor", keys: KeySignature.all15Minor)
        }
        .padding(16)
    }

    private func column(title: String, keys: [KeySignature]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                Button {
                    selection = key
                    onPick?()
                } label: {
                    HStack {
                        Text(displayName(for: key))
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(accidentalCountLabel(for: key))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(width: 140, alignment: .leading)
                    .background(
                        selection == key
                            ? Color.accentColor.opacity(0.2)
                            : Color.clear
                    )
                    .cornerRadius(4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(displayName(for: key))
            }
        }
    }

    private func displayName(for key: KeySignature) -> String {
        let tonic = "\(key.tonic.letterName)\(key.accidental.displaySymbol)"
        let mode = key.mode == .major ? "major" : "minor"
        return "\(tonic) \(mode)"
    }

    private func accidentalCountLabel(for key: KeySignature) -> String {
        let count = key.fifthsCount
        if count == 0 { return "—" }
        let symbol = count > 0 ? "♯" : "♭"
        return "\(abs(count))\(symbol)"
    }
}

#Preview {
    @Previewable @State var key: KeySignature = .cMajor
    return KeySignaturePicker(selection: $key)
        .frame(width: 360)
}

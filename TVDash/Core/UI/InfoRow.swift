import SwiftUI

/// One label–value line in a dashboard card.
struct InfoRow: View {
    private let label: Text
    private let value: String
    private let valueColor: Color

    init(_ label: LocalizedStringKey, value: String, valueColor: Color = .primary) {
        self.label = Text(label)
        self.value = value
        self.valueColor = valueColor
    }

    /// For labels that come from data (interface names and similar) and must not be translated.
    init(verbatim label: String, value: String) {
        self.label = Text(verbatim: label)
        self.value = value
        self.valueColor = .primary
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 24) {
            label
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(verbatim: value)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .font(.callout)
    }
}

/// A big headline number with a caption, at the top of a card.
struct BigValue: View {
    let value: String
    let caption: LocalizedStringKey?
    var tint: Color = .primary
    var size: CGFloat = 72

    init(_ value: String, caption: LocalizedStringKey? = nil, tint: Color = .primary, size: CGFloat = 72) {
        self.value = value
        self.caption = caption
        self.tint = tint
        self.size = size
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: value)
                .font(.system(size: size, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
            if let caption {
                Text(caption)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        BigValue("62 %", caption: "used", tint: .purple)
        InfoRow("Total", value: "4 GB")
        InfoRow(verbatim: "en0", value: "192.168.1.20")
    }
    .frame(width: 600)
    .padding(80)
}

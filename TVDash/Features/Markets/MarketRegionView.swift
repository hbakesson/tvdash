import SwiftUI

/// One region per screen: a table of indexes with 1, 3, 5 and 10-year returns.
///
/// Selecting a row pushes a `MarketIndex` onto the enclosing `NavigationStack`.
struct MarketRegionView: View {
    let region: MarketRegion
    let model: MarketsModel

    private let valueColumnWidth: CGFloat = 225

    var body: some View {
        if model.allFailed {
            LoadFailedView { Task { await model.retry() } }
        } else {
            VStack(alignment: .leading, spacing: 40) {
                header
                table
                Spacer(minLength: 0)
                footer
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(region.title)
                .font(.system(size: 76, weight: .bold))
            Text("^[\(region.indexes.count) index](inflect: true)")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private var table: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                Text("Index")
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(ReturnPeriod.allCases, id: \.self) { period in
                    Text(period.title)
                        .frame(width: valueColumnWidth, alignment: .trailing)
                }
            }
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, RowButtonStyle.horizontalPadding)

            Divider()

            // Each row opens the index's chart, where the timespan can be chosen.
            ForEach(region.indexes) { index in
                NavigationLink(value: index) {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(verbatim: index.name)
                                .font(.title3.bold())
                            Text(subtitle(for: index))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        ReturnCells(state: model.state(for: index), columnWidth: valueColumnWidth)
                    }
                }
                .buttonStyle(RowButtonStyle())
                .accessibilityElement(children: .combine)
            }

            if let average = model.average(for: region) {
                Divider()
                HStack(spacing: 20) {
                    Text("Average")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ReturnCells(state: .loaded(average), columnWidth: valueColumnWidth)
                }
                .padding(.horizontal, RowButtonStyle.horizontalPadding)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 24) {
            Text("Price return, excluding dividends")
            if let updatedAt = model.updatedAt {
                Text(verbatim: "·")
                Text("Updated \(updatedAt, format: .dateTime.day().month().hour().minute())")
            }
        }
        .font(.caption)
        .foregroundStyle(.tertiary)
    }

    private func subtitle(for index: MarketIndex) -> String {
        guard let proxy = index.proxy else { return index.currency }
        return "\(index.currency) · " + String(localized: "via \(proxy)")
    }
}

/// A table row that lifts and highlights when focused.
private struct RowButtonStyle: ButtonStyle {
    static let horizontalPadding: CGFloat = 24

    func makeBody(configuration: Configuration) -> some View {
        Row(configuration: configuration)
    }

    private struct Row: View {
        let configuration: Configuration
        @Environment(\.isFocused) private var isFocused

        var body: some View {
            configuration.label
                .padding(.horizontal, RowButtonStyle.horizontalPadding)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.primary.opacity(isFocused ? 0.14 : 0))
                )
                .scaleEffect(configuration.isPressed ? 0.98 : isFocused ? 1.02 : 1)
                .shadow(color: .black.opacity(isFocused ? 0.3 : 0), radius: 16, y: 8)
                .animation(.easeOut(duration: 0.15), value: isFocused)
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
        }
    }
}

/// The five value cells of one table row.
private struct ReturnCells: View {
    let state: MarketsModel.RowState
    let columnWidth: CGFloat

    var body: some View {
        ForEach(ReturnPeriod.allCases, id: \.self) { period in
            cell(for: period)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: columnWidth, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func cell(for period: ReturnPeriod) -> some View {
        switch state {
        case .loading:
            ProgressView()
        case .failed:
            Text(verbatim: "–").foregroundStyle(.secondary)
        case .loaded(let returns):
            if let value = returns[period] {
                Text(verbatim: value.formatted(.percent.sign(strategy: .always()).precision(.fractionLength(1))))
                    .foregroundStyle(value >= 0 ? .green : .red)
            } else {
                Text(verbatim: "–").foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Previews

private struct PreviewProvider: IndexHistoryProviding {
    func history(symbol: String, range: HistoryRange, interval: HistoryInterval) async throws -> IndexHistory {
        if symbol == "^RUT" { throw IndexHistoryError.noData("Preview") }
        let growth = Double(symbol.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 40) / 100 + 0.02
        let end = Date.now
        let points = (0...520).map { week in
            let date = Calendar.current.date(byAdding: .weekOfYear, value: week - 520, to: end) ?? end
            return IndexHistory.Point(date: date, close: 100 * pow(1 + growth, Double(week) / 52))
        }
        return IndexHistory(
            symbol: symbol, name: symbol, currency: "USD", baseline: 100,
            latest: points.last?.close ?? 100, updatedAt: end, points: points
        )
    }
}

#Preview("North America") {
    let model = MarketsModel(provider: PreviewProvider())
    NavigationStack {
        MarketRegionView(region: MarketRegion.all[1], model: model)
    }
    .task { await model.refresh() }
}

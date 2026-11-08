import Charts
import SwiftUI

/// Chart screen for one index: latest value, change and a chart over the selected timespan.
///
/// Used as the start screen (OMXS30) and when opening an index from a region screen. The selected
/// timespan is shared by all indexes and remembered between launches.
struct IndexOverviewView: View {
    let model: IndexOverviewModel

    /// Can be overridden at launch with `-chartTimespan <case name>`.
    @AppStorage("chartTimespan") private var timespan: ChartTimespan = .yearToDate

    var body: some View {
        let state = model.state(for: timespan)

        VStack(alignment: .leading, spacing: 40) {
            // First focusable element, so focus lands here when the screen opens.
            Picker("Timespan", selection: $timespan) {
                ForEach(ChartTimespan.allCases) { timespan in
                    Text(timespan.title).tag(timespan)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 1200)

            IndexHeader(displayName: model.displayName, timespan: timespan, state: state)

            // Only this area changes while a timespan loads; the picker stays put, so focus is never lost.
            Group {
                switch state {
                case .loading:
                    ProgressView("Loading…")
                case .loaded(let history):
                    IndexChart(history: history, timespan: timespan)
                case .failed:
                    LoadFailedView { Task { await model.retry(timespan) } }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 80)
        .padding(.vertical, 60)
        .task(id: timespan) { await model.refreshPeriodically(timespan) }
    }
}

// MARK: - Header

private struct IndexHeader: View {
    let displayName: String
    let timespan: ChartTimespan
    let state: IndexOverviewModel.State

    /// Shown redacted while loading, so the layout does not jump when data arrives.
    private static let placeholder = IndexHistory(
        symbol: "", name: "OMX Stockholm 30 Index", currency: "", baseline: 2900, latest: 3000,
        updatedAt: .now, points: []
    )

    private var history: IndexHistory {
        if case .loaded(let history) = state { return history }
        return Self.placeholder
    }

    private var trendColor: Color { history.isUp ? .green : .red }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: displayName)
                    .font(.system(size: 76, weight: .bold))
                Text(verbatim: history.name)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .redacted(reason: isLoading ? .placeholder : [])
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(verbatim: history.latest.formatted(.number.precision(.fractionLength(2))))
                    .font(.system(size: 76, weight: .bold))
                    .monospacedDigit()
                Text(verbatim: changeText)
                    .font(.title3.bold())
                    .monospacedDigit()
                    .foregroundStyle(trendColor)
                periodText
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Updated \(history.updatedAt, format: .dateTime.day().month().hour().minute())")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .redacted(reason: isLoading ? .placeholder : [])
            .opacity(state == .failed ? 0 : 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var isLoading: Bool { state == .loading }

    @ViewBuilder
    private var periodText: some View {
        if timespan == .all, let first = history.points.first {
            Text("Since \(first.date, format: .dateTime.year())")
        } else {
            Text(timespan.summary)
        }
    }

    private var changeText: String {
        let points = history.change.formatted(.number.sign(strategy: .always()).precision(.fractionLength(2)))
        let percent = history.changeFraction.formatted(
            .percent.sign(strategy: .always()).precision(.fractionLength(2))
        )
        return "\(points) (\(percent))"
    }

}

// MARK: - Chart

private struct IndexChart: View {
    let history: IndexHistory
    let timespan: ChartTimespan

    private var trendColor: Color { history.isUp ? .green : .red }

    var body: some View { chart }

    private var yDomain: ClosedRange<Double> {
        let range = history.valueRange
        let padding = max((range.upperBound - range.lowerBound) * 0.08, 1)
        return (range.lowerBound - padding)...(range.upperBound + padding)
    }

    private var chart: some View {
        Chart {
            ForEach(history.points) { point in
                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    yStart: .value("Close", yDomain.lowerBound),
                    yEnd: .value("Close", point.close)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [trendColor.opacity(0.35), trendColor.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Close", point.close)
                )
                .foregroundStyle(trendColor)
                .lineStyle(StrokeStyle(lineWidth: 4, lineJoin: .round))
            }

            RuleMark(y: .value("Start of period", history.baseline))
                .foregroundStyle(Color.secondary)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [10, 8]))
        }
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: timespan.axisValues) {
                AxisGridLine()
                AxisValueLabel(format: timespan.axisLabelFormat)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) {
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
}

extension ChartTimespan {
    /// Where to put date labels: about 4–12 per chart.
    fileprivate var axisValues: AxisMarkValues {
        switch self {
        case .oneMonth: .stride(by: .weekOfYear)
        case .threeMonths, .sixMonths, .yearToDate, .oneYear: .stride(by: .month)
        case .fiveYears, .tenYears: .stride(by: .year)
        case .all: .automatic(desiredCount: 8)
        }
    }

    fileprivate var axisLabelFormat: Date.FormatStyle {
        switch self {
        case .oneMonth: .dateTime.day().month(.abbreviated)
        case .threeMonths, .sixMonths, .yearToDate, .oneYear: .dateTime.month(.abbreviated)
        case .fiveYears, .tenYears, .all: .dateTime.year()
        }
    }
}

// MARK: - Previews

private struct PreviewProvider: IndexHistoryProviding {
    var fails = false

    func history(symbol: String, range: HistoryRange, interval: HistoryInterval) async throws -> IndexHistory {
        if fails { throw IndexHistoryError.noData("Preview") }
        return .preview
    }
}

extension IndexHistory {
    /// Deterministic sample data for previews.
    static let preview: IndexHistory = {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 2)) ?? .now
        let points = (0..<215).map { day in
            IndexHistory.Point(
                date: calendar.date(byAdding: .day, value: day * 7 / 5, to: start) ?? start,
                close: 2880 + Double(day) * 1.8 + sin(Double(day) / 6) * 40
            )
        }
        return IndexHistory(
            symbol: "^OMX",
            name: "OMX Stockholm 30 Index",
            currency: "SEK",
            baseline: 2882.97,
            latest: points.last?.close ?? 2880,
            updatedAt: points.last?.date ?? .now,
            points: points
        )
    }()
}

#Preview("Loaded") {
    IndexOverviewView(model: IndexOverviewModel(provider: PreviewProvider()))
}

#Preview("Failed") {
    IndexOverviewView(model: IndexOverviewModel(provider: PreviewProvider(fails: true)))
}

import Charts
import SwiftUI

/// Start screen: year-to-date development of an index, sized for viewing from the couch.
struct IndexOverviewView: View {
    let model: IndexOverviewModel

    var body: some View {
        Group {
            switch model.state {
            case .loading:
                ProgressView("Loading…")
            case .loaded(let history):
                IndexPerformanceView(displayName: model.displayName, history: history)
            case .failed:
                LoadFailedView { Task { await model.retry() } }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await model.refreshPeriodically() }
    }
}

// MARK: - Loaded

private struct IndexPerformanceView: View {
    let displayName: String
    let history: IndexHistory

    private var trendColor: Color { history.isUp ? .green : .red }

    var body: some View {
        VStack(alignment: .leading, spacing: 48) {
            header
            chart
        }
        .padding(.horizontal, 80)
        .padding(.vertical, 60)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: displayName)
                    .font(.system(size: 76, weight: .bold))
                Text(verbatim: history.name)
                    .font(.headline)
                    .foregroundStyle(.secondary)
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
                Text("Since start of year")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Updated \(history.updatedAt, format: .dateTime.day().month().hour().minute())")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var changeText: String {
        let points = history.change.formatted(.number.sign(strategy: .always()).precision(.fractionLength(2)))
        let percent = history.changeFraction.formatted(
            .percent.sign(strategy: .always()).precision(.fractionLength(2))
        )
        return "\(points) (\(percent))"
    }

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

            RuleMark(y: .value("Start of year", history.baseline))
                .foregroundStyle(Color.secondary)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [10, 8]))
        }
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) {
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated))
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

// MARK: - Previews

private struct PreviewProvider: IndexHistoryProviding {
    var fails = false

    func history(symbol: String, range: HistoryRange) async throws -> IndexHistory {
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

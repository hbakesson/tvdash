import Charts
import SwiftUI

/// A small area chart of recent values, newest on the right.
struct Sparkline: View {
    let samples: [RollingHistory<Double>.Sample]
    let color: Color
    /// Fixed vertical range, e.g. `0...1` for fractions. `nil` scales to the data, starting at zero.
    var domain: ClosedRange<Double>?
    /// Formats the y-axis labels. No axis when `nil`.
    var axisFormat: ((Double) -> String)?

    private var yDomain: ClosedRange<Double> {
        if let domain { return domain }
        let peak = samples.map(\.value).max() ?? 0
        return 0...max(peak * 1.15, 1)
    }

    var body: some View {
        Chart(samples) { sample in
            AreaMark(x: .value("Time", sample.date), y: .value("Value", sample.value))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.45), color.opacity(0.02)], startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.monotone)
            LineMark(x: .value("Time", sample.date), y: .value("Value", sample.value))
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.monotone)
        }
        .chartYScale(domain: yDomain)
        .chartXAxis(.hidden)
        .chartYAxis {
            if let axisFormat {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(verbatim: axisFormat(number))
                        }
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    var history = RollingHistory<Double>(capacity: 60)
    for second in 0..<60 {
        history.append(0.4 + sin(Double(second) / 5) * 0.2, at: .now.addingTimeInterval(Double(second) * 2))
    }
    return Sparkline(samples: history.samples, color: .blue, domain: 0...1, axisFormat: { $0.percentText })
        .frame(height: 200)
        .padding(80)
}

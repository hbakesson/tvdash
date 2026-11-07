import SwiftUI

/// Full-screen error state with a focusable retry button.
struct LoadFailedView: View {
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Couldn't load index data", systemImage: "chart.line.downtrend.xyaxis")
        } description: {
            Text("Check your internet connection and try again.")
        } actions: {
            Button("Try Again", action: retry)
        }
    }
}

#Preview {
    LoadFailedView {}
}

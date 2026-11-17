import SwiftUI

/// Disk space on the device and how much of it this app takes.
struct StorageView: View {
    let model: DashboardModel

    var body: some View {
        DashboardScreen(section: .storage) {
            if let storage = model.storage {
                DashboardCard(title: "Disk", systemImage: "internaldrive", tint: .orange) {
                    BigValue(
                        storage.volumeAvailable.fileText, caption: "free of \(storage.volumeTotal.fileText)",
                        tint: .orange
                    )
                    UsageBar(fraction: storage.usedFraction, color: .orange)
                    InfoRow("Used", value: "\(storage.volumeUsed.fileText) (\(storage.usedFraction.percentText))")
                }

                CardColumns {
                    DashboardCard(title: "This app", systemImage: "app.badge", tint: .orange) {
                        InfoRow("App", value: storage.appBundle.fileText)
                        InfoRow("Documents", value: storage.documents.fileText)
                        InfoRow("Application Support", value: storage.applicationSupport.fileText)
                        InfoRow("Caches", value: storage.caches.fileText)
                        InfoRow("Temporary files", value: storage.temporary.fileText)
                        Divider()
                        InfoRow("Total", value: storage.appTotal.fileText)
                    }
                } trailing: {
                    DashboardCard(title: "Other apps", systemImage: "square.stack.3d.up", tint: .orange) {
                        PlatformLimitNote(
                            text: """
                                tvOS does not let apps see which other apps are installed or how much space they \
                                use. You can find that in Settings → General → Manage Storage.
                                """
                        )
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    let model = DashboardModel(provider: PreviewMetrics(), pathMonitor: PreviewPathMonitor())
    StorageView(model: model)
        .task { await model.monitor() }
}

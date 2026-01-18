import SwiftUI
import OSLog

@main
struct QuotaWatchApp: App {
    @State private var engine: QuotaEngine?
    @State private var initializationError: Error?
    @State private var isInitializing = false

    var body: some Scene {
        MenuBarExtra("QuotaWatch", systemImage: "chart.bar") {
            MenuBarView(
                engine: engine,
                initializationError: initializationError,
                isInitializing: isInitializing,
                retryInitialization: setupEngine
            )
            .onAppear {
                if engine == nil && !isInitializing {
                    Task { await setupEngine() }
                }
            }
        }
    }

    // MARK: - Engineのセットアップ

    private func setupEngine() async {
        guard engine == nil else { return }

        isInitializing = true
        initializationError = nil

        do {
            let provider = ZaiProvider()
            let persistence = try PersistenceManager(customDirectoryURL: FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first!
                .appending(path: "com.quotawatch"))
            let keychain = KeychainStore()

            let newEngine = await QuotaEngine(
                provider: provider,
                persistence: persistence,
                keychain: keychain
            )

            self.engine = newEngine
            await newEngine.startRunLoop()

        } catch {
            let logger = Logger(subsystem: "com.quotawatch.app", category: "QuotaWatchApp")
            logger.error("QuotaWatch初期化エラー: \(error.localizedDescription)")
            self.initializationError = error
        }

        isInitializing = false
    }
}

struct MenuBarView: View {
    let engine: QuotaEngine?
    let initializationError: Error?
    let isInitializing: Bool
    let retryInitialization: () async -> Void

    var body: some View {
        VStack {
            if let error = initializationError {
                errorView(error)
            } else if isInitializing {
                ProgressView("初期化中...")
            } else if let engine = engine {
                contentView(engine: engine)
            }
        }
    }

    @ViewBuilder
    private func errorView(_ error: Error) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("初期化エラー", systemImage: "exclamationmark.triangle")
                .font(.headline)
                .foregroundColor(.red)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)

            Button("再試行") {
                Task { await retryInitialization() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    @ViewBuilder
    private func contentView(engine: QuotaEngine) -> some View {
        Text("Hello")
            .padding()
    }
}

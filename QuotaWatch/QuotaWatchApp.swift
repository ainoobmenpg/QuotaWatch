import SwiftUI
import OSLog

@main
struct QuotaWatchApp: App {
    @State private var viewModel: ContentViewModel?
    @State private var initializationError: Error?
    @State private var isInitializing = false

    var body: some Scene {
        MenuBarExtra("QuotaWatch", systemImage: "chart.bar") {
            MenuBarView(
                viewModel: viewModel,
                initializationError: initializationError,
                isInitializing: isInitializing,
                retryInitialization: setupEngine
            )
            .onAppear {
                if viewModel == nil && !isInitializing {
                    Task { await setupEngine() }
                }
            }
        }
    }

    // MARK: - Engineのセットアップ

    private func setupEngine() async {
        guard viewModel == nil else { return }

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

            await newEngine.startRunLoop()

            // ContentViewModelを初期化
            let newViewModel = ContentViewModel(engine: newEngine)
            await newViewModel.loadInitialData()
            self.viewModel = newViewModel

        } catch {
            let logger = Logger(subsystem: "com.quotawatch.app", category: "QuotaWatchApp")
            logger.error("QuotaWatch初期化エラー: \(error.localizedDescription)")
            self.initializationError = error
        }

        isInitializing = false
    }
}

struct MenuBarView: View {
    let viewModel: ContentViewModel?
    let initializationError: Error?
    let isInitializing: Bool
    let retryInitialization: () async -> Void

    var body: some View {
        VStack {
            if let error = initializationError {
                errorView(error)
            } else if isInitializing {
                ProgressView("初期化中...")
            } else if let viewModel = viewModel {
                contentView(viewModel: viewModel)
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
    private func contentView(viewModel: ContentViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // メニューバータイトル
            Text(viewModel.menuBarTitle)
                .font(.headline)

            Divider()

            // スナップショット情報
            if let snapshot = viewModel.snapshot {
                snapshotView(snapshot)
            }

            Divider()

            // エンジン状態
            if let engineState = viewModel.engineState {
                engineStateView(engineState)
            }

            Divider()

            // アクション
            actionButtons(viewModel)

            // エラーメッセージ
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }

    @ViewBuilder
    private func snapshotView(_ snapshot: UsageSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // プライマリクォータ
            HStack {
                Text(snapshot.primaryTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let pct = snapshot.primaryPct {
                    Text("\(pct)%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 残り時間
                if let resetEpoch = snapshot.resetEpoch {
                    Text(TimeFormatter.formatTimeRemaining(resetEpoch: resetEpoch))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // プログレスバー
            if let pct = snapshot.primaryPct {
                ProgressView(value: Double(pct), total: 100)
                    .progressViewStyle(.linear)
            }

            // セカンダリクォータ
            if !snapshot.secondary.isEmpty {
                ForEach(snapshot.secondary) { limit in
                    secondaryLimitView(limit)
                }
            }
        }
    }

    @ViewBuilder
    private func secondaryLimitView(_ limit: UsageLimit) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(limit.label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let pct = limit.pct {
                    Text("\(pct)%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            if let pct = limit.pct {
                ProgressView(value: Double(pct), total: 100)
                    .progressViewStyle(.linear)
                    .scaleEffect(y: 0.5)
            }
        }
    }

    @ViewBuilder
    private func engineStateView(_ engineState: EngineState) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ステータス")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            HStack {
                if engineState.isBackingOff {
                    Label("バックオフ中", systemImage: "pause.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Label("通常", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                }

                Spacer()

                Text("次回: \(engineState.secondsUntilNextFetch)秒")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func actionButtons(_ viewModel: ContentViewModel) -> some View {
        HStack(spacing: 12) {
            Button(action: {
                Task { await viewModel.forceFetch() }
            }) {
                Label("強制フェッチ", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isFetching)

            Button(action: {
                Task { await viewModel.refresh() }
            }) {
                Label("更新", systemImage: "arrow.down.circle")
            }
            .buttonStyle(.bordered)
        }
    }
}

import SwiftUI
import OSLog

@main
struct QuotaWatchApp: App {
    @State private var viewModel: ContentViewModel?
    @State private var initializationError: Error?
    @State private var isInitializing = false
    private static let defaultMenuBarTitle = "QuotaWatch..."
    @State private var menuBarTitle: String = defaultMenuBarTitle
    @State private var showingAPIKeySheet = false
    @State private var apiKeySaveError: String?

    var body: some Scene {
        MenuBarExtra(menuBarTitle, systemImage: "chart.bar") {
            MenuBarView(
                viewModel: viewModel,
                initializationError: initializationError,
                isInitializing: isInitializing,
                retryInitialization: setupEngine,
                showingAPIKeySheet: $showingAPIKeySheet,
                apiKeySaveError: apiKeySaveError,
                saveAPIKey: saveAPIKey
            )
            .onAppear {
                if viewModel == nil && !isInitializing {
                    Task { await setupEngine() }
                }
            }
        }
        .onChange(of: viewModel) { _, newViewModel in
            if let title = newViewModel?.menuBarTitle {
                menuBarTitle = title
            }
        }
        .onChange(of: viewModel?.menuBarTitle) { _, newTitle in
            if let newTitle = newTitle {
                menuBarTitle = newTitle
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
            let newViewModel = ContentViewModel(engine: newEngine, provider: provider)
            await newViewModel.loadInitialData()
            self.viewModel = newViewModel

        } catch {
            let logger = Logger(subsystem: "com.quotawatch.app", category: "QuotaWatchApp")
            logger.error("QuotaWatch初期化エラー: \(error.localizedDescription)")
            self.initializationError = error
        }

        isInitializing = false
    }

    // MARK: - APIキー管理

    /// APIキーを保存して再初期化
    private func saveAPIKey(_ apiKey: String) async {
        // 競合防止: 既に初期化中の場合は早期リターン
        guard !isInitializing else {
            let logger = Logger(subsystem: "com.quotawatch.app", category: "QuotaWatchApp")
            logger.warning("初期化中のためAPIキー保存をスキップ")
            return
        }

        let logger = Logger(subsystem: "com.quotawatch.app", category: "QuotaWatchApp")
        do {
            let keychain = KeychainStore()
            try await keychain.write(apiKey: apiKey)
            logger.log("APIキー保存成功")

            // エラー状態をクリア
            apiKeySaveError = nil

            // 既存のviewModelをクリアして再初期化
            viewModel = nil
            initializationError = nil
            await setupEngine()
        } catch {
            logger.error("APIキー保存エラー: \(error.localizedDescription)")
            // エラー状態を設定してシートを再表示
            apiKeySaveError = error.localizedDescription
            showingAPIKeySheet = true
        }
    }
}

struct MenuBarView: View {
    let viewModel: ContentViewModel?
    let initializationError: Error?
    let isInitializing: Bool
    let retryInitialization: () async -> Void
    @Binding var showingAPIKeySheet: Bool
    let apiKeySaveError: String?
    let saveAPIKey: (String) async -> Void

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
        .sheet(isPresented: $showingAPIKeySheet) {
            APIKeySettingsSheet(
                onSave: saveAPIKey,
                initialError: apiKeySaveError
            )
        }
    }

    @ViewBuilder
    private func errorView(_ error: Error) -> some View {
        // APIキー未設定時は専用UIを表示
        if let engineError = error as? QuotaEngineError,
           case .apiKeyNotSet = engineError {
            apiKeyNotSetView()
        } else {
            // 既存のエラー表示
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
    }

    @ViewBuilder
    private func apiKeyNotSetView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("APIキー未設定", systemImage: "key.badge")
                .font(.headline)
                .foregroundColor(.orange)

            Text("Z.aiのAPIキーを設定してください")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("APIキーを設定") {
                showingAPIKeySheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    @ViewBuilder
    private func contentView(viewModel: ContentViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // ヘッダー
                if let engineState = viewModel.engineState {
                    HeaderView(
                        isBackingOff: engineState.isBackingOff,
                        hasError: viewModel.errorMessage != nil,
                        providerDisplayName: viewModel.providerDisplayName
                    )
                }

                Divider()

                // プライマリクォータ
                if let snapshot = viewModel.snapshot {
                    PrimaryQuotaView(snapshot: snapshot)
                }

                // セカンダリクォータ
                if let snapshot = viewModel.snapshot {
                    SecondaryQuotaView(limits: snapshot.secondary)
                }

                Divider()

                // ステータス
                if let engineState = viewModel.engineState {
                    StatusView(
                        lastFetchEpoch: engineState.lastFetchEpoch,
                        nextFetchEpoch: engineState.nextFetchEpoch,
                        backoffFactor: engineState.backoffFactor,
                        errorMessage: viewModel.errorMessage
                    )
                }

                Divider()

                // アクション
                ActionsView(
                    onForceFetch: {
                        await viewModel.forceFetch()
                    },
                    onTestNotification: {
                        await viewModel.sendTestNotification()
                    },
                    onOpenDashboard: {
                        await viewModel.openDashboard()
                    },
                    isFetching: viewModel.isFetching,
                    dashboardURL: viewModel.dashboardURL
                )

                Divider()

                // 設定
                SettingsView(
                    settings: viewModel.appSettings,
                    onUpdateIntervalChanged: { interval in
                        await viewModel.setUpdateInterval(interval)
                    },
                    onNotificationsChanged: { enabled in
                        await viewModel.setNotificationsEnabled(enabled)
                    },
                    onLoginItemChanged: { enabled in
                        await viewModel.setLoginItemEnabled(enabled)
                    }
                )

                // エラーメッセージ
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .frame(minWidth: 320, idealWidth: 360, maxWidth: 420)
    }
}

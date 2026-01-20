import AppKit
import SwiftUI

/// アプリ起動時に即座に初期化を行うための AppDelegate
///
/// MenuBarExtra の .task や .onAppear はポップアップが表示されるまで実行されないため、
/// NSApplicationDelegateAdaptor を使用して applicationDidFinishLaunching で初期化を行う。
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    // MARK: - Published Properties

    /// ViewModel（Engine 初期化完了後に設定）
    @Published var viewModel: ContentViewModel?

    /// MenuBarController（ViewModel 初期化後に設定）
    @Published var menuBarController: MenuBarController?

    /// 初期化エラー
    @Published var initializationError: Error?

    /// APIキー設定シート表示フラグ
    @Published var showingAPIKeySheet = false

    /// APIキー未設定アラート表示フラグ
    @Published var showingAPIKeyAlert = false

    /// APIキー保存エラー
    var apiKeySaveError: String?

    // MARK: - Private Properties

    private let loggerManager: LoggerManager = .shared

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task {
            // アプリ起動時に即座にEngineを初期化
            await setupEngine()
        }
    }

    // MARK: - Engine Setup

    /// Engineをセットアップ
    @MainActor
    func setupEngine() async {
        // ログ出力（早期リターンより前）
        await loggerManager.log("setupEngine() 開始", category: "APP")

        // 通知権限のチェックとリクエスト
        let notificationStatus = await NotificationManager.shared.getAuthorizationStatus()
        switch notificationStatus {
        case .notDetermined:
            await loggerManager.log("通知権限が未設定です。リクエストを表示します。", category: "APP")
            do {
                let granted = try await NotificationManager.shared.requestAuthorization()
                if granted {
                    await loggerManager.log("通知権限が付与されました", category: "APP")
                } else {
                    await loggerManager.log("通知権限が拒否されました", category: "APP")
                }
            } catch {
                await loggerManager.log("通知権限のリクエストに失敗: \(error.localizedDescription)", category: "APP")
            }
        case .authorized:
            await loggerManager.log("通知権限が付与されています", category: "APP")
        case .denied:
            await loggerManager.log("通知権限が拒否されています", category: "APP")
        case .provisional:
            await loggerManager.log("通知権限は暫定付与されています", category: "APP")
        case .ephemeral:
            await loggerManager.log("通知権限は一時的に付与されています", category: "APP")
        @unknown default:
            await loggerManager.log("未知の通知権限ステータス: \(notificationStatus.rawValue)", category: "APP")
        }

        guard viewModel == nil else {
            await loggerManager.log("setupEngine() スキップ: viewModel が既存", category: "APP")
            return
        }

        initializationError = nil

        do {
            let provider = ZaiProvider()
            let persistence = PersistenceManager(customDirectoryURL: FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first!
                .appending(path: "com.quotawatch"))
            let keychain = KeychainStore()

            let newEngine = try await QuotaEngine(
                provider: provider,
                persistence: persistence,
                keychain: keychain
            )

            // ContentViewModelを初期化（軽量な初期化のみ）
            let newViewModel = ContentViewModel(engine: newEngine, provider: provider)

            // 先にUIを表示
            self.viewModel = newViewModel
            self.menuBarController = MenuBarController(
                viewModel: newViewModel,
                appDelegate: self
            )

            // 成功時はエラーをクリア
            self.initializationError = nil
            await loggerManager.log("setupEngine() UI初期化完了", category: "APP")

            // バックグラウンドで残りの処理を実行
            Task {
                await newEngine.startRunLoop()
                await newViewModel.loadInitialData()
                await loggerManager.log("setupEngine() データロード完了", category: "APP")
            }

        } catch {
            await loggerManager.log("QuotaWatch初期化エラー: \(error.localizedDescription)", category: "APP")
            self.initializationError = error

            // APIキー未設定の場合は、NSAlertで通知してシートを表示
            if let engineError = error as? QuotaEngineError,
               case .apiKeyNotSet = engineError {
                await loggerManager.log("APIキー未設定エラーを検出、アラートを表示します", category: "APP")
                showAPIKeyAlert()
            }
        }
    }

    // MARK: - NSAlert

    /// APIキー未設定のアラートを表示
    @MainActor
    private func showAPIKeyAlert() {
        let alert = NSAlert()
        alert.messageText = "APIキー未設定"
        alert.informativeText = "Z.aiのAPIキーを設定してください。\nメニューバーのQuotaWatchアイコンをクリックして設定してください。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - API Key Management

    /// APIキーを保存して再初期化
    @MainActor
    func saveAPIKey(_ apiKey: String) async {
        do {
            let keychain = KeychainStore()
            try await keychain.write(apiKey: apiKey)
            await loggerManager.log("APIキー保存成功", category: "APP")

            // エラー状態をクリア
            apiKeySaveError = nil

            // 既存のviewModelをクリアして再初期化
            viewModel = nil
            initializationError = nil
            await setupEngine()
        } catch {
            await loggerManager.log("APIキー保存エラー: \(error.localizedDescription)", category: "APP")
            // エラー状態を設定してシートを再表示
            apiKeySaveError = error.localizedDescription
            showingAPIKeySheet = true
        }
    }
}

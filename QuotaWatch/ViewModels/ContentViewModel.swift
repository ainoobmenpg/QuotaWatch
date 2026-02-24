//
//  ContentViewModel.swift
//  QuotaWatch
//
//  SwiftUIへ状態を供給する@MainActorのViewModel
//

import Foundation
import SwiftUI
import UserNotifications
import OSLog

// MARK: - EngineState

/// UI向け簡易状態
///
/// AppStateからUIに必要な情報を抽出した構造体
public struct EngineState: Equatable, Sendable {
    /// 次回フェッチ時刻（epoch秒）
    let nextFetchEpoch: Int

    /// バックオフ係数
    let backoffFactor: Int

    /// 最終フェッチ時刻（epoch秒）
    let lastFetchEpoch: Int

    /// 連続失敗カウンター
    let consecutiveFailureCount: Int

    /// 次回フェッチまでの秒数
    var secondsUntilNextFetch: Int {
        let now = Date().epochSeconds
        return max(0, nextFetchEpoch - now)
    }

    /// バックオフ中かどうか
    var isBackingOff: Bool {
        return backoffFactor > 1
    }

    /// AppStateから変換
    init(from appState: AppState) {
        self.nextFetchEpoch = appState.fetch.nextFetchEpoch
        self.backoffFactor = appState.fetch.backoffFactor
        self.lastFetchEpoch = appState.fetch.lastFetchEpoch
        self.consecutiveFailureCount = appState.fetch.consecutiveFailureCount
    }

    /// FetchStateから変換
    init(from fetchState: FetchState) {
        self.nextFetchEpoch = fetchState.nextFetchEpoch
        self.backoffFactor = fetchState.backoffFactor
        self.lastFetchEpoch = fetchState.lastFetchEpoch
        self.consecutiveFailureCount = fetchState.consecutiveFailureCount
    }

    /// 値を指定して初期化（テスト用）
    init(
        nextFetchEpoch: Int,
        backoffFactor: Int,
        lastFetchEpoch: Int,
        consecutiveFailureCount: Int
    ) {
        self.nextFetchEpoch = nextFetchEpoch
        self.backoffFactor = backoffFactor
        self.lastFetchEpoch = lastFetchEpoch
        self.consecutiveFailureCount = consecutiveFailureCount
    }
}

// MARK: - ContentViewModel

/// SwiftUIへ状態を供給する@MainActorのViewModel
///
/// QuotaEngine（actor）とUI層のブリッジとなります。
@MainActor
public final class ContentViewModel: ObservableObject {
    // MARK: - 依存関係

    /// QuotaEngine（actor）
    private let engine: any QuotaEngineProtocol

    /// Provider（Z.ai等）
    private var currentProvider: Provider

    /// ロガーマネージャー
    private let loggerManager: LoggerManager = .shared

    /// ロガー
    private let logger = Logger(subsystem: "com.quotawatch.viewmodel", category: "ContentViewModel")

    // MARK: - UI状態（@Published）

    /// 現在のスナップショット
    @Published private(set) var snapshot: UsageSnapshot?

    /// エンジン状態
    @Published private(set) var engineState: EngineState?

    /// メニューバータイトル
    @Published private(set) var menuBarTitle: String = "..."

    /// フェッチ中かどうか
    @Published private(set) var isFetching: Bool = false

    /// エラーメッセージ
    @Published private(set) var errorMessage: String?

    /// 認証エラー状態（APIキー無効等）
    @Published private(set) var authorizationError: Bool = false

    /// APIキー未設定エラー（プロバイダー切り替え時に設定）
    @Published private(set) var apiKeyRequired: ProviderId?

    /// 初期データロード中かどうか
    @Published private(set) var isLoadingInitialData: Bool = true

    /// アプリ設定
    @Published private(set) var appSettings: AppSettings

    // MARK: - ストリーム監視

    /// ストリーム監視用Task
    private var streamObservationTask: Task<Void, Never>?

    // MARK: - 初期化

    /// ContentViewModelを初期化
    public init(engine: any QuotaEngineProtocol, provider: Provider) {
        self.engine = engine
        self.currentProvider = provider
        self.appSettings = AppSettings()
    }

    /// 初期データを非同期で読み込み
    public func loadInitialData() async {
        await engine.setBaseInterval(TimeInterval(appSettings.updateInterval.rawValue))
        await updateState()
        startObservingEngine()
        isLoadingInitialData = false
    }

    // MARK: - 状態同期

    /// エンジンから状態を取得しUI状態を更新
    public func updateState() async {
        let appState = await engine.getState()
        self.engineState = EngineState(from: appState)
        self.snapshot = await engine.getCurrentSnapshot()

        // メニューバータイトルを更新
        updateMenuBarTitle()

        // エラーメッセージを更新
        if !appState.lastError.isEmpty {
            self.errorMessage = appState.lastError
            // 認証エラーを判定
            updateAuthorizationError(appState.lastError)
        } else {
            self.errorMessage = nil
            self.authorizationError = false
        }
    }

    /// エラーメッセージから認証エラーかどうかを判定
    private func updateAuthorizationError(_ message: String) {
        // ProviderError.unauthorized のエラーメッセージで判定
        let authErrorKeywords = ["認証に失敗", "認証エラー", "unauthorized", "401", "403"]
        authorizationError = authErrorKeywords.contains { message.contains($0) }
    }

    /// メニューバータイトルを更新
    private func updateMenuBarTitle() {
        if isLoadingInitialData {
            menuBarTitle = "..."
            return
        }

        guard let snapshot = snapshot else {
            menuBarTitle = "N/A"
            return
        }

        var title = snapshot.primaryTitle
        if let pct = snapshot.primaryPct {
            title += " \(pct)%"
        }
        if let resetEpoch = snapshot.resetEpoch {
            title += " • \(TimeFormatter.formatTimeRemaining(resetEpoch: resetEpoch))"
        }
        menuBarTitle = title
    }

    // MARK: - ストリーム監視

    /// エンジンのAsyncStream監視を開始
    private func startObservingEngine() {
        guard streamObservationTask == nil else { return }
        streamObservationTask = Task {
            for await event in await engine.getEventStream() {
                await handleEvent(event)
            }
        }
    }

    /// エンジンイベントをハンドル
    private func handleEvent(_ event: QuotaEngineEvent) async {
        switch event {
        case .snapshotUpdated(let snapshot):
            self.snapshot = snapshot
            updateMenuBarTitle()
        case .fetchStarted:
            isFetching = true
        case .fetchSucceeded:
            isFetching = false
            authorizationError = false
        case .fetchFailed(let error):
            isFetching = false
            errorMessage = error
            updateAuthorizationError(error)
        }
    }

    // MARK: - ユーザーアクション

    /// 強制フェッチ実行
    public func forceFetch() async {
        isFetching = true
        errorMessage = nil
        authorizationError = false

        do {
            _ = try await engine.forceFetch()
            await updateState()
        } catch {
            errorMessage = error.localizedDescription
            updateAuthorizationError(error.localizedDescription)
        }
        isFetching = false
    }

    /// 状態をリフレッシュ
    public func refresh() async {
        await updateState()
    }

    // MARK: - 通知

    /// テスト通知を送信
    public func sendTestNotification() async {
        do {
            try await NotificationManager.shared.send(
                title: "QuotaWatch テスト通知",
                body: "これはテスト通知です。通知設定が正常に動作しています。"
            )
        } catch {
            errorMessage = "通知の送信に失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - ダッシュボード

    /// ダッシュボードを開く
    public func openDashboard() async {
        if let url = currentProvider.dashboardURL {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - 設定管理

    /// 更新間隔を設定
    public func setUpdateInterval(_ interval: UpdateInterval) async {
        await engine.setBaseInterval(TimeInterval(interval.rawValue))
    }

    /// 通知有効/無効を設定
    public func setNotificationsEnabled(_ enabled: Bool) async {
        if enabled {
            let status = await NotificationManager.shared.getAuthorizationStatus()
            if status != .authorized {
                // 権限要求の失敗は致命的ではないため、エラーは無視する
                try? await NotificationManager.shared.requestAuthorization()
            }
        }
    }

    /// Login Item有効/無効を設定
    public func setLoginItemEnabled(_ enabled: Bool) async {
        appSettings.loginItemEnabled = enabled
    }

    /// APIキーを保存してプロバイダー切り替えを再試行
    public func saveAPIKeyAndRetry(providerId: ProviderId, apiKey: String) async {
        logger.info("APIキー保存開始: \(providerId.displayName)")

        // KeychainStoreに保存
        let keychain = KeychainStore(providerId: providerId)
        do {
            try await keychain.write(apiKey: apiKey)
            logger.info("APIキー保存成功: \(providerId.displayName)")

            // プロバイダー切り替えを再試行
            await switchProvider(providerId)
        } catch {
            logger.error("APIキー保存エラー: \(error.localizedDescription)")
            errorMessage = "APIキーの保存に失敗しました: \(error.localizedDescription)"
        }
    }

    /// プロバイダーを切り替え（Engineを再初期化）
    public func switchProvider(_ providerId: ProviderId) async {
        logger.info("プロバイダー切り替え: \(providerId.displayName)")

        // プロバイダー設定を保存
        appSettings.providerId = providerId

        // プロバイダーを生成
        let newProvider = ProviderFactory.create(providerId: providerId)

        // Keychainを新しいプロバイダーで初期化
        let keychain = KeychainStore(providerId: providerId)

        // Engineを再初期化
        do {
            let persistence = PersistenceManager(customDirectoryURL: FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first!
                .appending(path: "com.quotawatch"))

            // 既存のEngineを停止
            await engine.stopRunLoop()

            // 新しいEngineを作成
            let newEngine = try await QuotaEngine(
                provider: newProvider,
                persistence: persistence,
                keychain: keychain
            )

            // プロバイダーを更新
            self.currentProvider = newProvider

            // 新しいEngineでフェッチ
            await newEngine.startRunLoop()
            _ = try await newEngine.forceFetch()

            logger.info("プロバイダー切り替え完了: \(providerId.displayName)")

            // APIキー未設定エラーをクリア
            apiKeyRequired = nil
        } catch {
            logger.error("プロバイダー切り替えエラー: \(error.localizedDescription)")

            // APIキー未設定エラーの場合
            if let engineError = error as? QuotaEngineError,
               case .apiKeyNotSet = engineError {
                // 切り替えようとしたプロバイダーIDを設定
                apiKeyRequired = providerId
            }
        }
    }

    // MARK: - ユーティリティ

    var providerDisplayName: String { currentProvider.displayName }
    var dashboardURL: URL? { currentProvider.dashboardURL }

    /// デバッグログをDesktopにエクスポート
    public func exportDebugLog() async -> URL? {
        await loggerManager.exportToDesktop()
    }
}

// MARK: - Equatable

extension ContentViewModel: Equatable {
    nonisolated public static func == (lhs: ContentViewModel, rhs: ContentViewModel) -> Bool {
        // 参照等価性（同じインスタンスかどうか）
        lhs === rhs
    }
}

//
//  ContentViewModel.swift
//  QuotaWatch
//
//  SwiftUIへ状態を供給する@MainActorのViewModel
//

import Foundation
import SwiftUI
import UserNotifications

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
        self.nextFetchEpoch = appState.nextFetchEpoch
        self.backoffFactor = appState.backoffFactor
        self.lastFetchEpoch = appState.lastFetchEpoch
        self.consecutiveFailureCount = appState.consecutiveFailureCount
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
    private let engine: QuotaEngine

    /// Provider（Z.ai等）
    private let provider: Provider

    /// ロガーマネージャー
    private let loggerManager: LoggerManager = .shared

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

    /// 初期データロード中かどうか
    @Published private(set) var isLoadingInitialData: Bool = true

    /// アプリ設定
    @Published private(set) var appSettings: AppSettings

    // MARK: - ストリーム監視

    /// ストリーム監視用Task
    private var streamObservationTask: Task<Void, Never>?

    // MARK: - 初期化

    /// ContentViewModelを初期化
    ///
    /// - Parameters:
    ///   - engine: QuotaEngine
    ///   - provider: Provider（Z.ai等）
    public init(engine: QuotaEngine, provider: Provider) {
        self.engine = engine
        self.provider = provider
        self.appSettings = AppSettings()

        Task {
            await loggerManager.log("ContentViewModel初期化完了", category: "UI")
        }
    }

    /// 初期データを非同期で読み込み
    ///
    /// 初期化完了を待ちたい場合は、このメソッドを呼び出してください。
    public func loadInitialData() async {
        // AppSettingsのupdateIntervalをEngineに反映
        await engine.setBaseInterval(TimeInterval(appSettings.updateInterval.rawValue))

        await updateState()
        // AsyncStream監視を開始
        startObservingEngine()

        // 初期ロード完了
        isLoadingInitialData = false
        await loggerManager.log("初期データロード完了", category: "UI")
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
        // 初期ロード中は「...」を表示
        if isLoadingInitialData {
            menuBarTitle = "..."
            Task {
                await loggerManager.log("メニューバータイトル更新: ...（初期ロード中）", category: "UI")
            }
            return
        }

        guard let snapshot = snapshot else {
            menuBarTitle = "N/A"
            Task {
                await loggerManager.log("メニューバータイトル更新: N/A", category: "UI")
            }
            return
        }

        // "GLM 5h 42% • 2h36m" 形式
        var title = snapshot.primaryTitle

        if let pct = snapshot.primaryPct {
            title += " \(pct)%"
        }

        if let resetEpoch = snapshot.resetEpoch {
            let remaining = TimeFormatter.formatTimeRemaining(resetEpoch: resetEpoch)
            title += " • \(remaining)"
        }

        menuBarTitle = title

        Task {
            await loggerManager.log("メニューバータイトル更新: \(title)", category: "UI")
        }
    }

    // MARK: - ストリーム監視

    /// エンジンのAsyncStream監視を開始
    private func startObservingEngine() {
        // 既に監視中の場合は何もしない
        guard streamObservationTask == nil else {
            Task {
                await loggerManager.log("AsyncStream監視は既に開始されています", category: "UI")
            }
            return
        }

        Task {
            await loggerManager.log("AsyncStream監視を開始します", category: "UI")
        }

        streamObservationTask = Task {
            for await event in await engine.getEventStream() {
                await handleEvent(event)
            }
        }
    }

    /// エンジンイベントをハンドル
    private func handleEvent(_ event: QuotaEngineEvent) async {
        await loggerManager.log("イベント受信: \(eventTypeString(event))", category: "UI")

        switch event {
        case .snapshotUpdated(let snapshot):
            self.snapshot = snapshot
            updateMenuBarTitle()
            await loggerManager.log("スナップショット更新: \(snapshot.primaryTitle)", category: "UI")

        case .fetchStarted:
            isFetching = true
            await loggerManager.log("フェッチ状態更新: true", category: "UI")

        case .fetchSucceeded:
            isFetching = false
            authorizationError = false
            await loggerManager.log("フェッチ成功", category: "UI")

        case .fetchFailed(let error):
            isFetching = false
            errorMessage = error
            // 認証エラーを判定
            updateAuthorizationError(error)
            await loggerManager.log("フェッチ失敗: \(error)", category: "UI")
        }
    }

    /// イベントタイプの文字列表現を取得
    private func eventTypeString(_ event: QuotaEngineEvent) -> String {
        switch event {
        case .snapshotUpdated:
            return "snapshotUpdated"
        case .fetchStarted:
            return "fetchStarted"
        case .fetchSucceeded:
            return "fetchSucceeded"
        case .fetchFailed:
            return "fetchFailed"
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
            await loggerManager.log("強制フェッチ成功", category: "UI")
        } catch {
            await loggerManager.log("強制フェッチエラー: \(error.localizedDescription)", category: "UI")
            errorMessage = error.localizedDescription
            // 認証エラーを判定
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
            await loggerManager.log("テスト通知を送信しました", category: "UI")
        } catch {
            await loggerManager.log("テスト通知エラー: \(error.localizedDescription)", category: "UI")
            errorMessage = "通知の送信に失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - ダッシュボード

    /// ダッシュボードを開く
    public func openDashboard() async {
        guard let dashboardURL = provider.dashboardURL else {
            await loggerManager.log("ダッシュボードURLが設定されていません", category: "UI")
            return
        }

        NSWorkspace.shared.open(dashboardURL)
        await loggerManager.log("ダッシュボードを開きました: \(dashboardURL)", category: "UI")
    }

    // MARK: - 設定管理

    /// 更新間隔を設定
    ///
    /// - Parameter interval: 更新間隔
    public func setUpdateInterval(_ interval: UpdateInterval) async {
        await loggerManager.log("更新間隔を変更: \(interval.displayName)", category: "UI")
        await engine.setBaseInterval(TimeInterval(interval.rawValue))
    }

    /// 通知有効/無効を設定
    ///
    /// - Parameter enabled: 有効にする場合はtrue
    public func setNotificationsEnabled(_ enabled: Bool) async {
        await loggerManager.log("通知設定を変更: \(enabled ? "有効" : "無効")", category: "UI")

        if enabled {
            // 権限がまだない場合は要求
            let status = await NotificationManager.shared.getAuthorizationStatus()
            if status != .authorized {
                do {
                    _ = try await NotificationManager.shared.requestAuthorization()
                } catch {
                    await loggerManager.log("通知権限の取得に失敗: \(error.localizedDescription)", category: "UI")
                    errorMessage = "通知権限の取得に失敗しました"
                }
            }
        }
    }

    /// Login Item有効/無効を設定
    ///
    /// - Parameter enabled: 有効にする場合はtrue
    public func setLoginItemEnabled(_ enabled: Bool) async {
        // AppSettingsを直接更新（didSetでupdateLoginItemStatusが呼ばれる）
        appSettings.loginItemEnabled = enabled
        await loggerManager.log("Login Item設定を変更: \(enabled ? "有効" : "無効")", category: "UI")
    }

    // MARK: - ユーティリティ

    /// Provider表示名
    var providerDisplayName: String {
        return provider.displayName
    }

    /// ダッシュボードURL
    var dashboardURL: URL? {
        return provider.dashboardURL
    }

    // MARK: - ログエクスポート

    /// デバッグログをDesktopにエクスポート
    ///
    /// - Returns: エクスポート成功時はファイルパス、失敗時はnil
    public func exportDebugLog() async -> URL? {
        return await loggerManager.exportToDesktop()
    }
}

// MARK: - Equatable

extension ContentViewModel: Equatable {
    nonisolated public static func == (lhs: ContentViewModel, rhs: ContentViewModel) -> Bool {
        // 参照等価性（同じインスタンスかどうか）
        lhs === rhs
    }
}

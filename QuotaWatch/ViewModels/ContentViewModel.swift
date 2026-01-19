//
//  ContentViewModel.swift
//  QuotaWatch
//
//  SwiftUIへ状態を供給する@MainActorのViewModel
//

import Foundation
import OSLog
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

    // MARK: - UI状態（@Published）

    /// 現在のスナップショット
    @Published private(set) var snapshot: UsageSnapshot?

    /// エンジン状態
    @Published private(set) var engineState: EngineState?

    /// メニューバータイトル
    @Published private(set) var menuBarTitle: String = "QuotaWatch"

    /// フェッチ中かどうか
    @Published private(set) var isFetching: Bool = false

    /// エラーメッセージ
    @Published private(set) var errorMessage: String?

    /// アプリ設定
    @Published private(set) var appSettings: AppSettings

    // MARK: - ロガー

    private let logger = Logger(subsystem: "com.quotawatch.viewmodel", category: "ContentViewModel")

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
    }

    /// 初期データを非同期で読み込み
    ///
    /// 初期化完了を待ちたい場合は、このメソッドを呼び出してください。
    public func loadInitialData() async {
        await updateState()
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
        } else {
            self.errorMessage = nil
        }
    }

    /// メニューバータイトルを更新
    private func updateMenuBarTitle() {
        guard let snapshot = snapshot else {
            menuBarTitle = "Quota N/A"
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
    }

    // MARK: - ユーザーアクション

    /// 強制フェッチ実行
    public func forceFetch() async {
        isFetching = true
        errorMessage = nil

        do {
            _ = try await engine.forceFetch()
            await updateState()
            logger.log("強制フェッチ成功")
        } catch {
            logger.error("強制フェッチエラー: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
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
            logger.log("テスト通知を送信しました")
        } catch {
            logger.error("テスト通知エラー: \(error.localizedDescription)")
            errorMessage = "通知の送信に失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - ダッシュボード

    /// ダッシュボードを開く
    public func openDashboard() async {
        guard let dashboardURL = provider.dashboardURL else {
            logger.warning("ダッシュボードURLが設定されていません")
            return
        }

        NSWorkspace.shared.open(dashboardURL)
        logger.log("ダッシュボードを開きました: \(dashboardURL)")
    }

    // MARK: - 設定管理

    /// 更新間隔を設定
    ///
    /// - Parameter interval: 更新間隔
    public func setUpdateInterval(_ interval: UpdateInterval) async {
        logger.log("更新間隔を変更: \(interval.displayName)")
        await engine.setBaseInterval(TimeInterval(interval.rawValue))
    }

    /// 通知有効/無効を設定
    ///
    /// - Parameter enabled: 有効にする場合はtrue
    public func setNotificationsEnabled(_ enabled: Bool) async {
        logger.log("通知設定を変更: \(enabled ? "有効" : "無効")")

        if enabled {
            // 権限がまだない場合は要求
            let status = await NotificationManager.shared.getAuthorizationStatus()
            if status != .authorized {
                do {
                    _ = try await NotificationManager.shared.requestAuthorization()
                } catch {
                    logger.error("通知権限の取得に失敗: \(error.localizedDescription)")
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
        logger.log("Login Item設定を変更: \(enabled ? "有効" : "無効")")
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
}

// MARK: - Equatable

extension ContentViewModel: Equatable {
    nonisolated public static func == (lhs: ContentViewModel, rhs: ContentViewModel) -> Bool {
        // 参照等価性（同じインスタンスかどうか）
        lhs === rhs
    }
}

//
//  ContentViewModel.swift
//  QuotaWatch
//
//  SwiftUIへ状態を供給する@MainActorのViewModel
//

import Foundation
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

    // MARK: - ロガー

    private let logger = Logger(subsystem: "com.quotawatch.viewmodel", category: "ContentViewModel")

    // MARK: - 初期化

    /// ContentViewModelを初期化
    ///
    /// - Parameter engine: QuotaEngine
    public init(engine: QuotaEngine) {
        self.engine = engine
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
}

// MARK: - Equatable

extension ContentViewModel: Equatable {
    nonisolated public static func == (lhs: ContentViewModel, rhs: ContentViewModel) -> Bool {
        // 参照等価性（同じインスタンスかどうか）
        lhs === rhs
    }
}

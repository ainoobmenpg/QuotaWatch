//
//  QuotaEngine.swift
//  QuotaWatch
//
//  QuotaEngine Actor - フェッチとバックオフの制御ロジック
//

import Foundation
import AppKit
import OSLog

// MARK: - QuotaEngineError

/// QuotaEngineが発生させるエラーの型
public enum QuotaEngineError: Error, Sendable, LocalizedError {
    /// APIキーが設定されていない
    case apiKeyNotSet

    /// キャッシュデータが存在しない
    case noCachedData

    /// 致命的なエラー
    case fatalError(String)

    public var errorDescription: String? {
        switch self {
        case .apiKeyNotSet:
            return "APIキーが設定されていません"
        case .noCachedData:
            return "キャッシュデータが存在しません"
        case .fatalError(let message):
            return "致命的なエラー: \(message)"
        }
    }
}

// MARK: - QuotaEngine

/// クォータ情報のフェッチとバックオフ制御を担当するEngine
///
/// Actorによりスレッドセーフ性を保証し、多重実行を防止します。
public actor QuotaEngine {
    // MARK: - 依存関係

    /// Provider（Z.ai等）
    private let provider: Provider

    /// 永続化管理
    private let persistence: PersistenceManager

    /// APIキーストア
    private let keychain: KeychainStore

    // MARK: - 状態

    /// アプリケーション実行状態
    private var state: AppState

    /// 現在のスナップショット（キャッシュ）
    private var currentSnapshot: UsageSnapshot?

    /// 基本フェッチ間隔（秒）
    private var baseInterval: TimeInterval

    /// Clock（ContinuousClock固定）
    /// 注: テスト容易性のためClockプロトコルを使用したいが、
    /// Swift 6の存在型制限により、暫定的にContinuousClockを直接使用します。
    /// 将来的には Clock プロトコルを使用してテスト容易性を向上させる予定です。
    private let clock: ContinuousClock

    /// runLoopのTask参照
    private var runLoopTask: Task<Void, Never>?

    /// スリープ復帰検知用オブザーバー
    private var sleepObserver: NSObjectProtocol?

    // MARK: - ロガー

    private let logger = Logger(subsystem: "com.quotawatch.engine", category: "QuotaEngine")

    // MARK: - 初期化

    /// QuotaEngineを初期化
    ///
    /// - Parameters:
    ///   - provider: Provider（Z.ai等）
    ///   - persistence: 永続化管理
    ///   - keychain: APIキーストア
    ///   - clock: Clock（デフォルト: ContinuousClock）
    public init(
        provider: Provider,
        persistence: PersistenceManager,
        keychain: KeychainStore,
        clock: ContinuousClock = ContinuousClock()
    ) async {
        self.provider = provider
        self.persistence = persistence
        self.keychain = keychain
        self.clock = clock
        self.baseInterval = AppConstants.minBaseInterval

        // 状態を復元
        self.state = await persistence.loadOrDefaultState()

        logger.log("QuotaEngine初期化: provider=\(provider.id)")

        // 強制終了後の復旧処理
        await recoverFromCrash()
    }

    // MARK: - 公開API - 状態取得

    /// 現在のスナップショットを取得
    ///
    /// - Returns: 現在のスナップショット（存在しない場合はnil）
    public func getCurrentSnapshot() -> UsageSnapshot? {
        return currentSnapshot
    }

    /// 現在の状態を取得
    ///
    /// - Returns: 現在のAppState
    public func getState() -> AppState {
        return state
    }

    /// 次回フェッチ時刻を取得
    ///
    /// - Returns: 次回フェッチ時刻（epoch秒）
    public func getNextFetchEpoch() -> Int {
        return state.nextFetchEpoch
    }

    // MARK: - 公開API - フェッチ判定

    /// フェッチが必要かどうかを判定
    ///
    /// - Returns: フェッチが必要な場合はtrue
    public func shouldFetch() -> Bool {
        let now = Date().epochSeconds
        return now >= state.nextFetchEpoch
    }

    // MARK: - 公開API - フェッチ実行

    /// 時刻到達ならフェッチを実行
    ///
    /// 時刻が到達していない場合は何もせず、現在のスナップショットを返します。
    ///
    /// - Returns: 最新のUsageSnapshot
    /// - Throws: QuotaEngineError
    public func fetchIfDue() async throws -> UsageSnapshot {
        if shouldFetch() {
            return try await fetch()
        }
        logger.debug("フェッチ時刻未到達、キャッシュを返す")
        guard let snapshot = currentSnapshot else {
            throw QuotaEngineError.noCachedData
        }
        return snapshot
    }

    /// 強制フェッチ（バックオフ無視）
    ///
    /// - Returns: 最新のUsageSnapshot
    /// - Throws: QuotaEngineError
    public func forceFetch() async throws -> UsageSnapshot {
        logger.debug("強制フェッチ実行")
        let snapshot = try await performFetch()

        // 強制フェッチ成功後、バックオフをリセットして通常スケジュールに戻す
        state.backoffFactor = 1
        state.lastError = ""

        let interval = calculateNextFetchInterval()
        state.nextFetchEpoch = Date().epochSeconds + Int(interval)

        try await persistence.saveState(state)

        logger.log("強制フェッチ成功: 次回=\(self.state.nextFetchEpoch)")
        return snapshot
    }

    // MARK: - 内部メソッド - フェッチ

    /// メインフェッチロジック
    ///
    /// - Returns: 最新のUsageSnapshot
    /// - Throws: QuotaEngineError
    private func fetch() async throws -> UsageSnapshot {
        logger.debug("フェッチ実行開始")

        do {
            let snapshot = try await performFetch()

            // 成功時: バックオフ係数をリセット
            state.backoffFactor = 1
            state.lastError = ""

            // 次回フェッチ時刻を計算
            let interval = calculateNextFetchInterval()
            state.nextFetchEpoch = Date().epochSeconds + Int(interval)

            // 状態を保存
            try await persistence.saveState(state)

            logger.log("フェッチ成功: 次回=\(self.state.nextFetchEpoch)")
            return snapshot

        } catch let error as ProviderError {
            // Providerエラーをハンドリング
            let decision = provider.classifyBackoff(error: error)
            try await handleError(error: error, decision: decision)

            // 再試行可能であれば、キャッシュを返す
            guard let snapshot = currentSnapshot else {
                throw QuotaEngineError.noCachedData
            }
            return snapshot

        } catch {
            // その他のエラー
            logger.error("予期しないエラー: \(error)")
            state.lastError = error.localizedDescription
            try await persistence.saveState(state)
            throw error
        }
    }

    /// APIキー取得 → Provider.fetchUsage() → キャッシュ保存
    ///
    /// - Returns: UsageSnapshot
    /// - Throws: QuotaEngineError, ProviderError
    private func performFetch() async throws -> UsageSnapshot {
        // APIキーを取得
        let apiKey: String
        do {
            guard let key = try await keychain.read() else {
                logger.error("APIキーが設定されていません")
                throw QuotaEngineError.apiKeyNotSet
            }
            apiKey = key
        } catch let error as KeychainError {
            // Keychainアクセスエラー（アクセス拒否等）は致命的エラー
            logger.error("Keychainアクセスエラー: \(error)")
            throw QuotaEngineError.fatalError("Keychainアクセスに失敗しました: \(error.localizedDescription)")
        }

        // Providerでフェッチ
        let snapshot = try await provider.fetchUsage(apiKey: apiKey)

        // スナップショットを更新
        currentSnapshot = snapshot

        // キャッシュに保存
        try await persistence.saveCache(snapshot)

        // 最終フェッチ時刻を更新
        state.lastFetchEpoch = Date().epochSeconds

        return snapshot
    }

    // MARK: - 内部メソッド - エラーハンドリング

    /// エラーをハンドリングし、バックオフ制御を行う
    ///
    /// - Parameters:
    ///   - error: 発生したエラー
    ///   - decision: バックオフ判定結果
    /// - Throws: QuotaEngineError
    private func handleError(error: ProviderError, decision: BackoffDecision) async throws {
        logger.error("エラー発生: \(error.localizedDescription)")

        switch decision.action {
        case .proceed:
            // 通常リトライ: 通常間隔で次回フェッチ時刻を設定
            logger.debug("通常リトライ: 次回は通常間隔で")
            let interval = calculateNextFetchInterval()
            state.nextFetchEpoch = Date().epochSeconds + Int(interval)

        case .backoff:
            // バックオフ: バックオフ係数を倍増（上限15）
            let newFactor = self.state.backoffFactor * 2
            self.state.backoffFactor = min(newFactor, 15)

            // バックオフ間隔を計算して次回フェッチ時刻を設定
            let interval = calculateBackoffInterval()
            self.state.nextFetchEpoch = Date().epochSeconds + Int(interval)

            logger.warning(
                "バックオフ適用: factor=\(self.state.backoffFactor), nextFetch=\(self.state.nextFetchEpoch)"
            )

        case .stop:
            // 停止: 致命的エラーとして扱う
            logger.error("致命的なエラーで停止: \(error.localizedDescription)")
            throw QuotaEngineError.fatalError(error.localizedDescription)
        }

        // エラー情報を保存
        state.lastError = decision.description
        try await persistence.saveState(state)

        // 再試行不可能な場合はエラーをスロー
        if !decision.isRetryable {
            throw QuotaEngineError.fatalError(decision.description)
        }
    }

    // MARK: - 内部メソッド - 間隔計算

    /// 次回フェッチ間隔を計算
    ///
    /// - Returns: フェッチ間隔（秒）
    private func calculateNextFetchInterval() -> TimeInterval {
        return baseInterval
    }

    /// バックオフ時のフェッチ間隔を計算
    ///
    /// - Returns: フェッチ間隔（秒）。バックオフ係数、最大値、ジッターを考慮
    private func calculateBackoffInterval() -> TimeInterval {
        // 計算式: baseInterval * backoffFactor
        let wait = baseInterval * Double(state.backoffFactor)

        // 最大値でクリップ
        let cappedWait = min(wait, AppConstants.maxBackoffSeconds)

        // ジッターを追加（0-15秒）
        let jitter = Double.random(in: 0...AppConstants.jitterSeconds)
        let totalWait = cappedWait + jitter

        logger.debug(
            "バックオフ間隔計算: factor=\(self.state.backoffFactor), wait=\(Int(wait))秒, capped=\(Int(cappedWait))秒, jitter=\(Int(jitter))秒, total=\(Int(totalWait))秒"
        )

        return totalWait
    }

    // MARK: - 内部メソッド - 復旧

    /// 強制終了後の復旧処理
    ///
    /// 初期化時に以下を行います：
    /// 1. キャッシュファイルからスナップショットを復元
    /// 2. `nextFetchEpoch`が過去の場合、現在時刻に補正
    /// 3. 連続失敗カウンターが閾値以上の場合、リセット
    private func recoverFromCrash() async {
        logger.debug("復旧処理開始")

        // キャッシュからスナップショットを復元
        if let snapshot = await persistence.loadCacheOrDefault() {
            currentSnapshot = snapshot
            logger.log("キャッシュ復元成功: \(snapshot.primaryTitle)")
        } else {
            logger.debug("キャッシュが存在しません")
        }

        // nextFetchEpochが過去の場合、現在時刻に補正
        let now = Date().epochSeconds
        if self.state.nextFetchEpoch < now {
            logger.debug("nextFetchEpochが過去のため、現在時刻に補正: \(self.state.nextFetchEpoch) -> \(now)")
            self.state.nextFetchEpoch = now
        }

        // 連続失敗カウンターが閾値以上の場合、リセット
        if self.state.consecutiveFailureCount >= AppConstants.maxConsecutiveFailures {
            logger.log("連続失敗カウンターが閾値(\(AppConstants.maxConsecutiveFailures))以上のため、リセットします")
            self.state.consecutiveFailureCount = 0
        }

        // 状態を保存
        try? await persistence.saveState(self.state)

        logger.log("復旧処理完了: nextFetch=\(self.state.nextFetchEpoch)")
    }

    // MARK: - 公開API - 設定更新

    /// 基本フェッチ間隔を設定
    ///
    /// - Parameter interval: フェッチ間隔（秒）
    public func setBaseInterval(_ interval: TimeInterval) {
        let clamped = max(interval, AppConstants.minBaseInterval)
        self.baseInterval = clamped
        logger.debug("基本フェッチ間隔を更新: \(Int(clamped))秒")
    }

    // MARK: - 公開API - runLoop制御

    /// runLoopを開始
    ///
    /// 定期フェッチを実行するループを開始し、スリープ復帰検知を設定します。
    public func startRunLoop() {
        // 既に実行中の場合は何もしない
        guard runLoopTask == nil else {
            logger.debug("runLoopは既に実行中です")
            return
        }

        logger.log("runLoopを開始します")

        // runLoopタスクを開始
        runLoopTask = Task {
            await runLoop()
        }

        // スリープ復帰検知を設定
        setupSleepObserver()
    }

    /// runLoopを停止
    ///
    /// 実行中のループをキャンセルし、通知監視を解除します。
    public func stopRunLoop() async {
        logger.log("runLoopを停止します")

        // タスクをキャンセル
        runLoopTask?.cancel()
        runLoopTask = nil

        // 通知監視を解除
        if let observer = sleepObserver {
            NotificationCenter.default.removeObserver(observer)
            sleepObserver = nil
            logger.debug("スリープ復帰検知を解除しました")
        }

        // 状態を永続化（完了を待つ）
        do {
            try await persistence.saveState(state)
            logger.log("runLoop停止: 状態を永続化しました")
        } catch {
            logger.error("runLoop停止: 状態の永続化に失敗: \(error.localizedDescription)")
        }
    }

    // MARK: - 内部メソッド - runLoop

    /// メインループ実装
    ///
    /// 設定された間隔で定期フェッチを実行します。
    /// `ContinuousClock.sleep(until:)` で次回フェッチ時刻まで待機し、
    /// Taskキャンセルに対応します。
    private func runLoop() async {
        logger.log("runLoop: 開始")

        // キャンセル時のクリーンアップ
        defer {
            logger.log("runLoop: 終了")
        }

        // メインループ
        while !Task.isCancelled {
            do {
                // フェッチ時刻まで待機
                let nowEpoch = Date().epochSeconds
                let nextFetchEpoch = state.nextFetchEpoch

                if nextFetchEpoch > nowEpoch {
                    let waitSeconds = nextFetchEpoch - nowEpoch
                    logger.debug("runLoop: \(waitSeconds)秒間スリープします")

                    // 指定時刻までスリープ
                    let deadline = self.clock.now.advanced(by: .seconds(Int64(waitSeconds)))
                    _ = try? await self.clock.sleep(until: deadline, tolerance: nil)

                    // キャンセルチェック
                    if Task.isCancelled {
                        logger.debug("runLoop: キャンセル検出（スリープ中）")
                        break
                    }
                }

                // フェッチ実行
                logger.debug("runLoop: フェッチを実行します")
                _ = try await fetch()

                // 成功時に連続失敗カウンターをリセット
                if state.consecutiveFailureCount > 0 {
                    state.consecutiveFailureCount = 0
                    try? await persistence.saveState(state)
                }

                // キャンセルチェック（フェッチ後）
                if Task.isCancelled {
                    logger.debug("runLoop: キャンセル検出（フェッチ後）")
                    break
                }

            } catch {
                // 連続失敗カウンターをインクリメント
                state.consecutiveFailureCount += 1

                // 閾値チェック
                if state.consecutiveFailureCount >= AppConstants.maxConsecutiveFailures {
                    logger.error("runLoop: 連続失敗が閾値(\(AppConstants.maxConsecutiveFailures))に達したため、ループを停止します")
                    try? await persistence.saveState(state)
                    break
                }

                // 状態を永続化
                try? await persistence.saveState(state)

                // エラー時もループは継続
                logger.error("runLoop: フェッチエラー: \(error.localizedDescription)")

                // キャンセルチェック
                if Task.isCancelled {
                    logger.debug("runLoop: キャンセル検出（エラーハンドリング中）")
                    break
                }
            }
        }
    }

    // MARK: - 内部メソッド - スリープ復帰検知

    /// スリープ復帰検知用の通知監視を設定
    ///
    /// Actor内で直接NotificationCenterを使用できないため、
    /// ダミーパススルー関数を経由して設定します。
    ///
    /// 注: Swift 6のactorとMainActorの相互作用により、
    /// スリープ復帰検知は暫定的に無効化しています。
    /// 将来的に別のアプローチで実装する予定です。
    private func setupSleepObserver() {
        // TODO: #16 Swift 6のactorモデルに対応したスリープ復帰検知を実装
        logger.debug("スリープ復帰検知は暫定的に無効化されています（Issue #16）")
    }

    /// スリープ復帰ハンドラ
    ///
    /// 復帰時、現在時刻が次回フェッチ時刻以上の場合は即時フェッチを実行します。
    private func handleWake() async {
        logger.log("スリープから復帰しました")

        let now = Date().epochSeconds
        if now >= state.nextFetchEpoch {
            logger.log("スリープ復帰時: フェッチ時刻到達、即時フェッチを実行します")
            do {
                _ = try await fetch()
            } catch {
                logger.error("スリープ復帰時のフェッチエラー: \(error.localizedDescription)")
            }
        } else {
            let waitSeconds = state.nextFetchEpoch - now
            logger.debug("スリープ復帰時: 次回フェッチまで\(waitSeconds)秒")
        }
    }

    // MARK: - テストヘルパー（DEBUGビルドのみ）

    #if DEBUG
    /// 次回フェッチ時刻を強制的に設定（テスト用）
    ///
    /// テストで60秒待機することを回避するために使用します。
    ///
    /// - Parameter epoch: 次回フェッチ時刻（epoch秒）
    public func overrideNextFetchEpoch(_ epoch: Int) {
        self.state.nextFetchEpoch = epoch
    }
    #endif
}

//
//  ResetNotifier.swift
//  QuotaWatch
//
//  クォータリセット通知を管理
//

import AppKit
import Foundation
import OSLog

// MARK: - ResetNotifierError

/// ResetNotifierが発生させるエラーの型
public enum ResetNotifierError: Error, Sendable, LocalizedError {
    /// 通知送信に失敗
    case notificationFailed(String)

    /// 状態の保存に失敗
    case stateSaveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notificationFailed(let message):
            return "通知送信に失敗: \(message)"
        case .stateSaveFailed(let message):
            return "状態保存に失敗: \(message)"
        }
    }
}

// MARK: - ResetNotifier

/// クォータリセット通知を管理
public actor ResetNotifier {
    private let engine: any QuotaEngineProtocol
    private let notificationManager: NotificationManager
    private let persistence: PersistenceManager
    private let loggerManager: LoggerManager = .shared
    private var task: Task<Void, Never>?

    /// スリープ復帰検知用オブザーバー
    /// Note: nonisolated(unsafe) は @MainActor からアクセスするために必要
    private nonisolated(unsafe) var wakeObserver: NSObjectProtocol?

    private let logger = Logger(subsystem: "com.quotawatch.notifier", category: "ResetNotifier")

    public init(
        engine: any QuotaEngineProtocol,
        notificationManager: NotificationManager = .shared,
        persistence: PersistenceManager
    ) {
        self.engine = engine
        self.notificationManager = notificationManager
        self.persistence = persistence
    }

    // MARK: - 公開API - ライフサイクル

    /// 通知チェックを開始
    public func start() {
        guard task == nil else { return }
        logger.log("ResetNotifierを開始")
        Task {
            await loggerManager.log("ResetNotifierを開始", category: "RESET")
        }

        task = Task {
            await runLoop()
        }

        // スリープ復帰検知を設定
        Task { @MainActor in
            self.setupWakeObserver()
        }
    }

    /// 通知チェックを停止
    public func stop() {
        task?.cancel()
        task = nil

        // @MainActor で実行
        Task { @MainActor in
            self.teardownWakeObserver()
        }

        logger.log("ResetNotifierを停止")
        Task {
            await loggerManager.log("ResetNotifierを停止", category: "RESET")
        }
    }

    // MARK: - 内部メソッド - runLoop

    private func runLoop() async {
        while !Task.isCancelled {
            do {
                try await checkReset()
            } catch {
                logger.error("リセットチェックエラー: \(error.localizedDescription)")
            }

            // 1分待機
            do {
                try await Task.sleep(nanoseconds: UInt64(AppConstants.notificationCheckInterval * 1_000_000_000))
            } catch {
                break
            }
        }
    }

    // MARK: - 内部メソッド - リセットチェック

    private func checkReset() async throws {
        let state = await engine.getState()
        let now = Date().epochSeconds

        // リセット時刻到達かつ未通知の場合
        if now >= state.lastKnownResetEpoch &&
           state.lastNotifiedResetEpoch != state.lastKnownResetEpoch {

            logger.log("リセット検知: 通知を送信します")
            await loggerManager.log("リセット検知: 通知を送信します", category: "RESET")

            // 通知送信
            do {
                try await notificationManager.send(
                    title: "クォータリセット",
                    body: "5時間クォータがリセットされました"
                )

                // 重複防止: lastKnownResetEpochを未来に進める
                var updatedState = state
                updatedState.lastNotifiedResetEpoch = state.lastKnownResetEpoch
                updatedState.lastKnownResetEpoch += Int(AppConstants.resetIntervalSeconds)

                try await persistence.saveState(updatedState)

                logger.log("通知送信成功: epochを\(updatedState.lastKnownResetEpoch)に更新")
                await loggerManager.log("通知送信成功: epoch=\(updatedState.lastKnownResetEpoch)", category: "RESET")

            } catch let error as NotificationManagerError {
                logger.error("通知送信エラー: \(error.localizedDescription)")
                await loggerManager.log("通知送信エラー: \(error.localizedDescription)", category: "RESET")
                throw ResetNotifierError.notificationFailed(error.localizedDescription)
            } catch {
                logger.error("状態保存エラー: \(error.localizedDescription)")
                await loggerManager.log("状態保存エラー: \(error.localizedDescription)", category: "RESET")
                throw ResetNotifierError.stateSaveFailed(error.localizedDescription)
            }
        }
    }

    // MARK: - 内部メソッド - スリープ復帰検知

    /// スリープ復帰検知用の通知監視を設定
    @MainActor
    private func setupWakeObserver() {
        let center = NSWorkspace.shared.notificationCenter

        wakeObserver = center.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.handleWakeNotification()
            }
        }

        logger.log("スリープ復帰検知を開始しました")
    }

    /// スリープ復帰検知用の通知監視を解除
    @MainActor
    private func teardownWakeObserver() {
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            wakeObserver = nil
            logger.log("スリープ復帰検知を解除しました")
        }
    }

    /// スリープ復帰ハンドラ
    ///
    /// ResetNotifierのリセットチェックと、QuotaEngineへの即時フェッチ要求を実行します。
    private func handleWakeNotification() async {
        logger.log("スリープから復帰しました - 即時チェックを実行")
        await loggerManager.log("スリープから復帰しました - ResetNotifier", category: "RESET")

        // ResetNotifierのリセットチェック
        do {
            try await checkReset()
        } catch {
            logger.error("スリープ復帰時のチェックエラー: \(error.localizedDescription)")
            await loggerManager.log("スリープ復帰時のチェックエラー: \(error.localizedDescription)", category: "RESET")
        }

        // QuotaEngineへの即時フェッチ要求（Issue #16対応）
        await engine.handleWakeFromSleep()
    }
}

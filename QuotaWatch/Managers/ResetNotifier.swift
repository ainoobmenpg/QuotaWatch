//
//  ResetNotifier.swift
//  QuotaWatch
//
//  クォータリセット通知を管理
//

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
    private let engine: QuotaEngine
    private let notificationManager: NotificationManager
    private let persistence: PersistenceManager
    private var task: Task<Void, Never>?

    private let logger = Logger(subsystem: "com.quotawatch.notifier", category: "ResetNotifier")

    public init(
        engine: QuotaEngine,
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

        task = Task {
            await runLoop()
        }
    }

    /// 通知チェックを停止
    public func stop() {
        task?.cancel()
        task = nil
        logger.log("ResetNotifierを停止")
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

            } catch let error as NotificationManagerError {
                logger.error("通知送信エラー: \(error.localizedDescription)")
                throw ResetNotifierError.notificationFailed(error.localizedDescription)
            } catch {
                logger.error("状態保存エラー: \(error.localizedDescription)")
                throw ResetNotifierError.stateSaveFailed(error.localizedDescription)
            }
        }
    }
}

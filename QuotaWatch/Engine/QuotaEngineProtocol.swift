//
//  QuotaEngineProtocol.swift
//  QuotaWatch
//
//  QuotaEngineのプロトコル定義
//

import Foundation

// MARK: - QuotaEngineProtocol

/// QuotaEngineのプロトコル（テスト容易性のための抽象化）
///
/// Actor隔離問題に対処するため、QuotaEngineの公開APIをプロトコルとして定義します。
/// テストコードではMockQuotaEngineを使用することで、actorの隔離制約を回避できます。
///
/// Note: Actorプロトコルのため、メソッド自体は同期定義ですが、
/// 外部から呼び出す際にはactor隔離によりawaitが必要です。
///
/// Note: DEBUG用メソッドは#if DEBUGで条件付き定義されています。
/// Swiftのactor宣言では条件コンパイルによるプロトコル切り替えができないため、
/// 単一のプロトコル内でDEBUGメソッドを条件付きで定義しています。
public protocol QuotaEngineProtocol: Actor {
    /// 現在のスナップショットを取得
    func getCurrentSnapshot() -> UsageSnapshot?

    /// イベントストリームを取得
    func getEventStream() -> AsyncStream<QuotaEngineEvent>

    /// 現在の状態を取得
    func getState() -> AppState

    /// 次回フェッチ時刻を取得
    func getNextFetchEpoch() -> Int

    /// フェッチが必要かどうかを判定
    func shouldFetch() -> Bool

    /// 時刻到達ならフェッチを実行
    func fetchIfDue() async throws -> UsageSnapshot

    /// 強制フェッチ（バックオフ無視）
    func forceFetch() async throws -> UsageSnapshot

    /// 基本フェッチ間隔を設定
    func setBaseInterval(_ interval: TimeInterval)

    /// runLoopを開始
    func startRunLoop()

    /// runLoopを停止
    func stopRunLoop() async

    /// スリープ復帰ハンドラ
    func handleWakeFromSleep() async

    #if DEBUG
    /// 次回フェッチ時刻を強制的に設定（テスト用）
    func overrideNextFetchEpoch(_ epoch: Int)

    /// ログ内容取得（テスト用）
    func getDebugLogContents() async -> String

    /// ログクリア（テスト用）
    func clearDebugLog() async
    #endif
}

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

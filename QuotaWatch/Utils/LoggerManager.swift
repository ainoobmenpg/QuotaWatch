//
//  LoggerManager.swift
//  QuotaWatch
//
//  ロガーを一元管理するマネージャー
//

import Foundation
import OSLog

/// ロガーを一元管理するマネージャー
///
/// DebugLoggerのシングルトンインスタンスを管理し、
/// コンポーネント間でのインスタンス重複作成を防ぎます。
public actor LoggerManager {
    /// シングルトンインスタンス
    public static let shared = LoggerManager()

    /// DebugLogger（遅延初期化）
    private var debugLogger: DebugLogger?

    /// ログファイルのパス
    private let logFileURL: URL

    /// ログサイズ上限（100KB）
    private let maxLogSize: Int = 100 * 1024

    /// OSLog logger
    private let logger = Logger(subsystem: "com.quotawatch.LoggerManager", category: "LoggerManager")

    private init() {
        // Application Supportディレクトリを使用
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "com.quotawatch.QuotaWatch"
        self.logFileURL = appSupport.appending(path: "\(bundleID)/debug.log")

        // ディレクトリを作成
        let directoryURL = logFileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    /// DebugLoggerを取得（必要なときに初期化）
    ///
    /// - Returns: DebugLoggerインスタンス
    public func getDebugLogger() -> DebugLogger? {
        if let existing = debugLogger {
            return existing
        }

        // ディレクトリを作成
        let directoryURL = logFileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        let logger = DebugLogger(logFileURL: logFileURL, clearOnInitialize: false)
        self.debugLogger = logger
        return logger
    }

    /// ログ出力
    ///
    /// DEBUG/RELEASE両方でログを出力します。
    /// ファイルとOSLogの両方に出力します。
    ///
    /// - Parameters:
    ///   - message: ログメッセージ
    ///   - category: カテゴリ（デフォルト: "GENERAL"）
    public func log(_ message: String, category: String = "GENERAL") async {
        // OSLog にも出力（確認用）
        logger.log("[\(category)] \(message)")

        // ファイルにも出力
        await getDebugLogger()?.log(message, category: category)
    }

    /// RELEASE用ロガーを取得（サイズ制限付き）
    ///
    /// - Returns: DebugLoggerインスタンス
    private func getReleaseLogger() -> DebugLogger? {
        if let existing = debugLogger {
            // サイズチェックとローテーション
            Task {
                await performLogRotationIfNeeded()
            }
            return existing
        }
        let logger = DebugLogger(logFileURL: logFileURL, clearOnInitialize: false)
        self.debugLogger = logger
        return logger
    }

    /// ログローテーション（サイズ超過時）
    private func performLogRotationIfNeeded() async {
        guard let logger = debugLogger else { return }

        let currentSize = await logger.getFileSize()
        if currentSize > maxLogSize {
            // 上限超過時: 古いログから削除（先頭50%を削除）
            await logger.rotateLog(keepRatio: 0.5)
        }
    }

    // MARK: - テストヘルパー

    /// ログ内容取得
    ///
    /// - Returns: ログファイルの内容
    public func getDebugLogContents() async -> String {
        return await getDebugLogger()?.readContents() ?? ""
    }

    /// ログクリア
    public func clearDebugLog() async {
        await getDebugLogger()?.clear()
    }

    /// カテゴリ別ログ抽出（テスト用）
    ///
    /// - Parameters:
    ///   - category: ログカテゴリ（例: "FETCH", "ENGINE"）
    ///   - logContents: ログファイルの内容
    /// - Returns: 該当カテゴリのログメッセージ配列（タイムスタンプ・カテゴリタグ除去済み）
    public func extractLogs(byCategory category: String, from logContents: String) -> [String] {
        let lines = logContents.components(separatedBy: .newlines)
        var result: [String] = []

        // カテゴリパターン: [timestamp] [CATEGORY] message
        let pattern = "\\[.*?\\] \\[\(category)\\] (.*)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        for line in lines where !line.isEmpty {
            let range = NSRange(line.startIndex..., in: line)
            if let match = regex.firstMatch(in: line, range: range),
               let messageRange = Range(match.range(at: 1), in: line) {
                result.append(String(line[messageRange]))
            }
        }

        return result
    }

    /// すべてのログ行を取得（テスト用）
    ///
    /// - Parameter logContents: ログファイルの内容
    /// - Returns: すべてのログ行（タイムスタンプ・カテゴリタグ付き）
    public func extractAllLogLines(from logContents: String) -> [String] {
        return logContents
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
    }

    /// カテゴリ別ログカウント（テスト用）
    ///
    /// - Parameters:
    ///   - category: ログカテゴリ
    ///   - logContents: ログファイルの内容
    /// - Returns: 該当カテゴリのログ数
    public func countLogs(byCategory category: String, in logContents: String) -> Int {
        return extractLogs(byCategory: category, from: logContents).count
    }

    // MARK: - エクスポート

    /// Desktopにログファイルをエクスポート
    ///
    /// - Returns: エクスポート先のファイルパス（失敗時はnil）
    public func exportToDesktop() async -> URL? {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let exportURL = desktopURL.appending(path: "QuotaWatch_Log.txt")

        let contents = await getDebugLogContents()

        do {
            try contents.write(to: exportURL, atomically: true, encoding: .utf8)
            return exportURL
        } catch {
            return nil
        }
    }

    // MARK: - ユーティリティ

    /// ログファイルのパスを取得
    ///
    /// - Returns: ログファイルのパス
    public func getLogFilePath() -> String {
        return logFileURL.path
    }
}

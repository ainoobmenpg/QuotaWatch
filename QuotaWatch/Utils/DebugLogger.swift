//
//  DebugLogger.swift
//  QuotaWatch
//
//  テキストファイルに出力するデバッグロガー
//

import Foundation

/// テキストファイルに出力するデバッグロガー
///
/// ログをファイルに出力し、AIが確認できるようにします。
/// アプリケーションサポートディレクトリ内の `debug.log` にログを出力します。
public actor DebugLogger {
    /// ログファイルのパス
    private let logFileURL: URL

    /// ログフォーマット用の日付フォーマッター
    private let dateFormatter: ISO8601DateFormatter

    /// ログファイルをクリアするかどうか（初期化時）
    private let clearOnInitialize: Bool

    /// DebugLoggerを初期化
    ///
    /// - Parameters:
    ///   - logFileURL: ログファイルのパス
    ///   - clearOnInitialize: 初期化時にログをクリアするか（デフォルト: false）
    public init(logFileURL: URL, clearOnInitialize: Bool = false) {
        self.logFileURL = logFileURL
        self.clearOnInitialize = clearOnInitialize

        // 日付フォーマッターを初期化
        self.dateFormatter = ISO8601DateFormatter()
        self.dateFormatter.formatOptions = [
            .withYear, .withMonth, .withDay,
            .withTime, .withFractionalSeconds
        ]

        // ディレクトリを作成
        let directoryURL = logFileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        // 初期化時にクリアする場合は削除
        if clearOnInitialize {
            try? FileManager.default.removeItem(at: logFileURL)
        }
    }

    /// ログメッセージをファイルに出力
    ///
    /// - Parameters:
    ///   - message: ログメッセージ
    ///   - category: カテゴリ（デフォルト: "GENERAL"）
    public func log(_ message: String, category: String = "GENERAL") {
        let timestamp = dateFormatter.string(from: Date())
        let logLine = "[\(timestamp)] [\(category)] \(message)\n"

        // 既存のログに追記
        if let data = logLine.data(using: .utf8) {
            if let handle = try? FileHandle(forWritingTo: logFileURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            } else {
                // ファイルが存在しない場合は新規作成
                try? data.write(to: logFileURL)
            }
        }
    }

    /// ログファイルをクリア
    public func clear() {
        try? FileManager.default.removeItem(at: logFileURL)
    }

    /// ログファイルの内容を取得
    ///
    /// - Returns: ログファイルの内容
    public func readContents() -> String {
        if let data = try? Data(contentsOf: logFileURL),
           let contents = String(data: data, encoding: .utf8) {
            return contents
        }
        return ""
    }

    /// ログファイルのパスを取得
    ///
    /// - Returns: ログファイルのパス
    public func getLogFilePath() -> String {
        return logFileURL.path
    }

    /// ログファイルのサイズを取得
    ///
    /// - Returns: ファイルサイズ（バイト単位、ファイルが存在しない場合は0）
    public func getFileSize() -> Int {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: logFileURL.path),
              let fileSize = attributes[.size] as? Int else {
            return 0
        }
        return fileSize
    }

    /// ログローテーション（古いログを削除）
    ///
    /// - Parameter keepRatio: 保持する割合（0.0〜1.0、例: 0.5で後半50%を保持）
    public func rotateLog(keepRatio: Double) {
        let contents = readContents()
        guard !contents.isEmpty else { return }

        let lines = contents.components(separatedBy: .newlines)
        guard lines.count > 1 else { return }

        // 指定された割合で後半を保持
        let keepCount = Int(Double(lines.count) * keepRatio)
        let startIndex = max(0, lines.count - keepCount)
        let rotatedLines = lines[startIndex..<lines.count]
        let rotatedContents = rotatedLines.joined(separator: "\n")

        // 上書き保存
        if let data = rotatedContents.data(using: .utf8) {
            try? data.write(to: logFileURL)
        }
    }
}

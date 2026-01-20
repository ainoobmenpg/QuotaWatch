//
//  DebugLoggerTestHelpers.swift
//  QuotaWatchTests
//
//  DebugLogger用テストヘルパー
//

import Foundation
import XCTest
@testable import QuotaWatch

/// DebugLogger用テストヘルパー
///
/// ログ出力をベースとしたテストを支援するユーティリティメソッドを提供します。
public actor DebugLoggerTestHelpers {

    // MARK: - ファイル管理

    /// テスト用一時ログファイルを作成
    ///
    /// - Parameter testName: テスト名（ファイル名に使用）
    /// - Returns: 一時ログファイルのURL
    public static func createTempLogFile(testName: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "test_\(testName)_\(UUID().uuidString).log"
        return tempDir.appendingPathComponent(fileName)
    }

    /// テスト用一時ログファイルを削除
    ///
    /// - Parameter url: 削除するファイルのURL
    public static func removeTempLogFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - ログ解析

    /// カテゴリ別ログを抽出
    ///
    /// - Parameters:
    ///   - category: ログカテゴリ（例: "FETCH", "ENGINE"）
    ///   - logContents: ログファイルの内容
    /// - Returns: 該当カテゴリのログメッセージ配列（タイムスタンプ・カテゴリタグ除去済み）
    public static func extractLogs(byCategory category: String, from logContents: String) -> [String] {
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

    /// すべてのログ行を取得
    ///
    /// - Parameter logContents: ログファイルの内容
    /// - Returns: すべてのログ行（タイムスタンプ・カテゴリタグ付き）
    public static func extractAllLogLines(from logContents: String) -> [String] {
        return logContents
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
    }

    // MARK: - アサーション

    /// ログ包含検証
    ///
    /// 指定したカテゴリに期待するメッセージが含まれていることを検証します。
    ///
    /// - Parameters:
    ///   - logContents: ログファイルの内容
    ///   - category: ログカテゴリ
    ///   - expectedMessage: 期待するメッセージ
    public static func assertLogContains(
        _ logContents: String,
        category: String,
        expectedMessage: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let logs = extractLogs(byCategory: category, from: logContents)
        XCTAssertTrue(
            logs.contains(expectedMessage),
            "カテゴリ[\(category)]に「\(expectedMessage)」が含まれているべきですが、実際のログ: \(logs)",
            file: file,
            line: line
        )
    }

    /// ログ非包含検証
    ///
    /// 指定したカテゴリにメッセージが含まれていないことを検証します。
    ///
    /// - Parameters:
    ///   - logContents: ログファイルの内容
    ///   - category: ログカテゴリ
    ///   - unexpectedMessage: 含まれてはならないメッセージ
    public static func assertLogNotContains(
        _ logContents: String,
        category: String,
        unexpectedMessage: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let logs = extractLogs(byCategory: category, from: logContents)
        XCTAssertFalse(
            logs.contains(unexpectedMessage),
            "カテゴリ[\(category)]に「\(unexpectedMessage)」が含まれていないべきですが、含まれていました",
            file: file,
            line: line
        )
    }

    /// ログカウント検証
    ///
    /// 指定したカテゴリのログ数を検証します。
    ///
    /// - Parameters:
    ///   - logContents: ログファイルの内容
    ///   - category: ログカテゴリ
    ///   - expectedCount: 期待するログ数
    public static func assertLogCount(
        _ logContents: String,
        category: String,
        expectedCount: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let count = countLogs(byCategory: category, in: logContents)
        XCTAssertEqual(
            count,
            expectedCount,
            "カテゴリ[\(category)]のログ数は\(expectedCount)であるべきですが、実際は\(count)",
            file: file,
            line: line
        )
    }

    /// ログ順序検証
    ///
    /// 指定したカテゴリのログが期待する順序で出力されていることを検証します。
    ///
    /// - Parameters:
    ///   - logContents: ログファイルの内容
    ///   - category: ログカテゴリ
    ///   - expectedMessages: 期待するメッセージの順序
    public static func assertLogOrder(
        _ logContents: String,
        category: String,
        expectedMessages: [String],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let logs = extractLogs(byCategory: category, from: logContents)

        for (index, expected) in expectedMessages.enumerated() {
            if index < logs.count {
                XCTAssertEqual(
                    logs[index],
                    expected,
                    "カテゴリ[\(category)]の\(index + 1)番目のログは「\(expected)」であるべきですが、実際は「\(logs[index])」",
                    file: file,
                    line: line
                )
            } else {
                XCTFail(
                    "カテゴリ[\(category)]のログ数が不足しています。\(index + 1)番目のログ「\(expected)」が見つかりません",
                    file: file,
                    line: line
                )
            }
        }
    }

    // MARK: - ユーティリティ

    /// カテゴリ別ログカウント
    ///
    /// - Parameters:
    ///   - category: ログカテゴリ
    ///   - logContents: ログファイルの内容
    /// - Returns: 該当カテゴリのログ数
    public static func countLogs(byCategory category: String, in logContents: String) -> Int {
        return extractLogs(byCategory: category, from: logContents).count
    }

    /// ISO8601タイムスタンプの検証
    ///
    /// ログ内のすべてのタイムスタンプがISO8601フォーマットであることを検証します。
    ///
    /// - Parameter logContents: ログファイルの内容
    public static func assertValidISO8601Timestamps(
        in logContents: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let lines = logContents.components(separatedBy: .newlines)

        // ISO8601パターン: [2025-01-19T12:34:56.789Z]
        let timestampPattern = "\\[(\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d+Z?)\\]"
        guard let timestampRegex = try? NSRegularExpression(pattern: timestampPattern) else {
            XCTFail("タイムスタンプ正規表現の作成に失敗", file: file, line: line)
            return
        }

        // ISO8601DateFormatterでパートできるか検証
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withYear, .withMonth, .withDay,
            .withTime, .withFractionalSeconds
        ]

        var validCount = 0
        var invalidCount = 0

        for line in lines where !line.isEmpty {
            let range = NSRange(line.startIndex..., in: line)
            if let match = timestampRegex.firstMatch(in: line, range: range),
               let timestampRange = Range(match.range(at: 1), in: line) {
                let timestamp = String(line[timestampRange])
                if formatter.date(from: timestamp) != nil {
                    validCount += 1
                } else {
                    invalidCount += 1
                    XCTFail("無効なISO8601タイムスタンプ: \(timestamp)", file: file, line: line)
                }
            }
        }

        XCTAssertEqual(
            invalidCount,
            0,
            "\(validCount)個の有効なタイムスタンプ、\(invalidCount)個の無効なタイムスタンプ",
            file: file,
            line: line
        )
    }

    /// ログファイルサイズを取得
    ///
    /// - Parameter logContents: ログファイルの内容
    /// - Returns: バイト単位のサイズ
    public static func getLogSize(_ logContents: String) -> Int {
        return logContents.data(using: .utf8)?.count ?? 0
    }

    /// ログが空であることを検証
    ///
    /// - Parameter logContents: ログファイルの内容
    public static func assertLogEmpty(
        _ logContents: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let trimmed = logContents.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertTrue(
            trimmed.isEmpty,
            "ログが空であるべきですが、内容: \(trimmed)",
            file: file,
            line: line
        )
    }

    /// ログが空でないことを検証
    ///
    /// - Parameter logContents: ログファイルの内容
    public static func assertLogNotEmpty(
        _ logContents: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let trimmed = logContents.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertFalse(
            trimmed.isEmpty,
            "ログに内容が含まれているべきですが、空です",
            file: file,
            line: line
        )
    }
}

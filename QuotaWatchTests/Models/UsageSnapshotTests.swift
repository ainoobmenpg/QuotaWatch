//
//  UsageSnapshotTests.swift
//  QuotaWatchTests
//
//  UsageSnapshot/UsageLimitモデルおよびZ.ai生レスポンスモデルの単体テスト
//

import XCTest
@testable import QuotaWatch

final class UsageSnapshotTests: XCTestCase {

    // MARK: - UsageSnapshot Codable Tests

    func testUsageSnapshotEncodingDecoding() throws {
        let snapshot = UsageSnapshot(
            providerId: "zai",
            fetchedAtEpoch: 1737100800,
            primaryTitle: "Tokens",
            primaryPct: 42,
            primaryUsed: 4230.0,
            primaryTotal: 10000.0,
            primaryRemaining: 5770.0,
            resetEpoch: 1737118800,
            secondary: [
                UsageLimit(
                    label: "Time Limit",
                    pct: 24,
                    used: 1200.0,
                    total: 5000.0,
                    remaining: 3800.0,
                    resetEpoch: 1738310400
                )
            ],
            rawDebugJson: "{\"test\": true}"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(snapshot)
        let decoded = try decoder.decode(UsageSnapshot.self, from: data)

        XCTAssertEqual(decoded.providerId, "zai")
        XCTAssertEqual(decoded.fetchedAtEpoch, 1737100800)
        XCTAssertEqual(decoded.primaryTitle, "Tokens")
        XCTAssertEqual(decoded.primaryPct, 42)
        XCTAssertEqual(decoded.primaryUsed, 4230.0)
        XCTAssertEqual(decoded.primaryTotal, 10000.0)
        XCTAssertEqual(decoded.primaryRemaining, 5770.0)
        XCTAssertEqual(decoded.resetEpoch, 1737118800)
        XCTAssertEqual(decoded.secondary.count, 1)
        XCTAssertEqual(decoded.secondary[0].label, "Time Limit")
        XCTAssertEqual(decoded.rawDebugJson, "{\"test\": true}")
    }

    func testUsageSnapshotEquatable() {
        let snapshot1 = UsageSnapshot(
            providerId: "zai",
            fetchedAtEpoch: 1737100800,
            primaryTitle: "Tokens",
            primaryPct: 42,
            primaryUsed: 4230.0,
            primaryTotal: 10000.0,
            primaryRemaining: 5770.0,
            resetEpoch: 1737118800,
            secondary: [],
            rawDebugJson: nil
        )

        let snapshot2 = UsageSnapshot(
            providerId: "zai",
            fetchedAtEpoch: 1737100800,
            primaryTitle: "Tokens",
            primaryPct: 42,
            primaryUsed: 4230.0,
            primaryTotal: 10000.0,
            primaryRemaining: 5770.0,
            resetEpoch: 1737118800,
            secondary: [],
            rawDebugJson: nil
        )

        XCTAssertEqual(snapshot1, snapshot2)
    }

    // MARK: - UsageLimit Codable Tests

    func testUsageLimitEncodingDecoding() throws {
        let limit = UsageLimit(
            label: "Search (Monthly)",
            pct: 12,
            used: 12.0,
            total: 100.0,
            remaining: 88.0,
            resetEpoch: 1738310400
        )

        let data = try JSONEncoder().encode(limit)
        let decoded = try decoder.decode(UsageLimit.self, from: data)

        XCTAssertEqual(decoded.label, "Search (Monthly)")
        XCTAssertEqual(decoded.pct, 12)
        XCTAssertEqual(decoded.used, 12.0)
        XCTAssertEqual(decoded.total, 100.0)
        XCTAssertEqual(decoded.remaining, 88.0)
        XCTAssertEqual(decoded.resetEpoch, 1738310400)
    }

    func testUsageLimitWithNilValues() throws {
        let limit = UsageLimit(
            label: "Unknown Limit",
            pct: nil,
            used: nil,
            total: nil,
            remaining: nil,
            resetEpoch: nil
        )

        let data = try JSONEncoder().encode(limit)
        let decoded = try decoder.decode(UsageLimit.self, from: data)

        XCTAssertEqual(decoded.label, "Unknown Limit")
        XCTAssertNil(decoded.pct)
        XCTAssertNil(decoded.used)
        XCTAssertNil(decoded.total)
        XCTAssertNil(decoded.remaining)
        XCTAssertNil(decoded.resetEpoch)
    }

    // MARK: - QuotaResponse Parsing Tests

    func testQuotaResponseParsing() throws {
        // api_sample.json ベースのテストデータ
        let jsonString = """
        {
          "code": 0,
          "data": {
            "limits": [
              {
                "type": "TOKENS_LIMIT",
                "percentage": 42.3,
                "usage": 4230,
                "number": 10000,
                "remaining": 5770,
                "nextResetTime": 1737100800
              },
              {
                "type": "TIME_LIMIT",
                "usage": 1200,
                "number": 5000,
                "remaining": 3800,
                "nextResetTime": "2026-02-01T00:00:00Z"
              }
            ]
          }
        }
        """

        let data = jsonString.data(using: .utf8)!
        let response = try decoder.decode(QuotaResponse.self, from: data)

        XCTAssertEqual(response.code, 0)
        XCTAssertNotNil(response.data)
        XCTAssertNil(response.error)

        let limits = response.data?.limits
        XCTAssertEqual(limits?.count, 2)

        // 最初の制限（TOKENS_LIMIT）
        let firstLimit = limits?[0]
        XCTAssertEqual(firstLimit?.type, "TOKENS_LIMIT")
        XCTAssertEqual(firstLimit?.percentage, 42.3)
        XCTAssertEqual(firstLimit?.usage, 4230.0)
        XCTAssertEqual(firstLimit?.number, 10000.0)
        XCTAssertEqual(firstLimit?.remaining, 5770.0)

        // 2番目の制限（TIME_LIMIT）
        let secondLimit = limits?[1]
        XCTAssertEqual(secondLimit?.type, "TIME_LIMIT")
        XCTAssertNil(secondLimit?.percentage)
        XCTAssertEqual(secondLimit?.usage, 1200.0)
        XCTAssertEqual(secondLimit?.number, 5000.0)
        XCTAssertEqual(secondLimit?.remaining, 3800.0)
    }

    func testQuotaResponseWithError() throws {
        let jsonString = """
        {
          "code": 1302,
          "error": {
            "code": 1302,
            "message": "Rate limit exceeded"
          }
        }
        """

        let data = jsonString.data(using: .utf8)!
        let response = try decoder.decode(QuotaResponse.self, from: data)

        XCTAssertEqual(response.code, 1302)
        XCTAssertNil(response.data)
        XCTAssertNotNil(response.error)
        XCTAssertEqual(response.error?.code, 1302)
        XCTAssertEqual(response.error?.message, "Rate limit exceeded")
    }

    // MARK: - ResetTimeValue Normalization Tests

    func testResetTimeValueSeconds() throws {
        // epoch秒でデコード
        let json1 = """
        {"nextResetTime": 1737100800}
        """
        let data1 = json1.data(using: .utf8)!
        let container1 = try decoder.decode(ResetTimeContainer.self, from: data1)

        if case .seconds(let value) = container1.nextResetTime {
            XCTAssertEqual(value, 1737100800)
            XCTAssertEqual(normalizeResetTime(container1.nextResetTime), 1737100800)
        } else {
            XCTFail("Expected .seconds case")
        }
    }

    func testResetTimeValueMilliseconds() throws {
        // epochミリ秒でデコード（13桁）
        let json1 = """
        {"nextResetTime": 1737100800000}
        """
        let data1 = json1.data(using: .utf8)!
        let container1 = try decoder.decode(ResetTimeContainer.self, from: data1)

        if case .milliseconds(let value) = container1.nextResetTime {
            XCTAssertEqual(value, 1737100800000)
            XCTAssertEqual(normalizeResetTime(container1.nextResetTime), 1737100800)
        } else {
            XCTFail("Expected .milliseconds case")
        }
    }

    func testResetTimeValueISO8601() throws {
        // ISO8601文字列でデコード
        let json1 = """
        {"nextResetTime": "2026-02-01T00:00:00Z"}
        """
        let data1 = json1.data(using: .utf8)!
        let container1 = try decoder.decode(ResetTimeContainer.self, from: data1)

        if case .iso8601(let value) = container1.nextResetTime {
            XCTAssertEqual(value, "2026-02-01T00:00:00Z")
            // 2026-02-01 00:00:00 UTC = 1769904000 (epoch秒)
            let normalized = normalizeResetTime(container1.nextResetTime)
            XCTAssertEqual(normalized, 1769904000)
        } else {
            XCTFail("Expected .iso8601 case")
        }
    }

    func testResetTimeValueEquatable() {
        XCTAssertEqual(ResetTimeValue.seconds(1737100800), ResetTimeValue.seconds(1737100800))
        XCTAssertEqual(ResetTimeValue.milliseconds(1737100800000), ResetTimeValue.milliseconds(1737100800000))
        XCTAssertEqual(ResetTimeValue.iso8601("2026-02-01T00:00:00Z"), ResetTimeValue.iso8601("2026-02-01T00:00:00Z"))

        XCTAssertNotEqual(ResetTimeValue.seconds(1737100800), ResetTimeValue.seconds(123))
        XCTAssertNotEqual(ResetTimeValue.seconds(1737100800), ResetTimeValue.milliseconds(1737100800000))
    }

    // MARK: - Percentage Calculation Tests

    func testCalculatePercentageWithPercentageField() {
        // percentageフィールドがある場合はそれを優先
        let result = calculatePercentage(percentage: 42.3, usage: 5000, total: 10000)
        XCTAssertEqual(result, 42)
    }

    func testCalculatePercentageWithoutPercentageField() {
        // percentageフィールドがない場合は計算
        let result = calculatePercentage(percentage: nil, usage: 4230, total: 10000)
        XCTAssertEqual(result, 42)  // floor(100 * 4230 / 10000) = 42
    }

    func testCalculatePercentageEdgeCases() {
        // ゼロ除算の回避
        XCTAssertEqual(calculatePercentage(percentage: nil, usage: 100, total: 0), 0)
        XCTAssertEqual(calculatePercentage(percentage: nil, usage: 0, total: 100), 0)
        XCTAssertEqual(calculatePercentage(percentage: nil, usage: 100, total: 100), 100)

        // 小数点以下の切り捨て
        XCTAssertEqual(calculatePercentage(percentage: 99.9, usage: 0, total: 1), 99)
        XCTAssertEqual(calculatePercentage(percentage: nil, usage: 9999, total: 10000), 99)
    }

    // MARK: - ErrorResponse Tests

    func testErrorResponseEncodingDecoding() throws {
        let error = ErrorResponse(code: 1302, message: "Rate limit exceeded")

        let data = try JSONEncoder().encode(error)
        let decoded = try decoder.decode(ErrorResponse.self, from: data)

        XCTAssertEqual(decoded.code, 1302)
        XCTAssertEqual(decoded.message, "Rate limit exceeded")
    }

    func testErrorResponseWithNilCode() throws {
        let error = ErrorResponse(code: nil, message: "Unknown error")

        let data = try JSONEncoder().encode(error)
        let decoded = try decoder.decode(ErrorResponse.self, from: data)

        XCTAssertNil(decoded.code)
        XCTAssertEqual(decoded.message, "Unknown error")
    }

    // MARK: - Sendable Conformance

    func testSendableConformance() {
        // Swift 6 concurrency: 全てのモデルがSendableに準拠している必要がある
        let snapshot = UsageSnapshot(
            providerId: "zai",
            fetchedAtEpoch: 1737100800,
            primaryTitle: "Tokens",
            primaryPct: 42,
            primaryUsed: 4230.0,
            primaryTotal: 10000.0,
            primaryRemaining: 5770.0,
            resetEpoch: 1737118800,
            secondary: [],
            rawDebugJson: nil
        )

        // Sendable準拠の確認（コンパイルが通ればOK）
        let _: @Sendable () -> UsageSnapshot = { snapshot }
        let _: @Sendable () -> UsageLimit = { UsageLimit(label: "Test", pct: nil, used: nil, total: nil, remaining: nil, resetEpoch: nil) }
        let _: @Sendable () -> QuotaLimit = {
            QuotaLimit(type: "TEST", percentage: nil, usage: 0, number: 100, remaining: 100, nextResetTime: .seconds(0))
        }
    }

    // MARK: - 正規化ロジックテスト

    func testUsageSnapshotNormalizationFromQuotaData() throws {
        // api_sample.json ベースのテストデータ
        let quotaData = QuotaData(limits: [
            QuotaLimit(
                type: "TOKENS_LIMIT",
                percentage: 42.3,
                usage: 4230,
                number: 10000,
                remaining: 5770,
                nextResetTime: .seconds(1737118800)
            ),
            QuotaLimit(
                type: "TIME_LIMIT",
                percentage: nil,
                usage: 1200,
                number: 5000,
                remaining: 3800,
                nextResetTime: .iso8601("2026-02-01T00:00:00Z")
            ),
        ])

        let snapshot = UsageSnapshot(from: quotaData)

        XCTAssertNotNil(snapshot)
        XCTAssertEqual(snapshot?.providerId, "zai")
        XCTAssertEqual(snapshot?.primaryTitle, "Tokens")
        XCTAssertEqual(snapshot?.primaryPct, 42)
        XCTAssertEqual(snapshot?.primaryUsed, 4230.0)
        XCTAssertEqual(snapshot?.primaryTotal, 10000.0)
        XCTAssertEqual(snapshot?.primaryRemaining, 5770.0)
        XCTAssertEqual(snapshot?.resetEpoch, 1737118800)
        XCTAssertEqual(snapshot?.secondary.count, 1)
        XCTAssertEqual(snapshot?.secondary[0].label, "Time Limit")
        XCTAssertEqual(snapshot?.secondary[0].pct, 24)  // 計算: floor(100 * 1200 / 5000) = 24
        XCTAssertEqual(snapshot?.secondary[0].used, 1200.0)
        XCTAssertEqual(snapshot?.secondary[0].total, 5000.0)
        XCTAssertEqual(snapshot?.secondary[0].remaining, 3800.0)
        // 2026-02-01 00:00:00 UTC = 1769904000 (epoch秒)
        XCTAssertEqual(snapshot?.secondary[0].resetEpoch, 1769904000)
        XCTAssertNil(snapshot?.rawDebugJson)
    }

    func testUsageSnapshotNormalizationWithoutPrimary() {
        // プライマリクォータ（TOKENS_LIMIT）がない場合
        let quotaData = QuotaData(limits: [
            QuotaLimit(
                type: "WEB_SEARCH_MONTHLY",
                percentage: nil,
                usage: 12,
                number: 100,
                remaining: 88,
                nextResetTime: .iso8601("2026-02-01T00:00:00Z")
            ),
        ])

        let snapshot = UsageSnapshot(from: quotaData)

        XCTAssertNil(snapshot, "プライマリクォータがない場合はnilを返す")
    }

    func testUsageSnapshotNormalizationWithoutPercentageField() throws {
        // percentageフィールドがない場合の計算テスト
        let quotaData = QuotaData(limits: [
            QuotaLimit(
                type: "TOKENS_LIMIT",
                percentage: nil,  // percentageなし
                usage: 4230,
                number: 10000,
                remaining: 5770,
                nextResetTime: .seconds(1737118800)
            ),
        ])

        let snapshot = UsageSnapshot(from: quotaData)

        XCTAssertNotNil(snapshot)
        // 計算: floor(100 * 4230 / 10000) = 42
        XCTAssertEqual(snapshot?.primaryPct, 42)
    }

    func testUsageSnapshotNormalizationWithMultipleSecondaries() throws {
        // 複数セカンダリ枠のテスト
        let quotaData = QuotaData(limits: [
            QuotaLimit(
                type: "TOKENS_LIMIT",
                percentage: 42.3,
                usage: 4230,
                number: 10000,
                remaining: 5770,
                nextResetTime: .seconds(1737118800)
            ),
            QuotaLimit(
                type: "TIME_LIMIT",
                percentage: nil,
                usage: 1200,
                number: 5000,
                remaining: 3800,
                nextResetTime: .iso8601("2026-02-01T00:00:00Z")
            ),
            QuotaLimit(
                type: "WEB_SEARCH_MONTHLY",
                percentage: 5.0,
                usage: 5,
                number: 100,
                remaining: 95,
                nextResetTime: .milliseconds(1769904000000)
            ),
            QuotaLimit(
                type: "READER_MONTHLY",
                percentage: nil,
                usage: 0,
                number: 50,
                remaining: 50,
                nextResetTime: .seconds(1769904000)
            ),
        ])

        let snapshot = UsageSnapshot(from: quotaData)

        XCTAssertNotNil(snapshot)
        XCTAssertEqual(snapshot?.secondary.count, 3)
        XCTAssertEqual(snapshot?.secondary[0].label, "Time Limit")
        XCTAssertEqual(snapshot?.secondary[1].label, "Search (Monthly)")
        XCTAssertEqual(snapshot?.secondary[2].label, "Reader (Monthly)")
    }

    func testUsageSnapshotNormalizationWithDebugJson() throws {
        // デバッグJSONオプションのテスト
        let quotaData = QuotaData(limits: [
            QuotaLimit(
                type: "TOKENS_LIMIT",
                percentage: 42.3,
                usage: 4230,
                number: 10000,
                remaining: 5770,
                nextResetTime: .seconds(1737118800)
            ),
        ])

        // デバッグJSONあり
        let snapshotWithDebug = UsageSnapshot(from: quotaData, includeDebugJson: true)
        XCTAssertNotNil(snapshotWithDebug)
        XCTAssertNotNil(snapshotWithDebug?.rawDebugJson)

        // デバッグJSONなし（デフォルト）
        let snapshotWithoutDebug = UsageSnapshot(from: quotaData, includeDebugJson: false)
        XCTAssertNotNil(snapshotWithoutDebug)
        XCTAssertNil(snapshotWithoutDebug?.rawDebugJson)
    }

    // MARK: - Helper Types

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        return decoder
    }

    // ResetTimeValueのデコードテスト用ヘルパー構造体
    private struct ResetTimeContainer: Codable {
        let nextResetTime: ResetTimeValue
    }
}

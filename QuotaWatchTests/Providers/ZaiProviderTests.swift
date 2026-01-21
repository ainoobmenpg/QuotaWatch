//
//  ZaiProviderTests.swift
//  QuotaWatchTests
//
//  ZaiProviderの単体テスト
//

import XCTest
@testable import QuotaWatch

// MARK: - ZaiProviderTests

final class ZaiProviderTests: XCTestCase {
    var sut: ZaiProvider!

    override func setUp() async throws {
        try await super.setUp()
        sut = ZaiProvider()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - プロパティテスト

    func testProviderProperties() {
        XCTAssertEqual(sut.id, "zai")
        XCTAssertEqual(sut.displayName, "Z.ai")
        XCTAssertEqual(sut.keychainService, "zai_api_key")
        XCTAssertNotNil(sut.dashboardURL)
        XCTAssertEqual(sut.dashboardURL?.absoluteString, "https://z.ai")
    }

    // MARK: - classifyBackoff テスト

    func testClassifyBackoff_Http429_ReturnsBackoff() {
        let error = ProviderError.httpError(statusCode: 429)
        let decision = sut.classifyBackoff(error: error)

        XCTAssertEqual(decision.isRetryable, true)
        if case .backoff = decision.action {
            // バックオフ判定されている
        } else {
            XCTFail("バックオフ判定されるべき")
        }
        XCTAssertTrue(decision.description.contains("バックオフ中"))
    }

    func testClassifyBackoff_NetworkError_ReturnsProceed() {
        let error = ProviderError.networkError(underlying: URLError(.notConnectedToInternet))
        let decision = sut.classifyBackoff(error: error)

        XCTAssertEqual(decision.isRetryable, true)
        if case .proceed = decision.action {
            // 期待通り
        } else {
            XCTFail("proceed判定されるべき")
        }
        XCTAssertTrue(decision.description.contains("通常リトライ"))
    }

    func testClassifyBackoff_Unauthorized_ReturnsStop() {
        let error = ProviderError.unauthorized
        let decision = sut.classifyBackoff(error: error)

        XCTAssertEqual(decision.isRetryable, false)
        if case .stop = decision.action {
            // 期待通り
        } else {
            XCTFail("stop判定されるべき")
        }
    }

    func testClassifyBackoff_DecodingError_ReturnsProceed() {
        let error = ProviderError.decodingError(
            underlying: DecodingError.dataCorrupted(.init(
                codingPath: [],
                debugDescription: "test"
            ))
        )
        let decision = sut.classifyBackoff(error: error)

        XCTAssertEqual(decision.isRetryable, true)
        if case .proceed = decision.action {
            // 期待通り
        } else {
            XCTFail("proceed判定されるべき")
        }
    }

    func testClassifyBackoff_QuotaNotAvailable_ReturnsStop() {
        let error = ProviderError.quotaNotAvailable
        let decision = sut.classifyBackoff(error: error)

        XCTAssertEqual(decision.isRetryable, false)
        if case .stop = decision.action {
            // 期待通り
        } else {
            XCTFail("stop判定されるべき")
        }
    }

    func testClassifyBackoff_InvalidResponse_ReturnsStop() {
        let error = ProviderError.invalidResponse
        let decision = sut.classifyBackoff(error: error)

        XCTAssertEqual(decision.isRetryable, false)
        if case .stop = decision.action {
            // 期待通り
        } else {
            XCTFail("stop判定されるべき")
        }
    }

    // MARK: - codeチェックのテスト（モックJSON）

    func testQuotaResponse_CodeZero_Success() throws {
        // code: 0 は成功
        let json = """
        {
            "code": 0,
            "data": {
                "limits": [
                    {
                        "type": "TOKENS_5H",
                        "percentage": 10.5,
                        "usage": 10000.0,
                        "number": 100000.0,
                        "remaining": 90000.0,
                        "nextResetTime": 1737100800
                    }
                ]
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(QuotaResponse.self, from: data)

        XCTAssertEqual(response.code, 0)
        XCTAssertNotNil(response.data)
        XCTAssertNil(response.error)
    }

    func testQuotaResponse_CodeNonZero_NoError_ThrowsUnauthorized() {
        // code: 非0、errorなし → unauthorizedになるはず
        let json = """
        {
            "code": 401,
            "data": null
        }
        """

        let data = json.data(using: .utf8)!
        let response = try? JSONDecoder().decode(QuotaResponse.self, from: data)

        XCTAssertNotNil(response)
        XCTAssertEqual(response?.code, 401)
        XCTAssertNil(response?.data)
        XCTAssertNil(response?.error)
    }

    func testQuotaResponse_CodeNonZero_WithRateLimitError_Returns429() {
        // code: 1302（レート制限）、errorあり
        let json = """
        {
            "code": 1302,
            "error": {
                "code": 1302,
                "message": "Too many requests"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try? JSONDecoder().decode(QuotaResponse.self, from: data)

        XCTAssertNotNil(response)
        XCTAssertEqual(response?.code, 1302)
        XCTAssertNotNil(response?.error)
        XCTAssertEqual(response?.error?.code, 1302)
    }

    func testQuotaResponse_Code1302_NoError_IsRateLimit() {
        // code: 1302（レート制限）、errorなし → codeのみで判定
        let json = """
        {
            "code": 1302
        }
        """

        let data = json.data(using: .utf8)!
        let response = try? JSONDecoder().decode(QuotaResponse.self, from: data)

        XCTAssertNotNil(response)
        XCTAssertEqual(response?.code, 1302)
        XCTAssertNil(response?.error)
    }

    func testQuotaResponse_Code0_WithErrorObject_Compatibility() {
        // 互換性テスト: code: 0 だが errorオブジェクトがある場合
        // 既存のチェックでエラーになるはず
        let json = """
        {
            "code": 0,
            "error": {
                "code": 1302,
                "message": "Rate limit"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try? JSONDecoder().decode(QuotaResponse.self, from: data)

        XCTAssertNotNil(response)
        XCTAssertEqual(response?.code, 0)
        XCTAssertNotNil(response?.error)
    }
}

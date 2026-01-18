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
        if case .backoff(let wait) = decision.action {
            // バックオフ待機時間が設定されている
            XCTAssertGreaterThan(wait, 0)
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
}

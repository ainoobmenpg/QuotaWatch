import XCTest
@testable import QuotaWatch

final class KeychainStoreTests: XCTestCase {
    var sut: KeychainStore!
    let testAccount = "test_user_keychain_tests"

    override func setUp() async throws {
        try await super.setUp()
        sut = KeychainStore(account: testAccount)
        try? await sut.delete()
    }

    override func tearDown() async throws {
        try? await sut.delete()
        sut = nil
        try await super.tearDown()
    }

    // MARK: - テストケース

    func testWriteAndRead() async throws {
        let testKey = "test-api-key-12345"
        try await sut.write(apiKey: testKey)
        let retrieved = try await sut.read()
        XCTAssertEqual(retrieved, testKey)
    }

    func testReadWhenNotExists() async {
        do {
            _ = try await sut.read()
            XCTFail("itemNotFoundエラーが発生すべき")
        } catch KeychainError.itemNotFound {
            // 期待通り
        } catch {
            XCTFail("予期しないエラー: \(error)")
        }
    }

    func testDelete() async throws {
        try await sut.write(apiKey: "test-key")
        let existsBefore = try await sut.exists()
        XCTAssertTrue(existsBefore)
        try await sut.delete()
        let existsAfter = try await sut.exists()
        XCTAssertFalse(existsAfter)
    }

    func testDeleteWhenNotExists() async {
        do {
            try await sut.delete()
            XCTFail("itemNotFoundエラーが発生すべき")
        } catch KeychainError.itemNotFound {
            // 期待通り
        } catch {
            XCTFail("予期しないエラー: \(error)")
        }
    }

    func testExistsReturnsTrueWhenPresent() async throws {
        try await sut.write(apiKey: "test-key")
        let exists = try await sut.exists()
        XCTAssertTrue(exists)
    }

    func testExistsReturnsFalseWhenNotPresent() async throws {
        let exists = try await sut.exists()
        XCTAssertFalse(exists)
    }

    func testUpdateExistingKey() async throws {
        try await sut.write(apiKey: "key1")
        try await sut.write(apiKey: "key2")
        let retrieved = try await sut.read()
        XCTAssertEqual(retrieved, "key2")
    }

    func testEmptyStringKey() async throws {
        try await sut.write(apiKey: "")
        let retrieved = try await sut.read()
        XCTAssertEqual(retrieved, "")
    }

    func testLongApiKey() async throws {
        let longKey = String(repeating: "a", count: 1000)
        try await sut.write(apiKey: longKey)
        let retrieved = try await sut.read()
        XCTAssertEqual(retrieved, longKey)
    }

    func testSpecialCharactersInKey() async throws {
        let specialKey = "test-key-日本語-🔑-uuid-12345"
        try await sut.write(apiKey: specialKey)
        let retrieved = try await sut.read()
        XCTAssertEqual(retrieved, specialKey)
    }
}

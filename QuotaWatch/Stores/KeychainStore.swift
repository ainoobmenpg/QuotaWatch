import Foundation
import OSLog

// MARK: - KeychainError

public enum KeychainError: Error, Sendable, LocalizedError {
    case itemNotFound
    case accessDenied
    case generalError(status: OSStatus)

    public var errorDescription: String? {
        switch self {
        case .itemNotFound: return "Keychainアイテムが見つかりません"
        case .accessDenied: return "Keychainへのアクセスが拒否されました"
        case .generalError(let status): return "Keychainエラー (ステータス: \(status))"
        }
    }
}

// MARK: - KeychainStore

public actor KeychainStore {
    private static let service = "zai_api_key"
    private let account: String
    private let logger = Logger(subsystem: "com.quotawatch.keychain", category: "KeychainStore")

    /// Keychain Access Group
    /// 開発中でも安定したアクセスを実現するために使用
    private var accessGroup: String {
        // AppIdentifierPrefixとBundle Identifierを結合
        // 例: ABC12345.com.quotawatch.QuotaWatch
        if let prefix = Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as? String {
            return "\(prefix)com.quotawatch.QuotaWatch"
        }
        // フォールバック: Bundle Identifierをそのまま使用
        return Bundle.main.bundleIdentifier ?? "com.quotawatch.QuotaWatch"
    }

    public init(account: String? = nil) {
        self.account = account ?? NSUserName()
        logger.log("KeychainStore初期化: service=\(Self.service), account=\(self.account)")
    }

    public func read() async throws -> String? {
        logger.debug("APIキー読み取り開始")
        let query = createQuery(returnData: true)
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let apiKey = String(data: data, encoding: .utf8) else {
                logger.error("Keychainデータのデコードに失敗")
                throw KeychainError.generalError(status: errSecDecode)
            }
            logger.debug("APIキー読み取り成功（長さ: \(apiKey.count)）")
            return apiKey
        case errSecItemNotFound:
            logger.debug("APIキーが見つかりません")
            throw KeychainError.itemNotFound
        case errSecAuthFailed:
            logger.error("Keychainアクセス拒否: \(status)")
            throw KeychainError.accessDenied
        default:
            logger.error("Keychain読み取りエラー: \(status)")
            throw KeychainError.generalError(status: status)
        }
    }

    public func write(apiKey: String) async throws {
        logger.debug("APIキー保存開始（長さ: \(apiKey.count)）")
        let exists = try await exists()

        if exists {
            let query = createQuery()
            let attributes: [String: Any] = [
                kSecValueData as String: apiKey.data(using: .utf8)!
            ]
            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            if status == errSecSuccess {
                logger.log("APIキー更新成功")
            } else {
                logger.error("APIキー更新失敗: \(status)")
                throw KeychainError.generalError(status: status)
            }
        } else {
            var query = createQuery()
            query[kSecValueData as String] = apiKey.data(using: .utf8)!
            // アクセシビリティ: デバイス起動後の初回アンロック以降はアクセス可能
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            let status = SecItemAdd(query as CFDictionary, nil)
            if status == errSecSuccess {
                logger.log("APIキー保存成功")
            } else {
                logger.error("APIキー保存失敗: \(status)")
                throw KeychainError.generalError(status: status)
            }
        }
    }

    public func delete() async throws {
        logger.debug("APIキー削除開始")
        let query = createQuery()
        let status = SecItemDelete(query as CFDictionary)

        switch status {
        case errSecSuccess:
            logger.log("APIキー削除成功")
        case errSecItemNotFound:
            logger.debug("削除対象のAPIキーが見つかりません")
            throw KeychainError.itemNotFound
        default:
            logger.error("APIキー削除失敗: \(status)")
            throw KeychainError.generalError(status: status)
        }
    }

    public func exists() async throws -> Bool {
        let query = createQuery(returnData: false)
        let status = SecItemCopyMatching(query as CFDictionary, nil)

        switch status {
        case errSecSuccess: return true
        case errSecItemNotFound: return false
        case errSecAuthFailed:
            logger.error("Keychainアクセス拒否: \(status)")
            throw KeychainError.accessDenied
        default:
            logger.error("Keychain存在確認エラー: \(status)")
            throw KeychainError.generalError(status: status)
        }
    }

    private func createQuery(returnData: Bool = false) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup
        ]
        if returnData {
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne
        }
        return query
    }
}

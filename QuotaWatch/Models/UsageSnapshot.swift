//
//  UsageSnapshot.swift
//  QuotaWatch
//
//  UI/通知が参照する正規化済みデータモデルとZ.ai生レスポンスモデル
//

import Foundation

// MARK: - 正規化モデル

/// UI/通知が参照する唯一のモデル
///
/// Provider固有のレスポンス構造から正規化され、UIコンポーネントはこのモデルのみを参照します。
public struct UsageSnapshot: Codable, Equatable, Sendable {
    /// プロバイダ識別子（例: "zai"）
    public let providerId: String

    /// 取得時刻（epoch秒）
    public let fetchedAtEpoch: Int

    /// プライマリクォータのタイトル（例: "GLM 5h"）
    public let primaryTitle: String

    /// プライマリクォータの使用率（0-100）、nil可
    public let primaryPct: Int?

    /// プライマリクォータの使用量
    public let primaryUsed: Double?

    /// プライマリクォータの上限
    public let primaryTotal: Double?

    /// プライマリクォータの残り
    public let primaryRemaining: Double?

    /// 次回リセットのepoch秒
    public let resetEpoch: Int?

    /// セカンダリクォータ（月次枠等）
    public let secondary: [UsageLimit]

    /// デバッグ用生JSON文字列（任意）
    public let rawDebugJson: String?

    public init(
        providerId: String,
        fetchedAtEpoch: Int,
        primaryTitle: String,
        primaryPct: Int?,
        primaryUsed: Double?,
        primaryTotal: Double?,
        primaryRemaining: Double?,
        resetEpoch: Int?,
        secondary: [UsageLimit],
        rawDebugJson: String? = nil
    ) {
        self.providerId = providerId
        self.fetchedAtEpoch = fetchedAtEpoch
        self.primaryTitle = primaryTitle
        self.primaryPct = primaryPct
        self.primaryUsed = primaryUsed
        self.primaryTotal = primaryTotal
        self.primaryRemaining = primaryRemaining
        self.resetEpoch = resetEpoch
        self.secondary = secondary
        self.rawDebugJson = rawDebugJson
    }
}

/// セカンダリクォータ制限
public struct UsageLimit: Codable, Equatable, Sendable, Identifiable {
    /// 一意識別子（Codableには含まれない）
    public let id = UUID()

    /// ラベル（例: "Search (Monthly)"）
    public let label: String

    /// 使用率（0-100）、nil可
    public let pct: Int?

    /// 使用量
    public let used: Double?

    /// 上限
    public let total: Double?

    /// 残り
    public let remaining: Double?

    /// リセット時刻（epoch秒）
    public let resetEpoch: Int?

    public init(
        label: String,
        pct: Int?,
        used: Double?,
        total: Double?,
        remaining: Double?,
        resetEpoch: Int?
    ) {
        self.label = label
        self.pct = pct
        self.used = used
        self.total = total
        self.remaining = remaining
        self.resetEpoch = resetEpoch
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case label, pct, used, total, remaining, resetEpoch
    }
}

// MARK: - Z.ai 生レスポンスモデル

/// Z.ai APIレスポンスのルート構造
public struct QuotaResponse: Codable, Sendable {
    /// ステータスコード（0: 成功）
    public let code: Int

    /// レスポンスデータ（成功時）
    public let data: QuotaData?

    /// エラー情報（失敗時）
    public let error: ErrorResponse?

    public init(code: Int, data: QuotaData?, error: ErrorResponse?) {
        self.code = code
        self.data = data
        self.error = error
    }

    // Codableカスタム実装：dataとerrorの排他性を考慮
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(Int.self, forKey: .code)
        data = try container.decodeIfPresent(QuotaData.self, forKey: .data)
        error = try container.decodeIfPresent(ErrorResponse.self, forKey: .error)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(error, forKey: .error)
    }

    private enum CodingKeys: String, CodingKey {
        case code, data, error
    }
}

/// Z.ai APIレスポンスのデータ部分
public struct QuotaData: Codable, Sendable {
    /// クォータ制限の配列
    public let limits: [QuotaLimit]

    public init(limits: [QuotaLimit]) {
        self.limits = limits
    }
}

/// クォータ制限の詳細
public struct QuotaLimit: Codable, Sendable {
    /// 制限タイプ（例: "TOKENS_5H", "WEB_SEARCH_MONTHLY"）
    public let type: String

    /// 使用率（%）、APIによっては返されない場合あり
    public let percentage: Double?

    /// 使用量
    public let usage: Double

    /// 上限
    public let number: Double

    /// 残り
    public let remaining: Double

    /// 次回リセット時刻（epoch秒/ミリ秒 or ISO8601文字列）
    public let nextResetTime: ResetTimeValue

    public init(
        type: String,
        percentage: Double?,
        usage: Double,
        number: Double,
        remaining: Double,
        nextResetTime: ResetTimeValue
    ) {
        self.type = type
        self.percentage = percentage
        self.usage = usage
        self.number = number
        self.remaining = remaining
        self.nextResetTime = nextResetTime
    }
}

/// リセット時刻の値（多様なフォーマットに対応）
public enum ResetTimeValue: Codable, Sendable, Equatable {
    /// epoch秒（例: 1737100800）
    case seconds(Int)

    /// epochミリ秒
    case milliseconds(Int)

    /// ISO8601文字列（例: "2026-02-01T00:00:00Z"）
    case iso8601(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // 整数の場合
        if let intValue = try? container.decode(Int.self) {
            // 13桁以上ならミリ秒とみなす（2026年以降のタイムスタンプは13桁）
            if intValue >= 1_000_000_000_000 {
                self = .milliseconds(intValue)
            } else {
                self = .seconds(intValue)
            }
            return
        }

        // 文字列の場合
        if let stringValue = try? container.decode(String.self) {
            self = .iso8601(stringValue)
            return
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "ResetTimeValueは整数または文字列である必要があります"
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .seconds(let value):
            try container.encode(value)
        case .milliseconds(let value):
            try container.encode(value)
        case .iso8601(let value):
            try container.encode(value)
        }
    }
}

/// エラーレスポンス
public struct ErrorResponse: Codable, Sendable, Equatable {
    /// エラーコード
    public let code: Int?

    /// エラーメッセージ
    public let message: String?

    public init(code: Int?, message: String?) {
        self.code = code
        self.message = message
    }
}

// MARK: - ユーティリティ関数

/// `ResetTimeValue`をepoch秒へ正規化
///
/// - Parameter value: 正規化前のリセット時刻
/// - Returns: epoch秒（パース失敗時はnil）
public func normalizeResetTime(_ value: ResetTimeValue) -> Int? {
    switch value {
    case .seconds(let s):
        return s
    case .milliseconds(let ms):
        return ms / 1000
    case .iso8601(let str):
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: str) else {
            return nil
        }
        return Int(date.timeIntervalSince1970)
    }
}

/// 使用率を計算（percentageフィールドを優先）
///
/// - Parameters:
///   - percentage: APIから返されたpercentage値（あれば）
///   - usage: 使用量
///   - total: 上限
/// - Returns: 使用率（0-100の整数）
public func calculatePercentage(percentage: Double?, usage: Double, total: Double) -> Int {
    if let pct = percentage {
        return Int(floor(pct))
    }
    guard total > 0 else {
        return 0
    }
    return Int(floor(100 * usage / total))
}

// MARK: - 正規化サポート

/// Z.aiのプライマリクォータタイプ
private enum PrimaryQuotaType: String {
    case tokens5H = "TOKENS_5H"

    /// 指定されたタイプがプライマリかどうかを判定
    static func isPrimary(_ type: String) -> Bool {
        return type == tokens5H.rawValue
    }
}

/// タイプから表示用タイトルを生成（例: "TOKENS_5H" → "GLM 5h"）
private func formatTitle(for type: String) -> String {
    switch type.uppercased() {
    case "TOKENS_5H":
        return "GLM 5h"
    default:
        return type.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

/// セカンダリ枠のラベルを生成（例: "WEB_SEARCH_MONTHLY" → "Search (Monthly)"）
private func formatSecondaryLabel(for type: String) -> String {
    switch type.uppercased() {
    case "WEB_SEARCH_MONTHLY":
        return "Search (Monthly)"
    case "READER_MONTHLY":
        return "Reader (Monthly)"
    case "ZREAD_MONTHLY":
        return "ZRead (Monthly)"
    default:
        let formatted = type
            .replacingOccurrences(of: "_", with: " ")
            .lowercased()
            .capitalized
        if formatted.contains("Monthly") {
            return formatted.replacingOccurrences(of: "Monthly", with: "(Monthly)")
        }
        return formatted
    }
}

// MARK: - UsageSnapshot正規化

extension UsageSnapshot {
    /// Z.aiのQuotaDataからUsageSnapshotを生成
    ///
    /// - Parameters:
    ///   - quotaData: Z.ai APIレスポンスのデータ部分
    ///   - providerId: プロバイダ識別子（デフォルト: "zai"）
    ///   - includeDebugJson: デバッグJSONを含めるか（デフォルト: false）
    /// - Returns: 正規化されたUsageSnapshot。プライマリクォータがない場合はnil
    public init?(from quotaData: QuotaData, providerId: String = "zai", includeDebugJson: Bool = false) {
        let fetchedAtEpoch = Date().epochSeconds

        // プライマリとセカンダリを分類
        var primary: QuotaLimit?
        var secondaryItems: [QuotaLimit] = []

        for limit in quotaData.limits {
            if PrimaryQuotaType.isPrimary(limit.type) {
                primary = limit
            } else {
                secondaryItems.append(limit)
            }
        }

        // プライマリが必須
        guard let primaryLimit = primary else {
            return nil
        }

        // プライマリ情報の設定
        self.providerId = providerId
        self.fetchedAtEpoch = fetchedAtEpoch
        self.primaryTitle = formatTitle(for: primaryLimit.type)
        self.primaryPct = calculatePercentage(
            percentage: primaryLimit.percentage,
            usage: primaryLimit.usage,
            total: primaryLimit.number
        )
        self.primaryUsed = primaryLimit.usage
        self.primaryTotal = primaryLimit.number
        self.primaryRemaining = primaryLimit.remaining
        self.resetEpoch = normalizeResetTime(primaryLimit.nextResetTime)

        // セカンダリ枠の正規化
        self.secondary = secondaryItems.map { limit in
            UsageLimit(
                label: formatSecondaryLabel(for: limit.type),
                pct: calculatePercentage(
                    percentage: limit.percentage,
                    usage: limit.usage,
                    total: limit.number
                ),
                used: limit.usage,
                total: limit.number,
                remaining: limit.remaining,
                resetEpoch: normalizeResetTime(limit.nextResetTime)
            )
        }

        // デバッグJSON（オプション）
        if includeDebugJson {
            if let jsonData = try? JSONEncoder().encode(quotaData),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                self.rawDebugJson = jsonString
            } else {
                self.rawDebugJson = nil
            }
        } else {
            self.rawDebugJson = nil
        }
    }
}

//
//  TimeFormatter.swift
//  QuotaWatch
//
//  時間フォーマットユーティリティ
//

import Foundation

/// 時間フォーマットユーティリティ
public enum TimeFormatter {
    /// DateFormatterの静的キャッシュ（formatResetTime用）
    private static let resetTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d H:mm"
        return formatter
    }()

    /// 残り時間をフォーマット（"0h04m"形式で統一）
    ///
    /// - Parameter resetEpoch: リセット時刻（epoch秒）
    /// - Returns: フォーマットされた時間文字列
    ///
    /// ## フォーマットルール
    /// - 常に `XhYYm` 形式で統一（4:30の紛らわしさを解消）
    /// - 例: 4時間30分 → "4h30m", 4分30秒 → "0h04m", 45秒 → "0h00m"
    public static func formatTimeRemaining(resetEpoch: Int) -> String {
        let now = Date().epochSeconds
        let seconds = max(0, resetEpoch - now)

        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        return String(format: "%dh%02dm", hours, minutes)
    }

    /// リセット時刻をフォーマット（"1/15 15:30"形式）
    ///
    /// - Parameter resetEpoch: リセット時刻（epoch秒）
    /// - Returns: フォーマットされた日時文字列
    public static func formatResetTime(resetEpoch: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(resetEpoch))
        return resetTimeFormatter.string(from: date)
    }
}

// MARK: - Date拡張

extension Date {
    /// epoch秒を取得
    var epochSeconds: Int {
        return Int(timeIntervalSince1970)
    }
}

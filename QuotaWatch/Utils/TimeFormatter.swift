//
//  TimeFormatter.swift
//  QuotaWatch
//
//  時間フォーマットユーティリティ
//

import Foundation

/// 時間フォーマットユーティリティ
public enum TimeFormatter {
    /// 残り時間をフォーマット（"2h36m"形式）
    ///
    /// - Parameter resetEpoch: リセット時刻（epoch秒）
    /// - Returns: フォーマットされた時間文字列
    ///
    /// ## フォーマットルール
    /// - 0-59秒: "42s"
    /// - 1-59分: "15m"
    /// - 1時間以上: "2h36m" または "2h"（残り分钟がない場合）
    public static func formatTimeRemaining(resetEpoch: Int) -> String {
        let now = Date().epochSeconds
        let seconds = max(0, resetEpoch - now)

        // 1分未満
        if seconds < 60 {
            return "\(seconds)s"
        }

        let minutes = seconds / 60

        // 1時間未満
        if minutes < 60 {
            return "\(minutes)m"
        }

        // 1時間以上
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if remainingMinutes > 0 {
            return "\(hours)h\(remainingMinutes)m"
        } else {
            return "\(hours)h"
        }
    }
}

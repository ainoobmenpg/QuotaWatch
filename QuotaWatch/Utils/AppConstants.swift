//
//  AppConstants.swift
//  QuotaWatch
//
//  アプリ全体で使用する定数
//

import Foundation

/// アプリ全体で使用する定数
public enum AppConstants {
    /// 時間関連定数（すべて秒数で統一）
    public static let maxBackoffSeconds: TimeInterval = 900        // バックオフ最大値（15分）
    public static let jitterSeconds: TimeInterval = 15              // ジッター範囲（0-15秒）
    public static let resetIntervalSeconds: TimeInterval = 18000    // クォータリセット間隔（5時間）
    public static let notificationCheckInterval: TimeInterval = 60  // 通知チェック周期（1分）
    public static let minBaseInterval: TimeInterval = 60            // ユーザー設定可能な最短フェッチ間隔（1分）
}

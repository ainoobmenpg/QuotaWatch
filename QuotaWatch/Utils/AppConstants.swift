//
//  AppConstants.swift
//  QuotaWatch
//
//  アプリ全体で使用する定数
//

import Foundation
import AppKit
import SwiftUI

/// アプリ全体で使用する定数
public enum AppConstants {
    /// 時間関連定数（すべて秒数で統一）
    public static let maxBackoffSeconds: TimeInterval = 900        // バックオフ最大値（15分）
    public static let jitterSeconds: TimeInterval = 15              // ジッター範囲（0-15秒）
    public static let resetIntervalSeconds: TimeInterval = 18000    // クォータリセット間隔（5時間）
    public static let notificationCheckInterval: TimeInterval = 60  // 通知チェック周期（1分）
    public static let minBaseInterval: TimeInterval = 60            // ユーザー設定可能な最短フェッチ間隔（1分）

    /// 連続失敗閾値（10回失敗で停止）
    /// 理由: 基本フェッチ間隔60秒 × バックオフ最大15分 = 約2.5時間のリトライ期間
    public static let maxConsecutiveFailures: Int = 10              // 連続失敗が閾値を超えた場合、runLoopを停止

    /// 色の閾値（残り率ベース）
    public static let quotaThresholdHealthy: Int = 50               // 残り50%超: 緑
    public static let quotaThresholdWarning: Int = 20               // 残り20-50%: オレンジ、残り20%未満: 赤

    /// クォータステータス色
    public enum Color {
        /// NSColor（AppKit用）
        public enum NSColor {
            public static let healthy = AppKit.NSColor.systemGreen    // 残り50%超
            public static let warning = AppKit.NSColor.systemOrange   // 残り20-50%
            public static let critical = AppKit.NSColor.systemRed     // 残り20%未満
        }

        /// Color（SwiftUI用）
        public enum SwiftUIColor {
            public static let healthy = SwiftUI.Color.green           // 残り50%超
            public static let warning = SwiftUI.Color.orange          // 残り20-50%
            public static let critical = SwiftUI.Color.red            // 残り20%未満
        }
    }
}

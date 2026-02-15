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
        /// カラーグラデーション用のRGB値
        public struct RGB: Sendable {
            public let red: CGFloat
            public let green: CGFloat
            public let blue: CGFloat

            public init(red: CGFloat, green: CGFloat, blue: CGFloat) {
                self.red = red
                self.green = green
                self.blue = blue
            }
        }

        /// グラデーション用カラーストップ（残量100% -> 0%）
        public enum GradientStop {
            /// 残り100%: 鮮やかな緑
            public static let fullGreen = RGB(red: 0.0, green: 0.8, blue: 0.0)
            /// 残り75%: 黄緑
            public static let yellowGreen = RGB(red: 0.5, green: 0.9, blue: 0.2)
            /// 残り50%: 黄
            public static let yellow = RGB(red: 1.0, green: 0.9, blue: 0.0)
            /// 残り35%: 黄橙
            public static let yellowOrange = RGB(red: 1.0, green: 0.7, blue: 0.0)
            /// 残り20%: オレンジ
            public static let orange = RGB(red: 1.0, green: 0.5, blue: 0.0)
            /// 残り10%: 赤橙
            public static let redOrange = RGB(red: 1.0, green: 0.3, blue: 0.0)
            /// 残り0%: 鮮やかな赤
            public static let fullRed = RGB(red: 1.0, green: 0.0, blue: 0.0)
        }

        /// グラデーションの境界点（残りパーセンテージ）
        public enum GradientBoundary {
            public static let full: Int = 100
            public static let high: Int = 75
            public static let medium: Int = 50
            public static let midLow: Int = 35
            public static let low: Int = 20
            public static let critical: Int = 10
            public static let empty: Int = 0
        }

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

//
//  NumberFormatterUtil.swift
//  QuotaWatch
//
//  数値フォーマットユーティリティ
//

import Foundation

/// 数値フォーマットユーティリティ
///
/// 大きな数値をK（千）/ M（百万）表記に変換します。
public enum NumberFormatterUtil {

    // MARK: - フォーマット定数

    /// 小数点フォーマット（1桁）
    private static let decimalFormat = "%.1f"
    /// 整数フォーマット
    private static let integerFormat = "%.0f"

    // MARK: - パブリックメソッド

    /// 数値をK/M表記でフォーマット
    ///
    /// - Parameter value: フォーマットする数値
    /// - Returns: フォーマットされた文字列
    ///
    /// ## フォーマットルール
    /// - 1,000,000以上: "1.5M", "10.0M"（百万単位、小数点1桁）
    /// - 1,000以上: "1.5K", "10.0K"（千単位、小数点1桁）
    /// - 1,000未満: "42", "999"（整数）
    /// - 負数: 絶対値をフォーマットしてマイナス記号を付加
    ///
    /// ## 使用例
    /// ```swift
    /// NumberFormatterUtil.format(1500)     // "1.5K"
    /// NumberFormatterUtil.format(1500000)  // "1.5M"
    /// NumberFormatterUtil.format(999)      // "999"
    /// NumberFormatterUtil.format(0)        // "0"
    /// NumberFormatterUtil.format(-1500)    // "-1.5K"
    /// ```
    public static func format(_ value: Double) -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""

        if absValue >= 1_000_000 {
            let millions = absValue / 1_000_000
            return sign + String(format: decimalFormat + "M", millions)
        } else if absValue >= 1_000 {
            let thousands = absValue / 1_000
            return sign + String(format: decimalFormat + "K", thousands)
        } else {
            return sign + String(format: integerFormat, absValue)
        }
    }

    /// 整数値をK/M表記でフォーマット（Intオーバーロード）
    ///
    /// - Parameter value: フォーマットする整数値
    /// - Returns: フォーマットされた文字列
    public static func format(_ value: Int) -> String {
        return format(Double(value))
    }
}

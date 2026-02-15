//
//  StatusView.swift
//  QuotaWatch
//
//  状態表示セクション
//

import SwiftUI

/// 状態表示ビュー
///
/// 最終フェッチ時刻、次回フェッチ時刻、バックオフ係数、エラーを表示します。
/// QuotaCardを使用して、コンパクトな1行表示と視覚的フィードバックを提供します。
@MainActor
@preconcurrency
struct StatusView: View, Equatable {
    /// 最終フェッチ時刻（epoch秒）
    let lastFetchEpoch: Int

    /// 次回フェッチ時刻（epoch秒）
    let nextFetchEpoch: Int

    /// バックオフ係数
    let backoffFactor: Int

    /// 最終エラーメッセージ（任意）
    let errorMessage: String?

    /// ステータスカードの背景色
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        QuotaCard(
            title: "ステータス",
            gradientColors: statusGradientColors
        ) {
            VStack(alignment: .leading, spacing: 8) {
                // メインステータス行（コンパクト1行表示）
                mainStatusRow

                // バックオフ中またはエラー時の詳細情報
                if backoffFactor > 1 || errorMessage != nil {
                    Divider()
                        .opacity(0.3)
                    detailInfoSection
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(statusAccessibilityLabel)
    }

    // MARK: - コンテンツビュー

    /// メインステータス行（コンパクト1行表示）
    private var mainStatusRow: some View {
        HStack(spacing: 12) {
            // ステータスアイコン
            statusIcon

            // フェッチ情報
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("最終:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(formatLastFetch())
                        .font(.caption)
                        .foregroundStyle(.primary)
                }

                HStack(spacing: 4) {
                    Text("次回:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(formatNextFetch())
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
            }

            Spacer()

            // バックオフまたはエラーインジケーター
            statusIndicator
        }
    }

    /// ステータスアイコン
    private var statusIcon: some View {
        Group {
            if errorMessage != nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.white)
                    .font(.title3)
            } else if backoffFactor > 1 {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.white)
                    .font(.title3)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
        }
        .frame(width: 28, height: 28)
    }

    /// ステータスインジケーター（バックオフ係数またはエラー表示）
    @ViewBuilder
    private var statusIndicator: some View {
        if backoffFactor > 1 {
            VStack(spacing: 2) {
                Text("バックオフ")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.9))
                Text("x\(backoffFactor)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white.opacity(0.2))
            )
        } else if errorMessage != nil {
            VStack(spacing: 2) {
                Text("エラー")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.9))
                Text("詳細>")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white.opacity(0.2))
            )
        } else {
            EmptyView()
        }
    }

    /// 詳細情報セクション（バックオフ中またはエラー時）
    @ViewBuilder
    private var detailInfoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let error = errorMessage {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.white.opacity(0.9))
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .lineLimit(3)
                }
            }

            if backoffFactor > 1 {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.white.opacity(0.9))
                        .font(.caption)
                    Text("レート制限により一時的にフェッチ間隔を延長しています")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
    }

    // MARK: - 背景色計算

    /// ステータスに応じたグラデーション背景色
    private var statusGradientColors: [Color]? {
        if errorMessage != nil {
            // エラー時: 赤系グラデーション
            return errorGradientColors
        } else if backoffFactor > 1 {
            // バックオフ中: オレンジ系グラデーション
            return backoffGradientColors
        }
        // 正常時: グラデーションなし（標準グレー背景）
        return nil
    }

    /// エラー時の赤系グラデーション
    private var errorGradientColors: [Color] {
        [Color.red.opacity(0.25), Color.red.opacity(0.15)]
    }

    /// バックオフ中のオレンジ系グラデーション
    private var backoffGradientColors: [Color] {
        [Color.orange.opacity(0.25), Color.orange.opacity(0.15)]
    }

    // MARK: - フォーマット

    /// 最終フェッチ時刻をフォーマット
    private func formatLastFetch() -> String {
        let now = Date().epochSeconds
        let diff = now - lastFetchEpoch

        // 未来の日付や異常値（負のdiff）の場合
        if diff < 0 {
            return "不明"
        }

        if diff < 60 {
            return "\(diff)秒前"
        } else if diff < 3600 {
            let minutes = diff / 60
            return "\(minutes)分前"
        } else if diff < 86400 {
            let hours = diff / 3600
            return "\(hours)時間前"
        } else {
            let days = diff / 86400
            return "\(days)日前"
        }
    }

    /// 次回フェッチ時刻をフォーマット
    private func formatNextFetch() -> String {
        let now = Date().epochSeconds
        let diff = max(0, nextFetchEpoch - now)

        if diff == 0 {
            return "すぐ"
        } else if diff < 60 {
            return "\(diff)秒後"
        } else if diff < 3600 {
            let minutes = diff / 60
            return "\(minutes)分後"
        } else {
            let hours = diff / 3600
            return "\(hours)時間後"
        }
    }

    /// アクセシビリティラベル
    private var statusAccessibilityLabel: String {
        var label = "ステータス: "
        if let error = errorMessage {
            label += "エラー - \(error)"
        } else if backoffFactor > 1 {
            label += "バックオフ中（係数\(backoffFactor)倍）"
        } else {
            label += "正常"
        }
        label += "、最終フェッチ\(formatLastFetch())、次回\(formatNextFetch())"
        return label
    }

    // MARK: - Equatable

    nonisolated static func == (lhs: StatusView, rhs: StatusView) -> Bool {
        lhs.lastFetchEpoch == rhs.lastFetchEpoch &&
        lhs.nextFetchEpoch == rhs.nextFetchEpoch &&
        lhs.backoffFactor == rhs.backoffFactor &&
        lhs.errorMessage == rhs.errorMessage
    }
}

// MARK: - Preview

#Preview("正常状態") {
    StatusView(
        lastFetchEpoch: Date().epochSeconds - 120,
        nextFetchEpoch: Date().epochSeconds + 180,
        backoffFactor: 1,
        errorMessage: nil
    )
    .frame(width: 320)
    .padding()
}

#Preview("バックオフ中") {
    StatusView(
        lastFetchEpoch: Date().epochSeconds - 300,
        nextFetchEpoch: Date().epochSeconds + 600,
        backoffFactor: 4,
        errorMessage: nil
    )
    .frame(width: 320)
    .padding()
}

#Preview("エラー状態") {
    StatusView(
        lastFetchEpoch: Date().epochSeconds - 600,
        nextFetchEpoch: Date().epochSeconds + 300,
        backoffFactor: 1,
        errorMessage: "APIキーが無効です"
    )
    .frame(width: 320)
    .padding()
}

#Preview("エラー+バックオフ") {
    StatusView(
        lastFetchEpoch: Date().epochSeconds - 900,
        nextFetchEpoch: Date().epochSeconds + 720,
        backoffFactor: 8,
        errorMessage: "ネットワークエラーが発生しました"
    )
    .frame(width: 320)
    .padding()
}

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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ステータス")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                // Last fetch
                HStack {
                    Text("最終フェッチ:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatLastFetch())
                        .font(.caption)
                        .foregroundStyle(.primary)
                    Spacer()
                }

                // Next attempt
                HStack {
                    Text("次回フェッチ:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatNextFetch())
                        .font(.caption)
                        .foregroundStyle(.primary)
                    Spacer()
                }

                // Backoff factor
                if backoffFactor > 1 {
                    HStack {
                        Text("バックオフ係数:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("x\(backoffFactor)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Spacer()
                    }
                }

                // Error message
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption2)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .lineLimit(2)
                    }
                }
            }
        }
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

    // MARK: - Equatable

    nonisolated static func == (lhs: StatusView, rhs: StatusView) -> Bool {
        lhs.lastFetchEpoch == rhs.lastFetchEpoch &&
        lhs.nextFetchEpoch == rhs.nextFetchEpoch &&
        lhs.backoffFactor == rhs.backoffFactor &&
        lhs.errorMessage == rhs.errorMessage
    }
}

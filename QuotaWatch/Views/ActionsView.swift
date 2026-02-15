//
//  ActionsView.swift
//  QuotaWatch
//
//  アクションボタンセクション（Liquid Glass対応）
//

import SwiftUI

/// Liquid Glass アイコンボタン
struct IconButton: View {
    let systemImage: String
    let tooltip: String
    let action: () async -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 16))
                .foregroundStyle(isDisabled ? .secondary : .primary)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.glass)
        .disabled(isDisabled)
        .help(tooltip)
    }
}

/// アクションビュー（Liquid Glass対応）
///
/// Force fetch、Test notification、Open Dashboardのアイコンボタンを表示します。
struct ActionsView: View {
    /// 強制フェッチアクション
    let onForceFetch: () async -> Void

    /// テスト通知アクション
    let onTestNotification: () async -> Void

    /// ダッシュボードを開くアクション
    let onOpenDashboard: () async -> Void

    /// フェッチ中かどうか
    var isFetching: Bool = false

    /// ダッシュボードURL
    var dashboardURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("アクション")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                // Force fetch
                IconButton(
                    systemImage: "arrow.clockwise",
                    tooltip: "強制フェッチ",
                    action: onForceFetch,
                    isDisabled: isFetching
                )

                // Test notification
                IconButton(
                    systemImage: "bell.badge",
                    tooltip: "通知テスト",
                    action: onTestNotification
                )

                // Open dashboard
                if dashboardURL != nil {
                    IconButton(
                        systemImage: "safari",
                        tooltip: "ダッシュボード",
                        action: onOpenDashboard
                    )
                }
            }
        }
    }
}

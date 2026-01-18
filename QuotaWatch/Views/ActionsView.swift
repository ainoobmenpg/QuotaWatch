//
//  ActionsView.swift
//  QuotaWatch
//
//  アクションボタンセクション
//

import SwiftUI

/// 非同期アクションを実行するボタン
struct AsyncButton: View {
    let title: String
    let systemImage: String?
    let action: () async -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            if let systemImage = systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .buttonStyle(.bordered)
        .disabled(isDisabled)
    }
}

/// アクションビュー
///
/// Force fetch、Test notification、Open Dashboardのボタンを表示します。
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
                AsyncButton(
                    title: "強制フェッチ",
                    systemImage: "arrow.clockwise",
                    action: onForceFetch,
                    isDisabled: isFetching
                )

                // Test notification
                AsyncButton(
                    title: "通知テスト",
                    systemImage: "bell.badge",
                    action: onTestNotification
                )

                // Open dashboard
                if let dashboardURL = dashboardURL {
                    AsyncButton(
                        title: "ダッシュボード",
                        systemImage: "safari",
                        action: onOpenDashboard
                    )
                }
            }
        }
    }
}

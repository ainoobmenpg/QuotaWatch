//
//  HeaderView.swift
//  QuotaWatch
//
//  ヘッダー（アプリ名/状態アイコン/Providerラベル）
//

import SwiftUI

/// ヘッダービュー
///
/// アプリ名、状態アイコン、Providerラベルを表示します。
struct HeaderView: View {
    /// バックオフ中かどうか
    var isBackingOff: Bool

    /// エラーがあるかどうか
    var hasError: Bool

    /// プロバイダ表示名
    var providerDisplayName: String

    var body: some View {
        HStack(spacing: 8) {
            // アプリ名
            Text("QuotaWatch")
                .font(.headline)
                .fontWeight(.semibold)

            // 状態アイコン
            statusIcon

            Spacer()

            // プロバイダラベル
            Text(providerDisplayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// 状態アイコン
    @ViewBuilder
    private var statusIcon: some View {
        if hasError {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .help("エラーが発生しています")
        } else if isBackingOff {
            Image(systemName: "pause.circle.fill")
                .foregroundStyle(.orange)
                .help("バックオフ中です")
        } else {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .help("正常に動作しています")
        }
    }
}

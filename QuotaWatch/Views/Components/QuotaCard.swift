import SwiftUI
import AppKit

/// 統一されたカード型コンテナ（Liquid Glass対応）
///
/// macOS 26 (Tahoe) の Liquid Glass デザイン言語を使用したカードスタイルを提供します。
struct QuotaCard<Content: View>: View {
    // MARK: - Properties

    /// カードのタイトル
    let title: String?

    /// ティント色（Liquid Glass用）
    let tintColor: Color?

    /// カードのコンテンツ
    @ViewBuilder let content: () -> Content

    // MARK: - Initializer

    /// QuotaCardを初期化します
    ///
    /// - Parameters:
    ///   - title: カードのタイトル（省略可能）
    ///   - gradientColors: グラデーション背景の色配列（非推奨 - tintColorを使用）
    ///   - tintColor: Liquid Glass用のティント色
    ///   - content: カード内に表示するコンテンツ
    init(
        title: String? = nil,
        gradientColors: [Color]? = nil,
        tintColor: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        // gradientColorsから最初の色をティント色として使用
        self.tintColor = tintColor ?? gradientColors?.first
        self.content = content
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // タイトルセクション
            if let title = title {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
            }

            // コンテンツセクション
            content()
        }
        .padding(16)
        .glassCardBackground(tintColor: tintColor)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Glass Card Background Modifier

private extension View {
    /// Liquid Glass カード用の背景を適用する修飾子
    func glassCardBackground(tintColor: Color?) -> some View {
        self
            .glassEffect(
                tintColor != nil ? .regular.tint(tintColor!) : .regular,
                in: .rect(cornerRadius: 12)
            )
    }
}

// MARK: - Preview

#Preview("標準カード") {
    QuotaCard(title: "クォータ使用状況") {
        VStack(alignment: .leading, spacing: 8) {
            Text("GLM-4")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Text("75%")
                    .font(.title)
                    .fontWeight(.bold)
                Text("使用済み")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    .frame(width: 200)
    .padding()
}

#Preview("グラデーションカード") {
    QuotaCard(
        title: "グラデーション背景",
        gradientColors: [.blue.opacity(0.3), .purple.opacity(0.3)]
    ) {
        Text("グラデーション効果を持つカード")
            .foregroundStyle(.primary)
    }
    .frame(width: 250)
    .padding()
}

#Preview("タイトルなし") {
    QuotaCard {
        HStack {
            VStack(alignment: .leading) {
                Text("高速クォータ")
                    .font(.headline)
                Text("残り: 25回")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("45%")
                .font(.title2)
                .fontWeight(.semibold)
        }
    }
    .frame(width: 200)
    .padding()
}

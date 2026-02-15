import SwiftUI
import AppKit

/// 統一されたカード型コンテナ
///
/// ドロップシャドウ、角丸、背景を持つカードスタイルを提供します。
/// オプションでグラデーション背景もサポートします。
struct QuotaCard<Content: View>: View {
    // MARK: - Properties

    /// カードのタイトル
    let title: String?

    /// グラデーション背景色（nilの場合は単色背景）
    let gradientColors: [Color]?

    /// カードのコンテンツ
    @ViewBuilder let content: () -> Content

    // MARK: - Initializer

    /// QuotaCardを初期化します
    ///
    /// - Parameters:
    ///   - title: カードのタイトル（省略可能）
    ///   - gradientColors: グラデーション背景の色配列（省略可能）
    ///   - content: カード内に表示するコンテンツ
    init(
        title: String? = nil,
        gradientColors: [Color]? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.gradientColors = gradientColors
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
        .cardBackground(gradientColors: gradientColors)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Card Background Modifier

private extension View {
    /// カード用の背景を適用する修飾子
    func cardBackground(gradientColors: [Color]?) -> some View {
        self.background(
            Group {
                if let colors = gradientColors, !colors.isEmpty {
                    // グラデーション背景
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                } else {
                    // 単色背景（ダークモード対応）
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                }
            }
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

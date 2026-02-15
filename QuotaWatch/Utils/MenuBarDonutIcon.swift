//
//  MenuBarDonutIcon.swift
//  QuotaWatch
//
//  SwiftUI を使ってメニューバー用の円グラフアイコンを生成する
//  案E: 1つの円 + 数字 + 外枠（時間経過）
//

import AppKit
import SwiftUI

/// SwiftUI を使って円グラフを描画し、NSImage を生成する構造体
/// 案E: 1つの円 + 中央に数字 + 外枠で時間経過を表示
@MainActor
struct MenuBarDonutIcon {
    /// 使用率（0-100）
    let usagePercentage: Int

    /// 残り時間の進捗（0-1）
    let timeProgress: Double

    /// 円グラフの直径
    let diameter: CGFloat

    /// ステータス色を取得（残り率ベース、グラデーション適用）
    private var statusColor: Color {
        QuotaColorCalculator.shared.gradientColor(forUsage: usagePercentage)
    }

    /// 残りパーセント（0-100）
    private var remainingPercentage: Int {
        max(0, min(100, 100 - usagePercentage))
    }

    /// NSImage を生成
    func makeImage() -> NSImage {
        // SwiftUI View を作成
        let view = UnifiedIconView(
            remainingPercentage: remainingPercentage,
            timeProgress: timeProgress,
            statusColor: statusColor,
            size: diameter
        )
        .frame(width: diameter, height: diameter)

        // ImageRenderer で NSImage に変換
        // 高DPI対応: スクリーンのバックングスケールを取得して設定
        let mainScreen = NSScreen.main
        let backingScaleFactor = mainScreen?.backingScaleFactor ?? 2.0

        let renderer = ImageRenderer(content: view)
        renderer.scale = backingScaleFactor  // Retinaディスプレイ対応
        renderer.isOpaque = false

        guard let nsImage = renderer.nsImage else {
            // フォールバック：空の画像を返す
            return NSImage(size: NSSize(width: diameter, height: diameter))
        }

        return nsImage
    }
}

/// 統合アイコンビュー（1つの円 + 数字 + 外枠）
private struct UnifiedIconView: View {
    /// 残りパーセント（0-100）
    let remainingPercentage: Int

    /// 時間経過（0-1）
    let timeProgress: Double

    /// ステータス色
    let statusColor: Color

    /// サイズ
    let size: CGFloat

    /// 外枠の太さ
    private var outerRingWidth: CGFloat { size * 0.08 }

    /// 内側ドーナツの太さ
    private var innerDonutWidth: CGFloat { size * 0.12 }

    /// 数字のフォントサイズ
    private var fontSize: CGFloat { size * 0.4 }

    var body: some View {
        ZStack {
            // 1. 外枠リング（時間経過）- 薄いグレー
            OuterRingView(
                progress: timeProgress,
                ringWidth: outerRingWidth,
                size: size
            )

            // 2. 内側ドーナツ（残量）
            InnerDonutView(
                remainingPercentage: remainingPercentage,
                color: statusColor,
                ringWidth: innerDonutWidth,
                size: size * 0.75 // 外枠の内側に配置
            )

            // 3. 中央の数字
            Text("\(remainingPercentage)")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(statusColor)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(width: size, height: size)
        // drawingGroupでレンダリング品質を向上（アンチエイリアス強化）
        .drawingGroup()
    }
}

/// 外枠リング（時間経過を表示）
private struct OuterRingView: View {
    /// 進捗（0-1）
    let progress: Double

    /// リングの太さ
    let ringWidth: CGFloat

    /// 全体のサイズ
    let size: CGFloat

    var body: some View {
        ZStack {
            // 背景リング（薄いグレー）
            Circle()
                .stroke(
                    Color.primary.opacity(0.15),
                    lineWidth: ringWidth
                )

            // 進捗リング（グレー）
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.primary.opacity(0.4),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // 上から始める
        }
        .frame(width: size, height: size)
    }
}

/// 内側ドーナツ（残量を表示）
private struct InnerDonutView: View {
    /// 残りパーセント（0-100）
    let remainingPercentage: Int

    /// 色
    let color: Color

    /// リングの太さ
    let ringWidth: CGFloat

    /// 全体のサイズ
    let size: CGFloat

    var body: some View {
        ZStack {
            // 背景ドーナツ（使用済み部分）
            Circle()
                .stroke(
                    Color.secondary.opacity(0.2),
                    lineWidth: ringWidth
                )

            // 残りドーナツ（メインの色）
            Circle()
                .trim(from: 0, to: CGFloat(remainingPercentage) / 100.0)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // 上から始める
                .animation(.easeInOut(duration: 0.3), value: remainingPercentage)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview("案E: 統合アイコン") {
    VStack(spacing: 20) {
        // 異なる残量のプレビュー
        HStack(spacing: 15) {
            // 健全状態（75%残り）
            Image(nsImage: MenuBarDonutIcon(
                usagePercentage: 25,
                timeProgress: 0.7,
                diameter: 22
            ).makeImage())
            .background(Color.black.opacity(0.1))

            // 警告状態（40%残り）
            Image(nsImage: MenuBarDonutIcon(
                usagePercentage: 60,
                timeProgress: 0.5,
                diameter: 22
            ).makeImage())
            .background(Color.black.opacity(0.1))

            // 危険状態（10%残り）
            Image(nsImage: MenuBarDonutIcon(
                usagePercentage: 90,
                timeProgress: 0.3,
                diameter: 22
            ).makeImage())
            .background(Color.black.opacity(0.1))
        }
        .padding()

        // サイズ比較
        HStack(spacing: 15) {
            Image(nsImage: MenuBarDonutIcon(
                usagePercentage: 30,
                timeProgress: 0.5,
                diameter: 16
            ).makeImage())
            .background(Color.black.opacity(0.1))

            Image(nsImage: MenuBarDonutIcon(
                usagePercentage: 30,
                timeProgress: 0.5,
                diameter: 22
            ).makeImage())
            .background(Color.black.opacity(0.1))

            Image(nsImage: MenuBarDonutIcon(
                usagePercentage: 30,
                timeProgress: 0.5,
                diameter: 28
            ).makeImage())
            .background(Color.black.opacity(0.1))
        }
        .padding()
        .background(Color.gray.opacity(0.2))
    }
}

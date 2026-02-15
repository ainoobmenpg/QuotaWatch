//
//  MenuBarDonutIcon.swift
//  QuotaWatch
//
//  SwiftUI を使ってメニューバー用の円グラフアイコンを生成する
//

import AppKit
import SwiftUI

/// SwiftUI を使って円グラフを描画し、NSImage を生成する構造体
@MainActor
struct MenuBarDonutIcon {
    /// 使用率（0-100）
    let usagePercentage: Int

    /// 残り時間の進捗（0-1）
    let timeProgress: Double

    /// 各円グラフの直径
    let diameter: CGFloat

    /// ステータス色を取得（残り率ベース）
    private var statusColor: Color {
        QuotaColorCalculator.shared.color(forUsage: usagePercentage)
    }

    /// NSImage を生成
    func makeImage() -> NSImage {
        // 絵文字(10pt) + 円グラフ(16pt) + スペース(2pt) × 2 + グラフ間スペース(8pt) = 約51pt幅
        let emojiSize: CGFloat = 10
        let spacing: CGFloat = 8
        let chartSpacing: CGFloat = 8

        let chartWidth = CGFloat(diameter)
        let leftGroupWidth = emojiSize + spacing + chartWidth
        let rightGroupWidth = emojiSize + spacing + chartWidth
        let totalWidth = leftGroupWidth + chartSpacing + rightGroupWidth

        // SwiftUI View を作成
        let view = ZStack {
            // 背景は透明
            Color.clear

            HStack(spacing: 0) {
                // 左側：使用率グラフ + 絵文字
                HStack(spacing: spacing) {
                    Text("📊")
                        .font(.system(size: emojiSize))
                        .frame(width: emojiSize, height: diameter, alignment: .center)

                    MenuBarDonutChartView(
                        percentage: usagePercentage,
                        color: statusColor,
                        size: diameter
                    )
                }

                // スペース
                Spacer()
                    .frame(width: chartSpacing)

                // 右側：残り時間グラフ + 絵文字
                HStack(spacing: spacing) {
                    Text("⏰")
                        .font(.system(size: emojiSize))
                        .frame(width: emojiSize, height: diameter, alignment: .center)

                    MenuBarDonutChartView(
                        percentage: Int(timeProgress * 100),
                        color: .blue,
                        size: diameter
                    )
                }
            }
        }
        .frame(width: totalWidth, height: diameter)

        // ImageRenderer で NSImage に変換
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        renderer.isOpaque = false

        guard let nsImage = renderer.nsImage else {
            // フォールバック：空の画像を返す
            return NSImage(size: NSSize(width: totalWidth, height: diameter))
        }

        return nsImage
    }
}

/// メニューバー用のシンプルな円グラフ（残り強調）
private struct MenuBarDonutChartView: View {
    /// 使用率（0-100）
    let percentage: Int

    /// 色
    let color: Color

    /// サイズ
    let size: CGFloat

    /// 残り率
    private var remainingPercentage: Int {
        max(0, min(100, 100 - percentage))
    }

    var body: some View {
        ZStack {
            // 背景円（使用済み部分）
            Circle()
                .stroke(
                    Color.secondary.opacity(0.2),
                    lineWidth: 3.0
                )

            // 残り円グラフ（メインの色）
            Circle()
                .trim(from: 0, to: CGFloat(remainingPercentage) / 100.0)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 3.0, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // 上から始める
                .animation(.easeInOut, value: remainingPercentage)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        // 異なる使用率のプレビュー
        HStack(spacing: 15) {
            Image(nsImage: MenuBarDonutIcon(
                usagePercentage: 20,
                timeProgress: 0.7,
                diameter: 16
            ).makeImage())

            Image(nsImage: MenuBarDonutIcon(
                usagePercentage: 50,
                timeProgress: 0.5,
                diameter: 16
            ).makeImage())

            Image(nsImage: MenuBarDonutIcon(
                usagePercentage: 80,
                timeProgress: 0.3,
                diameter: 16
            ).makeImage())
        }
        .padding()
        .background(Color.black.opacity(0.1))
    }
}

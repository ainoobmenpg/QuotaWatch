//
//  MenuBarDonutIcon.swift
//  QuotaWatch
//
//  SwiftUI を使ってメニューバー用の円グラフアイコンを生成する
//  Phase 6: 2つ並び（残量 + 残り時間）
//

import AppKit
import SwiftUI

/// SwiftUI を使って円グラフを描画し、NSImage を生成する構造体
/// Phase 6: 2つの円を横並び（残量 + 残り時間）
@MainActor
struct MenuBarDonutIcon {
    /// 使用率（0-100）
    let usagePercentage: Int

    /// 残り時間の進捗（0-1）
    let timeProgress: Double

    /// 残り秒数
    let remainingSeconds: Int

    /// 各円の直径
    let diameter: CGFloat

    /// 2つの円の間隔
    let spacing: CGFloat

    /// ステータス色を取得（残り率ベース、グラデーション適用）
    private var statusColor: Color {
        QuotaColorCalculator.shared.gradientColor(forUsage: usagePercentage)
    }

    /// 残りパーセント（0-100）
    private var remainingPercentage: Int {
        max(0, min(100, 100 - usagePercentage))
    }

    /// 初期化
    init(
        usagePercentage: Int,
        timeProgress: Double,
        remainingSeconds: Int,
        diameter: CGFloat = 22,
        spacing: CGFloat = 4
    ) {
        self.usagePercentage = usagePercentage
        self.timeProgress = timeProgress
        self.remainingSeconds = remainingSeconds
        self.diameter = diameter
        self.spacing = spacing
    }

    /// NSImage を生成
    func makeImage() -> NSImage {
        let totalWidth = diameter * 2 + spacing
        let totalHeight = diameter

        // SwiftUI View を作成（2つの円を横並び）
        let view = HStack(spacing: spacing) {
            // 左側: 残量（案E）
            UnifiedIconView(
                displayText: "\(remainingPercentage)",
                innerProgress: Double(remainingPercentage) / 100.0,
                outerProgress: timeProgress,
                innerColor: statusColor,
                outerColor: .primary.opacity(0.4),
                size: diameter
            )

            // 右側: 残り時間（青系）
            UnifiedIconView(
                displayText: formatRemainingTime(remainingSeconds),
                innerProgress: timeProgress,
                outerProgress: timeProgress,
                innerColor: .blue.opacity(0.8),
                outerColor: .blue.opacity(0.3),
                size: diameter
            )
        }
        .frame(width: totalWidth, height: totalHeight)

        // ImageRenderer で NSImage に変換
        let mainScreen = NSScreen.main
        let backingScaleFactor = mainScreen?.backingScaleFactor ?? 2.0

        let renderer = ImageRenderer(content: view)
        renderer.scale = backingScaleFactor
        renderer.isOpaque = false

        guard let nsImage = renderer.nsImage else {
            return NSImage(size: NSSize(width: totalWidth, height: totalHeight))
        }

        return nsImage
    }

    // MARK: - 時間フォーマット

    /// 残り秒数を H:MM または M:SS 形式にフォーマット
    private func formatRemainingTime(_ seconds: Int) -> String {
        let clampedSeconds = max(0, seconds)

        if clampedSeconds >= 3600 {
            // 1時間以上: H:MM 形式
            let hours = clampedSeconds / 3600
            let minutes = (clampedSeconds % 3600) / 60
            return String(format: "%d:%02d", hours, minutes)
        } else {
            // 1時間未満: M:SS 形式
            let minutes = clampedSeconds / 60
            let secs = clampedSeconds % 60
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - 統合アイコンビュー（1つの円 + 数字 + 外枠）

/// 統合アイコンビュー（1つの円 + 数字 + 外枠）
private struct UnifiedIconView: View {
    /// 表示テキスト
    let displayText: String

    /// 内側ドーナツの進捗（0-1）
    let innerProgress: Double

    /// 外枠の進捗（0-1）
    let outerProgress: Double

    /// 内側の色
    let innerColor: Color

    /// 外枠の色
    let outerColor: Color

    /// サイズ
    let size: CGFloat

    /// 外枠の太さ
    private var outerRingWidth: CGFloat { size * 0.08 }

    /// 内側ドーナツの太さ
    private var innerDonutWidth: CGFloat { size * 0.12 }

    /// 数字のフォントサイズ
    private var fontSize: CGFloat { size * 0.35 }

    var body: some View {
        ZStack {
            // 1. 外枠リング
            OuterRingView(
                progress: outerProgress,
                ringWidth: outerRingWidth,
                size: size,
                progressColor: outerColor
            )

            // 2. 内側ドーナツ
            InnerDonutView(
                progress: innerProgress,
                color: innerColor,
                ringWidth: innerDonutWidth,
                size: size * 0.75
            )

            // 3. 中央の数字
            Text(displayText)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(innerColor)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(width: size, height: size)
        .drawingGroup()
    }
}

// MARK: - 外枠リング

/// 外枠リング（進捗を表示）
private struct OuterRingView: View {
    let progress: Double
    let ringWidth: CGFloat
    let size: CGFloat
    let progressColor: Color

    var body: some View {
        ZStack {
            // 背景リング
            Circle()
                .stroke(
                    Color.primary.opacity(0.15),
                    lineWidth: ringWidth
                )

            // 進捗リング
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 内側ドーナツ

/// 内側ドーナツ（進捗を表示）
private struct InnerDonutView: View {
    let progress: Double
    let color: Color
    let ringWidth: CGFloat
    let size: CGFloat

    var body: some View {
        ZStack {
            // 背景ドーナツ
            Circle()
                .stroke(
                    Color.secondary.opacity(0.2),
                    lineWidth: ringWidth
                )

            // 進捗ドーナツ
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview("Phase 6: 2つ並び") {
    VStack(spacing: 20) {
        // 異なる残量のプレビュー
        HStack(spacing: 15) {
            // 健全状態（75%残り、残り4時間32分）
            Image(nsImage: MenuBarDonutIcon(
                usagePercentage: 25,
                timeProgress: 0.7,
                remainingSeconds: 16320,
                diameter: 22
            ).makeImage())
            .background(Color.black.opacity(0.1))

            // 警告状態（40%残り、残り2時間15分）
            Image(nsImage: MenuBarDonutIcon(
                usagePercentage: 60,
                timeProgress: 0.5,
                remainingSeconds: 8100,
                diameter: 22
            ).makeImage())
            .background(Color.black.opacity(0.1))

            // 危険状態（10%残り、残り45分）
            Image(nsImage: MenuBarDonutIcon(
                usagePercentage: 90,
                timeProgress: 0.3,
                remainingSeconds: 2700,
                diameter: 22
            ).makeImage())
            .background(Color.black.opacity(0.1))
        }
        .padding()

        // 時間フォーマットのテスト
        HStack(spacing: 15) {
            // 1時間以上
            Image(nsImage: MenuBarDonutIcon(
                usagePercentage: 30,
                timeProgress: 0.5,
                remainingSeconds: 5432, // 1:30:32
                diameter: 22
            ).makeImage())
            .background(Color.black.opacity(0.1))

            // 1時間未満
            Image(nsImage: MenuBarDonutIcon(
                usagePercentage: 30,
                timeProgress: 0.5,
                remainingSeconds: 1832, // 30:32
                diameter: 22
            ).makeImage())
            .background(Color.black.opacity(0.1))

            // 1分未満
            Image(nsImage: MenuBarDonutIcon(
                usagePercentage: 30,
                timeProgress: 0.5,
                remainingSeconds: 45, // 0:45
                diameter: 22
            ).makeImage())
            .background(Color.black.opacity(0.1))
        }
        .padding()
        .background(Color.gray.opacity(0.2))
    }
}

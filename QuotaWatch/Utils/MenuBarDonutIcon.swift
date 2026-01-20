//
//  MenuBarDonutIcon.swift
//  QuotaWatch
//
//  NSBezierPath を使ってメニューバー用の円グラフアイコンを生成する
//

import AppKit

/// NSBezierPath を使って円グラフを描画し、NSImage を生成する構造体
struct MenuBarDonutIcon {
    /// 使用率（0-100）
    let usagePercentage: Int

    /// 残り時間の進捗（0-1）
    let timeProgress: Double

    /// 各円グラフの直径
    let diameter: CGFloat

    /// ステータス色を取得（残り率ベース）
    private var statusColor: NSColor {
        let remainingPercentage = 100 - usagePercentage
        if remainingPercentage > AppConstants.quotaThresholdHealthy {
            return AppConstants.Color.NSColor.healthy
        } else if remainingPercentage > AppConstants.quotaThresholdWarning {
            return AppConstants.Color.NSColor.warning
        } else {
            return AppConstants.Color.NSColor.critical
        }
    }

    /// NSImage を生成
    func makeImage() -> NSImage {
        // 絵文字(10pt) + 円グラフ(16pt) + スペース(2pt) × 2 + グラフ間スペース(15pt) = 約51pt幅
        let emojiSize: CGFloat = 10
        let spacing: CGFloat = 8
        let chartSpacing: CGFloat = 8

        let chartWidth = CGFloat(diameter)
        let leftGroupWidth = emojiSize + spacing + chartWidth
        let rightGroupWidth = emojiSize + spacing + chartWidth
        let totalWidth = leftGroupWidth + chartSpacing + rightGroupWidth

        let image = NSImage(size: NSSize(width: totalWidth, height: diameter))
        image.lockFocus()

        let context = NSGraphicsContext.current?.cgContext
        context?.setShouldAntialias(true)

        // 左側：使用率グラフ + 📊
        let leftX: CGFloat = 0
        drawEmoji("📊", at: NSPoint(x: leftX, y: 0), size: emojiSize, centerY: diameter / 2)
        let chart1Center = NSPoint(x: leftX + emojiSize + spacing + diameter / 2, y: diameter / 2)
        drawDonutChart(
            center: chart1Center,
            diameter: diameter,
            percentage: usagePercentage,
            color: statusColor
        )

        // 右側：残り時間グラフ + ⏰
        let rightX = leftX + emojiSize + spacing + diameter + chartSpacing
        drawEmoji("⏰", at: NSPoint(x: rightX, y: 0), size: emojiSize, centerY: diameter / 2)
        let chart2Center = NSPoint(x: rightX + emojiSize + spacing + diameter / 2, y: diameter / 2)
        drawDonutChart(
            center: chart2Center,
            diameter: diameter,
            percentage: Int(timeProgress * 100),
            color: .systemBlue
        )

        image.unlockFocus()
        return image
    }

    /// 絵文字を描画（中央揃え）
    private func drawEmoji(_ emoji: String, at point: NSPoint, size: CGFloat, centerY: CGFloat) {
        let font = NSFont.systemFont(ofSize: size)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let attrString = NSAttributedString(string: emoji, attributes: attrs)

        // 完全中央揃え
        let yOffset = centerY - size / 2 - 2

        attrString.draw(at: NSPoint(x: point.x, y: yOffset))
    }

    /// 円グラフを描画（残り強調）
    private func drawDonutChart(center: NSPoint, diameter: CGFloat, percentage: Int, color: NSColor) {
        let radius = diameter / 2
        let lineWidth: CGFloat = 3.0

        // 背景円（薄いグレー - 使用済み部分）
        let backgroundPath = NSBezierPath()
        backgroundPath.appendArc(
            withCenter: center,
            radius: radius - lineWidth / 2,
            startAngle: 0,
            endAngle: 360
        )
        NSColor.separatorColor.withAlphaComponent(0.3).setStroke()
        backgroundPath.lineWidth = lineWidth
        backgroundPath.stroke()

        // 残り円グラフ（メインの色）
        let remainingPercentage = max(0, min(100, 100 - percentage))
        let startAngle: CGFloat = 90  // 上から始める
        let endAngle = startAngle - (CGFloat(remainingPercentage) / 100.0 * 360)

        let foregroundPath = NSBezierPath()
        foregroundPath.appendArc(
            withCenter: center,
            radius: radius - lineWidth / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        color.setStroke()
        foregroundPath.lineWidth = lineWidth
        foregroundPath.stroke()
    }
}

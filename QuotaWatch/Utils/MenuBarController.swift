//
//  MenuBarController.swift
//  QuotaWatch
//
//  メニューバーの表示とポップアップを管理するクラス（NSStatusItemのみ使用）
//

import AppKit
import Combine
import SwiftUI

/// メニューバーの表示とポップアップを管理するクラス
///
/// NSStatusItem と NSMenu を使用してメニューバーを制御する
/// SwiftUI の MenuBarExtra は使用しない（競合回避）
@MainActor
final class MenuBarController: ObservableObject {
    // MARK: - プロパティ

    /// NSStatusItem（Sendableではないためnonisolated(unsafe)を使用）
    ///
    /// MenuBarControllerは@MainActorで実行されるため、すべてのアクセスはメインスレッドで行われる
    nonisolated(unsafe) private let statusItem: NSStatusItem

    /// ContentViewModelへの弱参照
    private weak var viewModel: ContentViewModel?

    /// AppDelegateへの弱参照
    private weak var appDelegate: AppDelegate?

    /// CombineのCancellables
    private var cancellables = Set<AnyCancellable>()

    /// NSHostingController（SwiftUI ViewをNSMenuに埋め込むため）
    private var hostingController: NSHostingController<MenuBarPopupView>?

    /// 5時間を秒数で表現
    private let fiveHoursInSeconds: Double = 5 * 60 * 60

    // MARK: - アニメーション関連

    /// アニメーションの継続時間（秒）
    private let animationDuration: Double = 0.3

    /// フレーム間隔（秒）60fps
    private let frameInterval: Double = 1.0 / 60.0

    /// 現在の使用率（アニメーション用）
    private var currentUsagePercentage: Int?

    /// 目標の使用率（アニメーション用）
    private var targetUsagePercentage: Int?

    /// 現在の時間進捗（アニメーション用）
    private var currentTimeProgress: Double?

    /// 目標の時間進捗（アニメーション用）
    private var targetTimeProgress: Double?

    /// アニメーション開始時刻
    private var animationStartTime: Date?

    /// アニメーション開始時の値
    private var animationStartUsage: Int?
    private var animationStartTimeProgress: Double?

    /// アニメーションタイマー
    private var animationTimer: Timer?

    // MARK: - 初期化

    /// MenuBarControllerを初期化
    ///
    /// - Parameters:
    ///   - viewModel: ContentViewModel
    ///   - appDelegate: AppDelegate
    init(viewModel: ContentViewModel, appDelegate: AppDelegate) {
        self.viewModel = viewModel
        self.appDelegate = appDelegate
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // NSHostingControllerを作成
        let popupView = MenuBarPopupView(
            viewModel: viewModel,
            appDelegate: appDelegate
        )
        self.hostingController = NSHostingController(rootView: popupView)

        // 初期表示を即座に設定
        startIconAnimation()

        // 監視を設定（prepend なし）
        setupObservation()

        // ポップアップメニューを設定
        setupMenu()
    }

    // MARK: - 設定

    /// メニューバー変更の監視を設定
    private func setupObservation() {
        guard let viewModel = viewModel else { return }

        // snapshot の変更を監視（メインスレッドで実行）
        viewModel.$snapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] (_: UsageSnapshot?) in
                self?.startIconAnimation()
            }
            .store(in: &cancellables)
    }

    /// ポップアップメニューを設定
    private func setupMenu() {
        let menu = NSMenu()

        // カスタムビューを持つメニューアイテム
        if let hostedView = hostingController?.view {
            // コンテンツに応じたサイズを計算（最小サイズを確保）
            let fittingSize = hostedView.fittingSize
            hostedView.frame.size = NSSize(
                width: max(360, fittingSize.width),
                height: max(200, min(600, fittingSize.height))
            )

            let viewItem = NSMenuItem()
            viewItem.view = hostedView
            menu.addItem(viewItem)
        }

        // 終了メニューアイテム
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(
            title: "終了",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApplication.shared
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - 更新

    /// アイコンアニメーションを開始
    private func startIconAnimation() {
        // snapshotから目標値を取得
        guard let snapshot = viewModel?.snapshot,
              let pct = snapshot.primaryPct else {
            // データがない場合は即座に更新
            updateMenuBarIconDirectly(usagePercentage: nil, timeProgress: nil)
            return
        }

        // 残り時間の進捗度を計算（5時間枠）
        // resetEpoch が nil の場合は進捗0%として扱う（リセット直後など）
        let now = Int(Date().timeIntervalSince1970)
        let calculatedTimeProgress: Double
        if let resetEpoch = snapshot.resetEpoch, resetEpoch > now {
            // 未リセット：進捗を計算
            let periodStart = resetEpoch - Int(fiveHoursInSeconds)
            let elapsed = max(0, Double(now - periodStart))
            calculatedTimeProgress = min(elapsed / fiveHoursInSeconds, 1.0)
        } else {
            // リセット済みまたは resetEpoch が nil：進捗0%
            calculatedTimeProgress = 0.0
        }

        // 目標値を設定
        targetUsagePercentage = pct
        targetTimeProgress = calculatedTimeProgress

        // 初回または値が大きく変化した場合のみアニメーション開始
        let shouldAnimate: Bool
        if let current = currentUsagePercentage, let currentTime = currentTimeProgress, let targetTime = targetTimeProgress {
            // 変化量が小さい場合はアニメーションしない（1%未満または時間進捗が0.01未満）
            let usageDelta = abs(Double(current - pct))
            let timeDelta = abs(currentTime - targetTime)
            shouldAnimate = usageDelta >= 1.0 || timeDelta >= 0.01
        } else {
            // 初回はアニメーションなしで即時表示
            shouldAnimate = false
        }

        if shouldAnimate {
            // アニメーション開始
            animationStartTime = Date()
            animationStartUsage = currentUsagePercentage
            animationStartTimeProgress = currentTimeProgress

            // 既存のタイマーをキャンセル
            animationTimer?.invalidate()

            // タイマーを開始
            animationTimer = Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.updateAnimationFrame()
                }
            }
        } else {
            // 即時更新
            currentUsagePercentage = pct
            currentTimeProgress = targetTimeProgress
            updateMenuBarIconDirectly(usagePercentage: pct, timeProgress: targetTimeProgress)
        }
    }

    /// アニメーションフレームを更新
    private func updateAnimationFrame() {
        guard let startTime = animationStartTime,
              let startUsage = animationStartUsage,
              let startTimeProgress = animationStartTimeProgress,
              let targetUsage = targetUsagePercentage,
              let targetTime = targetTimeProgress else {
            animationTimer?.invalidate()
            animationTimer = nil
            return
        }

        let elapsed = Date().timeIntervalSince(startTime)
        let progress = min(elapsed / animationDuration, 1.0)

        // easeInOutカーブを適用
        let easedProgress = easeInOut(progress)

        // 値を補間
        let currentUsage = Int(Double(startUsage) + (Double(targetUsage - startUsage) * easedProgress))
        let currentTime = startTimeProgress + ((targetTime - startTimeProgress) * easedProgress)

        currentUsagePercentage = currentUsage
        currentTimeProgress = currentTime

        updateMenuBarIconDirectly(usagePercentage: currentUsage, timeProgress: currentTime)

        // アニメーション完了
        if progress >= 1.0 {
            animationTimer?.invalidate()
            animationTimer = nil
            animationStartTime = nil
            animationStartUsage = nil
            animationStartTimeProgress = nil
        }
    }

    /// easeInOutカーブを計算
    private func easeInOut(_ t: Double) -> Double {
        return t < 0.5
            ? 2 * t * t
            : 1 - pow(-2 * t + 2, 2) / 2
    }

    /// メニューバーアイコンを直接更新（アニメーション用）
    private func updateMenuBarIconDirectly(usagePercentage: Int?, timeProgress: Double?) {
        guard let button = statusItem.button else { return }

        guard let pct = usagePercentage, let timeProg = timeProgress else {
            // データがない場合はテキストを表示
            button.title = viewModel?.menuBarTitle ?? "..."
            button.image = nil
            return
        }

        // 残り秒数を計算
        let remainingSeconds: Int
        if let resetEpoch = viewModel?.snapshot?.resetEpoch {
            let now = Int(Date().timeIntervalSince1970)
            remainingSeconds = max(0, resetEpoch - now)
        } else {
            remainingSeconds = 0
        }

        // NSImage を直接生成
        let icon = MenuBarDonutIcon(
            usagePercentage: pct,
            timeProgress: timeProg,
            remainingSeconds: remainingSeconds,
            diameter: 22
        )
        let image = icon.makeImage()

        button.title = ""
        button.image = image
        button.image?.isTemplate = false
    }

    // MARK: - クリーンアップ

    deinit {
        // タイマーの無効化（synchronizationなし）
        // Note: deinitでは同期処理が制限されるため、非同期クリーンアップは行わない
        // animationTimerは自動的に解放される
    }

    /// 明示的なクリーンアップメソッド（解放前に呼び出す推奨）
    func cleanup() {
        animationTimer?.invalidate()
        animationTimer = nil
        NSStatusBar.system.removeStatusItem(statusItem)
    }
}

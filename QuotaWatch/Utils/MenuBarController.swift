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
        updateMenuBarIcon()

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
                self?.updateMenuBarIcon()
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

    /// メニューバーアイコンを更新
    private func updateMenuBarIcon() {
        guard let button = statusItem.button else { return }

        // snapshotからデータを取得
        guard let snapshot = viewModel?.snapshot,
              let pct = snapshot.primaryPct,
              let resetEpoch = snapshot.resetEpoch else {
            // データがない場合はテキストを表示
            button.title = viewModel?.menuBarTitle ?? "..."
            button.image = nil
            return
        }

        // 残り時間の進捗度を計算（5時間枠）
        let now = Int(Date().timeIntervalSince1970)
        let timeProgress: Double
        if resetEpoch > now {
            // 未リセット：進捗を計算
            let periodStart = resetEpoch - Int(fiveHoursInSeconds)
            let elapsed = max(0, Double(now - periodStart))
            timeProgress = min(elapsed / fiveHoursInSeconds, 1.0)
        } else {
            // リセット済み：進捗0%
            timeProgress = 0.0
        }

        // NSImage を直接生成
        let icon = MenuBarDonutIcon(
            usagePercentage: pct,
            timeProgress: timeProgress,
            diameter: 16
        )
        let image = icon.makeImage()

        button.title = ""
        button.image = image
        button.image?.isTemplate = false

        // ログ出力
        Task { @MainActor in
            await LoggerManager.shared.log(
                "メニューバーアイコン更新: pct=\(pct)%, timeProgress=\(Int(timeProgress * 100))%",
                category: "MENUBAR"
            )
        }
    }

    // MARK: - クリーンアップ

    deinit {
        NSStatusBar.system.removeStatusItem(statusItem)
    }
}

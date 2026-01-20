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

        // 初期タイトルを即座に設定
        updateTitle()

        // 監視を設定（prepend なし）
        setupObservation()

        // ポップアップメニューを設定
        setupMenu()
    }

    // MARK: - 設定

    /// メニューバータイトル変更の監視を設定
    private func setupObservation() {
        guard let viewModel = viewModel else { return }

        // 初期値を明示的に emit して監視
        viewModel.$menuBarTitle
            .prepend(viewModel.menuBarTitle)
            .sink { [weak self] _ in
                self?.updateTitle()
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

    /// メニューバーのタイトルを更新
    private func updateTitle() {
        guard let button = statusItem.button else { return }

        let title = viewModel?.menuBarTitle ?? "..."
        button.title = title
        button.sizeToFit()

        // ログ出力
        Task { @MainActor in
            await LoggerManager.shared.log("メニューバータイトル更新: \(title)", category: "MENUBAR")
        }
    }

    // MARK: - クリーンアップ

    deinit {
        NSStatusBar.system.removeStatusItem(statusItem)
    }
}

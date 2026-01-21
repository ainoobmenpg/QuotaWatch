//
//  AppSettings.swift
//  QuotaWatch
//
//  設定値を管理するモデル
//

import Foundation
import SwiftUI
import OSLog
@preconcurrency import ServiceManagement

// MARK: - Login Item Service

/// Login Itemを管理するサービスのプロトコル
///
/// テスト容易性のため、SMAppServiceへの直接的な依存を抽象化します。
public protocol LoginItemService: Sendable {
    /// Login Itemの状態を取得
    var status: LoginItemStatus { get }

    /// Login Itemを登録
    /// - Throws: 登録に失敗した場合
    func register() throws

    /// Login Itemを解除
    /// - Throws: 解除に失敗した場合
    func unregister() throws
}

/// Login Itemの状態
public enum LoginItemStatus: Sendable {
    /// 有効
    case enabled
    /// 無効
    case disabled
    /// 不明（macOS 13.0未満等）
    case unknown
}

/// SMAppServiceを使用した実装
///
/// @unchecked Sendable: SMAppServiceはSendableに準拠していないが、
/// appServiceプロパティは不変（let）でスレッド安全
@available(macOS 13.0, *)
public struct SMAppServiceLoginItem: @unchecked Sendable, LoginItemService {
    private let appService: SMAppService

    /// デフォルトイニシャライザ（mainAppを使用）
    public init() {
        self.appService = SMAppService.mainApp
    }

    /// テスト用イニシャライザ
    init(appService: SMAppService) {
        self.appService = appService
    }

    public var status: LoginItemStatus {
        switch appService.status {
        case .enabled:
            return .enabled
        case .notRegistered, .notFound:
            return .disabled
        default:
            return .unknown
        }
    }

    public func register() throws {
        try appService.register()
    }

    public func unregister() throws {
        try appService.unregister()
    }
}

/// macOS 13.0未満用のダミー実装
public struct LegacyLoginItemService: LoginItemService {
    public var status: LoginItemStatus {
        return .unknown
    }

    public func register() throws {
        throw LoginItemError.unsupportedOS
    }

    public func unregister() throws {
        throw LoginItemError.unsupportedOS
    }
}

/// Login Item関連のエラー
public enum LoginItemError: Error, LocalizedError {
    case unsupportedOS

    public var errorDescription: String? {
        switch self {
        case .unsupportedOS:
            return "Login Item機能はmacOS 13.0以上が必要です"
        }
    }
}

/// Login Itemサービスのファクトリ
public enum LoginItemServiceFactory {
    /// プラットフォーム適したLoginItemServiceを作成
    public static func makeService() -> any LoginItemService {
        if #available(macOS 13.0, *) {
            return SMAppServiceLoginItem()
        } else {
            return LegacyLoginItemService()
        }
    }
}

/// 更新間隔（秒）
public enum UpdateInterval: Int, CaseIterable, Identifiable, Codable {
    case oneMinute = 60
    case fiveMinutes = 300
    case tenMinutes = 600
    case fifteenMinutes = 900

    public var id: Self { self }

    /// 表示名
    var displayName: String {
        switch self {
        case .oneMinute: return "1分"
        case .fiveMinutes: return "5分"
        case .tenMinutes: return "10分"
        case .fifteenMinutes: return "15分"
        }
    }
}

/// アプリ設定を管理するモデル
@Observable
@MainActor
public final class AppSettings {
    // MARK: - UserDefaults Keys

    private enum Keys {
        static let updateInterval = "updateInterval"
        static let notificationsEnabled = "notificationsEnabled"
        static let loginItemEnabled = "loginItemEnabled"
    }

    // MARK: - 依存関係

    private let defaults: UserDefaults
    private let loginItemService: any LoginItemService
    private var updateTask: Task<Void, Never>?

    // MARK: - 設定値

    /// 更新間隔
    public var updateInterval: UpdateInterval {
        didSet {
            defaults.set(updateInterval.rawValue, forKey: Keys.updateInterval)
            logger.log("更新間隔を変更: \(self.updateInterval.displayName)")
        }
    }

    /// 通知有効/無効
    public var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
            logger.log("通知設定を変更: \(self.notificationsEnabled ? "有効" : "無効")")
        }
    }

    /// Login Item（ログイン時起動）有効/無効
    public var loginItemEnabled: Bool {
        didSet {
            defaults.set(loginItemEnabled, forKey: Keys.loginItemEnabled)
            updateLoginItemStatus()
            logger.log("Login Item設定を変更: \(self.loginItemEnabled ? "有効" : "無効")")
        }
    }

    // MARK: - Logger

    private let logger = Logger(subsystem: "com.quotawatch.settings", category: "AppSettings")

    // MARK: - 初期化

    /// AppSettingsを初期化
    ///
    /// - Parameters:
    ///   - defaults: UserDefaults（デフォルトは.standard）
    ///   - loginItemService: LoginItemService（デフォルトはプラットフォーム適した実装）
    public init(
        defaults: UserDefaults = .standard,
        loginItemService: (any LoginItemService)? = nil
    ) {
        self.defaults = defaults
        self.loginItemService = loginItemService ?? LoginItemServiceFactory.makeService()

        // UserDefaultsから読み込み
        let savedInterval = defaults.integer(forKey: Keys.updateInterval)
        self.updateInterval = UpdateInterval(rawValue: savedInterval) ?? .fiveMinutes

        self.notificationsEnabled = defaults.bool(forKey: Keys.notificationsEnabled)

        // 初回起動時は通知をデフォルトで有効にする
        if defaults.object(forKey: Keys.notificationsEnabled) == nil {
            self.notificationsEnabled = true
        }

        // LoginItemServiceの実際の状態とUserDefaultsを同期
        // （システム設定から手動で削除された場合等の不一致を修正）
        let actualStatus = self.loginItemService.status == .enabled
        let savedStatus = defaults.bool(forKey: Keys.loginItemEnabled)

        if actualStatus != savedStatus {
            // 実際の状態をUserDefaultsに反映（init内なのでdidSetは呼ばれない）
            defaults.set(actualStatus, forKey: Keys.loginItemEnabled)
        }
        self.loginItemEnabled = actualStatus
    }

    // MARK: - Login Item管理

    /// Login Itemの状態を更新
    ///
    /// デバウンシングにより、頻繁な変更をまとめて処理します
    private func updateLoginItemStatus() {
        // 前回の更新タスクをキャンセル
        updateTask?.cancel()

        // データ競合を避けるため、値をローカル変数にキャプチャ
        let isEnabled = loginItemEnabled

        // 非同期で状態を更新（didSetは同期的なのでTaskでラップ）
        updateTask = Task { @MainActor in
            // 少し待機してから実行（頻繁な変更をまとめる）
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05秒

            // タスクがキャンセルされていない場合のみ実行
            guard !Task.isCancelled else { return }

            do {
                if isEnabled {
                    // 登録試行
                    if loginItemService.status == .enabled {
                        logger.debug("Login Itemは既に有効です")
                        return
                    }
                    try loginItemService.register()
                    logger.info("Login Itemを登録しました")
                } else {
                    // 解除試行
                    if loginItemService.status != .enabled {
                        logger.debug("Login Itemは既に無効です")
                        return
                    }
                    try loginItemService.unregister()
                    logger.info("Login Itemを解除しました")
                }
            } catch {
                logger.error("Login Item設定エラー: \(error.localizedDescription)")
            }
        }
    }
}

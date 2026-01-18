//
//  AppSettings.swift
//  QuotaWatch
//
//  設定値を管理するモデル
//

import Foundation
import SwiftUI
import OSLog

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
public final class AppSettings {
    // MARK: - UserDefaults Keys

    private enum Keys {
        static let updateInterval = "updateInterval"
        static let notificationsEnabled = "notificationsEnabled"
        static let loginItemEnabled = "loginItemEnabled"
    }

    // MARK: - UserDefaults

    private let defaults: UserDefaults

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
    /// - Parameter defaults: UserDefaults（デフォルトは.standard）
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // UserDefaultsから読み込み
        let savedInterval = defaults.integer(forKey: Keys.updateInterval)
        self.updateInterval = UpdateInterval(rawValue: savedInterval) ?? .fiveMinutes

        self.notificationsEnabled = defaults.bool(forKey: Keys.notificationsEnabled)

        // 初回起動時は通知をデフォルトで有効にする
        if defaults.object(forKey: Keys.notificationsEnabled) == nil {
            self.notificationsEnabled = true
        }

        self.loginItemEnabled = defaults.bool(forKey: Keys.loginItemEnabled)
    }

    // MARK: - Login Item管理

    /// Login Itemの状態を更新
    private func updateLoginItemStatus() {
        // TODO: SMAppServiceでログイン時起動を設定
        // macOS 13+で利用可能
        // #available(macOS 13.0, *) {
        //     let appService = SMAppService.mainApp
        //     do {
        //         if loginItemEnabled {
        //             if appService.status != .enabled {
        //                 try appService.register()
        //             }
        //         } else {
        //             if appService.status == .enabled {
        //                 try appService.unregister()
        //             }
        //         }
        //     } catch {
        //         logger.error("Login Item設定エラー: \(error.localizedDescription)")
        //     }
        // }
    }
}

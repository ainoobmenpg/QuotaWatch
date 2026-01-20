//
//  OnboardingManager.swift
//  QuotaWatch
//
//  初回起動判定を管理
//

import Foundation
import Observation

/// 初回起動判定を管理するクラス
///
/// UserDefaultsを使用してオンボーディング完了状態を管理します。
/// 既存ユーザーのアップデート時はWindowを表示しないよう、デフォルト値をtrueにします。
@Observable
public final class OnboardingManager {
    private let userDefaults: UserDefaults
    private let key = "hasCompletedOnboarding"

    /// 初期化（テスト用にUserDefaultsを注入可能）
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// オンボーディング完了状態
    ///
    /// 既存ユーザーのアップデート時にWindowが表示されないよう、
    /// キーが存在しない場合はtrue（完了扱い）を返します。
    public var hasCompletedOnboarding: Bool {
        get {
            // キーが存在しない場合は既存ユーザーとして true を返す
            if userDefaults.object(forKey: key) == nil {
                return true  // 既存ユーザー: オンボーディング済みとみなす
            }
            return userDefaults.bool(forKey: key)
        }
        set { userDefaults.set(newValue, forKey: key) }
    }

    /// オンボーディングが必要かどうか
    ///
    /// - 初回インストール時: true（Windowを表示）
    /// - 2回目以降の起動: false（Windowを表示しない）
    /// - 既存ユーザーのアップデート: false（Windowを表示しない）
    public var needsOnboarding: Bool {
        !hasCompletedOnboarding
    }

    /// オンボーディング完了をマーク
    public func markCompleted() {
        hasCompletedOnboarding = true
    }

    /// オンボーディング状態をリセット（デバッグ用）
    public func reset() {
        hasCompletedOnboarding = false
    }

    /// 初回インストールとして設定
    ///
    /// アプリ初回起動時に呼び出すことで、オンボーディングWindowを表示するように設定します
    public func markAsFirstLaunch() {
        hasCompletedOnboarding = false
    }
}

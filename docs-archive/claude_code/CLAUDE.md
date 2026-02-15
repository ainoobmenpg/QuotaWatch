# Claude Code 作業ガイド（QuotaWatch）

## 目標
macOS 26.2+ のメニューバー常駐アプリ **QuotaWatch** をSwiftUIで実装する（Deployment Targetに26.2が無い場合は、指定可能な範囲で最新を選択）。

## 守るルール
- まずMVPを完成させ、後で拡張する
- 依存を増やさない（外部ライブラリ無し）
- 状態管理は `actor` + `@MainActor` ViewModel で単純化
- 例外系（APIキー未設定 / 通知未許可 / レート制限）を必ずUIに反映
- APIキーはKeychainのみ（ディスクに平文禁止）
- 競合（多重フェッチ/通知重複）を禁止
- 多プロバイダ化は「将来」：MVPでは `ZaiProvider` のみ。抽象は最小限に留める

## コーディング規約
- Swift 6 を前提
- `OSLog` でカテゴリ別ログ
- `async/await` を優先

## 実装の進め方
1. プロジェクト雛形（SwiftUI + MenuBarExtra）
2. 正規化モデル（UsageSnapshot）とZ.ai生モデル
3. KeychainStore
4. Provider（protocol + ZaiProvider）
5. QuotaEngine（バックオフ + 永続化 + 多重実行防止）
6. ResetNotifier（1分チェック + 重複防止）
7. UI（グラフィカル表示 + 操作 + 設定）
8. Login Item トグル
9. 手動テスト

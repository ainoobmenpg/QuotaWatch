# QuotaWatch

macOSのメニューバーに常駐し、AIサービス（Z.ai/GLM）のクォータ使用状況を監視・表示するアプリケーションです。

## 概要

QuotaWatchは、SwiftBarプラグインとして実装されていたクォータ監視機能を、ネイティブのmacOSアプリ（SwiftUI + MenuBarExtra）として完全に置き換えることを目的としています。

## MVPステータス

**完了: 2026-01-19**（Issue #29 Phase 10）

### 実装済み機能

- ✅ メニューバー常駐アプリ（MenuBarExtra）
- ✅ Z.ai APIからクォータ使用状況を取得
- ✅ グラフィカル表示（プログレスバー/ゲージ）
- ✅ 指数バックオフによるレート制限対応
- ✅ キャッシュ維持（API失敗時も表示を維持）
- ✅ リセット通知（重複防止あり）
- ✅ KeychainによるAPIキー管理
- ✅ ログイン時起動設定
- ✅ 更新間隔設定（最短1分）
- ✅ 通知ON/OFF設定
- ✅ ログ機能（LoggerManager + DebugLogger）

### 特徴

- **メニューバー常駐**: 常にクォータ使用状況を確認可能
- **グラフィカル表示**: プログレスバー/ゲージで直感的に使用率を表示
- **スマート更新**: 指数バックオフでレート制限に対応
- **キャッシュ維持**: API失敗時も最後の成功データを表示
- **リセット通知**: クォータリセット時に確実に通知（重複防止）
- **セキュア**: APIキーはKeychainで安全に管理
- **ログイン時起動**: 自動監視を開始

## 対象環境

- **macOS 26.2 (Tahoe, 25C56) 以降**
  - macOS Tahoeは2025年12月にリリースされたバージョン
- Apple Silicon (arm64) / Intel (x86_64)

## インストール方法（GitHub Releasesからダウンロード）

### ⚠️ 重要: 開発元未署名のアプリについて

このアプリはコード署名されていないため、**macOS Sequoia (15.0) 以降**では以下の手順でGatekeeperを回避する必要があります。

### 対応macOSバージョン

- **macOS 26.2 (Tahoe, 25C56)** ✅ 対応
- **macOS 15.x (Sequoia)** ✅ 対応
- **macOS 14.x (Sonoma) 以前** ✅ 対応

### インストール手順

1. [Releases](../../releases) から最新版の `QuotaWatch-vX.X.X-macOS.zip` をダウンロード
2. ZIPファイルをダブルクリックして展開
3. `QuotaWatch.app` をアプリケーションフォルダにドラッグ

### Gatekeeper回避手順（macOS Sequoia 15.0以降 / Tahoe 26.x）

macOSのセキュリティにより、初回起動時に以下の警告が表示されます：

> "QuotaWatch.app"は開発元を検証できないため開けません。

**回避手順**:
1. アプリをダブルクリックして起動を試みる（警告が表示されます）
2. **「システム設定」**を開く（警告ダイアログから遷移可能）
3. 左側メニューから**「プライバシーとセキュリティ」**を選択
4. 「"QuotaWatch.app"はブロックされました」の下にある**「このまま開く」**ボタンをクリック
5. 管理者パスワードを入力
6. **「開く」**をクリックしてアプリを起動

**2回目以降**: 通常通りダブルクリックで起動可能（macOSが信頼済みとして記録）

### Gatekeeper回避手順（macOS Sonoma 14.x 以前）

1. `QuotaWatch.app` を**Control+クリック**（または右クリック）
2. **「開く」**を選択
3. **「開く」**をクリック

### セキュリティについて

- ソースコードは完全に公開されており、誰でも監査可能です
- APIキーはmacOSのKeychainで安全に管理されます（ディスク保存なし）
- ネットワーク通信は Z.ai API (`api.z.ai`) のみに接続します
- オープンソース開発であるため、不審な動作がないかコミュニティによる監査が可能です

---

## ソースコードからビルドする場合

### 必要なもの

- Xcode 16.0以降
- macOS 26.2以降

### ビルド手順

```bash
# リポジトリをクローン
git clone https://github.com/your-username/QuotaWatch.git
cd QuotaWatch

# Xcodeでプロジェクトを開く
open QuotaWatch.xcodeproj

# ⌘B でビルド
```

### テスト実行

Xcodeのテストナビゲーターから、または以下のコマンドで実行：

```bash
xcodebuild test -scheme QuotaWatch -destination 'platform=macOS'
```

## 設計ドキュメント

詳細な設計情報は `quota-watch-menubar-docs/` を参照してください（**設計書のアーカイブ**）。

- [全体概要](quota-watch-menubar-docs/docs/00_overview.md)
- [アーキテクチャ](quota-watch-menubar-docs/docs/02_architecture.md)
- [データモデル](quota-watch-menubar-docs/docs/03_data_model.md)
- [ネットワークとAPI](quota-watch-menubar-docs/docs/04_networking_api.md)
- [スケジューリングとバックオフ](quota-watch-menubar-docs/docs/05_backoff_and_scheduler.md)
- [通知仕様](quota-watch-menubar-docs/docs/06_notifications.md)
- [セキュリティ](quota-watch-menubar-docs/docs/07_security_keychain.md)
- [UI/UX設計](quota-watch-menubar-docs/docs/08_ui_ux.md)
- [永続化](quota-watch-menubar-docs/docs/09_persistence.md)
- [常駐設定](quota-watch-menubar-docs/docs/10_login_item.md)
- [テスト計画](quota-watch-menubar-docs/docs/11_testing.md)

## ライセンス

MIT License - LICENSEファイルを参照してください

## 貢献

CONTRIBUTING.mdを参照してください。

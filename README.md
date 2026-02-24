# QuotaWatch

macOSのメニューバーに常駐し、AIサービス（Z.ai/GLM、MiniMax）のクォータ使用状況を監視・表示するアプリケーションです。

## 概要

QuotaWatchは、SwiftBarプラグインとして実装されていたクォータ監視機能を、ネイティブのmacOSアプリ（SwiftUI + MenuBarExtra）として完全に置き換えることを目的としています。

## 対応プロバイダ

- **Z.ai (GLM)**: 中国版のGLMサービス
- **MiniMax**: MiniMax Coding Plan API

## MVPステータス

**完了: 2026-01-19**（Issue #29 Phase 10）

### 実装済み機能

- ✅ メニューバー常駐アプリ（MenuBarExtra）
- ✅ マルチプロバイダ対応（Z.ai、MiniMax）
- ✅ Z.ai / MiniMax APIからクォータ使用状況を取得
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
- ネットワーク通信は Z.ai API (`api.z.ai`) または MiniMax API (`www.minimax.io`) に接続します
- オープンソース開発であるため、不審な動作がないかコミュニティによる監査が可能です

---

## セットアップ

### 初回起動時の設定

1. **APIキーの登録**
   - メニューバーのQuotaWatchアイコンをクリック
   - "APIキーを設定"ボタンをクリック
   - プロバイダ（Z.ai / MiniMax）を選択してAPIキーを入力

2. **通知の許可**
   - 初回フェッチ時に通知権限のダイアログが表示されます
   - "許可"をクリックして通知を受け取れるようにしてください

3. **ログイン時の自動起動**
   - 設定画面から「ログイン時に起動」をオンにすると、Mac起動時に自動で常駐します

### 既知の制約

- **macOS要件**: macOS 14.x (Sonoma) 以降
- **対応プロバイダ**: Z.ai、MiniMax
- **ネットワーク**: インターネット接続が必要
- **APIキー**: Z.ai または MiniMaxのアカウントとAPIキーが必要

### トラブルシューティング

#### 「APIキーが無効です」と表示される場合
- APIキーが正しいか確認してください
- APIキーの有効期限が切れていないか確認してください
- 設定シートからAPIキーを再設定してください

#### 通知が届かない場合
- macOSの通知設定でQuotaWatchが許可されているか確認してください
  - システム設定 > 通知 > QuotaWatch で「許可」がオンになっているか確認

#### データが更新されない場合
- インターネット接続を確認してください
- メニューポップアップの「今すぐ更新」ボタンで強制フェッチを試してください

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

詳細な設計情報は `docs-archive/` を参照してください（**設計書のアーカイブ**）。

- [全体概要](docs-archive/docs/00_overview.md)
- [アーキテクチャ](docs-archive/docs/02_architecture.md)
- [データモデル](docs-archive/docs/03_data_model.md)
- [ネットワークとAPI](docs-archive/docs/04_networking_api.md)
- [スケジューリングとバックオフ](docs-archive/docs/05_backoff_and_scheduler.md)
- [通知仕様](docs-archive/docs/06_notifications.md)
- [セキュリティ](docs-archive/docs/07_security_keychain.md)
- [UI/UX設計](docs-archive/docs/08_ui_ux.md)
- [永続化](docs-archive/docs/09_persistence.md)
- [常駐設定](docs-archive/docs/10_login_item.md)
- [テスト計画](docs-archive/docs/11_testing.md)

## ライセンス

MIT License - LICENSEファイルを参照してください

## 貢献

CONTRIBUTING.mdを参照してください。

# QuotaWatch

macOSのメニューバーに常駐し、AIサービス（Z.ai/GLM）のクォータ使用状況を監視・表示するアプリケーションです。

## 概要

QuotaWatchは、SwiftBarプラグインとして実装されていたクォータ監視機能を、ネイティブのmacOSアプリ（SwiftUI + MenuBarExtra）として完全に置き換えることを目的としています。

### 特徴

- **メニューバー常駐**: 常にクォータ使用状況を確認可能
- **グラフィカル表示**: プログレスバー/ゲージで直感的に使用率を表示
- **スマート更新**: 指数バックオフでレート制限に対応
- **キャッシュ維持**: API失敗時も最後の成功データを表示
- **リセット通知**: クォータリセット時に確実に通知（重複防止）
- **セキュア**: APIキーはKeychainで安全に管理
- **ログイン時起動**: 自動監視を開始

## 対象環境

- **macOS 26.2 (25C56) 以降**
- Apple Silicon (arm64) / Intel (x86_64)

## インストール

当面は配布形式を未定としています。自己ビルド手順は「開発環境セットアップ」を参照してください。

## 開発環境セットアップ

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

詳細な設計情報は `quota-watch-menubar-docs/` を参照してください。

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

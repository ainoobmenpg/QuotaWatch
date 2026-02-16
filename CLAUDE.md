# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

**QuotaWatch** は、macOSのメニューバー常駐アプリで、AIサービス（Z.ai/GLM）のクォータ使用状況を監視・表示するアプリケーションです。SwiftBarプラグインをネイティブSwiftUIアプリ（MenuBarExtra）に置換することが目的です。

**現在の状態**: **MVP完了**（2026-01-19、Issue #29 Phase 10完了）。設計書は `quota-watch-menubar-docs/` にアーカイブされています。

## 対象環境

- **macOS 26.2 (Tahoe, 25C56) 以降**（Deployment Targetに26.2が無い場合は指定可能な範囲で最新を選択）
- SwiftUI + MenuBarExtra
- 外部ライブラリ依存なし（ネイティブ実装のみ）

## 開発コマンド

**プロジェクト作成（未実装の場合）**:
```
XcodeでmacOSアプリプロジェクトを作成（SwiftUI選択）
MenuBarExtraを使用した最小構成を設定
```

**ビルド**:
- Xcodeでビルド（⌘B）または `xcodebuild` コマンド

**テスト**:
- XCTestを使用。単体テストは以下を対象:
  - `nextResetTime` のパース（秒/ミリ秒/ISO文字列）
  - 使用率計算ロジック
  - バックオフ計算
  - ロールバック防止ロジック

> **アーキテクチャ・データモデル**: @docs/quick-reference.md を参照
> **Gitワークフロー**: @.claude/rules/git-workflow.md を参照

## 実装タスク順序

設計書 `claude_code/TASKS.md` に従うこと:

1. T0: プロジェクト雛形（MenuBarExtra）
2. T1: 正規化モデル + Z.ai生モデル
3. T2: KeychainStore
4. T2.5: ログ機能（LoggerManager + DebugLogger）
5. T3: Provider（protocol + ZaiProvider）
6. T4: 永続化層
7. T5: QuotaEngine（actor）
8. T6: ResetNotifier + NotificationManager
9. T7: UI（グラフィカル表示）
10. T8: 設定（更新間隔/通知ON/OFF/Login Item）

## 参考ドキュメント

- `quota-watch-menubar-docs/README.md` - プロジェクト概要とゴール
- `quota-watch-menubar-docs/docs/00_overview.md` - 全体概要
- `quota-watch-menubar-docs/docs/02_architecture.md` - アーキテクチャ詳細
- `quota-watch-menubar-docs/docs/03_data_model.md` - データモデル詳細
- `quota-watch-menubar-docs/docs/04_networking_api.md` - API仕様
- `quota-watch-menubar-docs/docs/05_backoff_and_scheduler.md` - スケジューリングとバックオフ
- `quota-watch-menubar-docs/docs/06_notifications.md` - 通知仕様
- `quota-watch-menubar-docs/docs/07_security_keychain.md` - セキュリティ
- `quota-watch-menubar-docs/docs/08_ui_ux.md` - UI/UX設計
- `quota-watch-menubar-docs/docs/09_persistence.md` - 永続化
- `quota-watch-menubar-docs/docs/10_login_item.md` - 常駐設定
- `quota-watch-menubar-docs/docs/11_testing.md` - テスト計画
- `quota-watch-menubar-docs/docs/13_provider_abstraction.md` - Provider抽象
- `quota-watch-menubar-docs/claude_code/TASKS.md` - 実装タスク一覧

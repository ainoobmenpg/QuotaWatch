# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

**QuotaWatch** は、macOSのメニューバー常駐アプリで、AIサービス（Z.ai/GLM）のクォータ使用状況を監視・表示するアプリケーションです。SwiftBarプラグインをネイティブSwiftUIアプリ（MenuBarExtra）に置換することが目的です。

**現在の状態**: 実装中。設計書は `quota-watch-menubar-docs/` にあります。

## 対象環境

- **macOS 26.2 (25C56) 以降**（Deployment Targetに26.2が無い場合は指定可能な範囲で最新を選択）
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

## アーキテクチャ

### 主要コンポーネント

```
Provider protocol（抽象レイヤー）
├── ZaiProvider（MVP実装）
│
QuotaEngine（actor）
├── フェッチとバックオフの意思決定
├── 多重実行防止（actorによる直列化）
└── UsageSnapshotの生成
│
ResetNotifier
├── 1分周期でリセットチェック
└── 重複防止して通知
│
ViewModel（@MainActor）
└── SwiftUIへ状態を供給
```

### データフロー

1. **Provider** → APIフェッチ → `UsageSnapshot`（正規化済みモデル）へ変換
2. **QuotaEngine** → バックオフ制御 + `usage_cache.json` へ永続化
3. **ResetNotifier** → 1分周期でリセット検知 → `NotificationManager` 経由で通知
4. **UI** → `UsageSnapshot` のみを参照（Provider固有構造は参照しない）

### 重要な設計原則

- **MVPは単一プロバイダ（Z.ai）で完結** - 将来拡張のための最小限の抽象のみ導入
- **UIは正規化済み `UsageSnapshot` のみ参照** - Provider生レスポンス構造を直接見ない
- **actor + @MainActorで状態管理を単純化** - 競合を回避
- **APIキーはKeychainのみ** - ディスク保存は禁止
- **ログはLoggerManagerで一元管理** - DEBUG/RELEASE両ビルドでログ出力をサポート

## データモデル

### UsageSnapshot（正規化モデル）
UI/通知が参照する唯一のモデル:

```swift
- providerId: String        // 例: "zai"
- fetchedAtEpoch: Int        // 取得時刻
- primaryTitle: String       // 例: "GLM 5h"
- primaryPct: Int?           // 0-100
- primaryUsed/Total/Remaining: Double?
- resetEpoch: Int?           // 次回リセットのepoch秒
- secondary: [UsageLimit]    // 月次枠等
- rawDebugJson: String?      // デバッグ用
```

### Z.ai API仕様

- **Endpoint**: `https://api.z.ai/api/monitor/usage/quota/limit`
- **Method**: GET
- **Headers**: `Authorization: <API_KEY>`（ベアトークン形式）
- **Response**: `spec/api_sample.json` 参照

### レート制限判定（バックオフ対象）
- HTTP 429
- JSON内 `code` / `error.code` / `errorCode` が {1302, 1303, 1305}

## 永続化

**保存先**: `Application Support/<BundleID>/`

- `usage_cache.json` - 最新成功レスポンス（`UsageSnapshot`）
- `state.json` - 実行状態（次回フェッチ時刻、バックオフ係数、通知重複防止用epoch）

**状態スキーマ**: `spec/state_schema.json` 参照

## ログ機能

**LoggerManager（actor）** - ログ出力を一元管理:
- `DebugLogger` のシングルトンインスタンスを管理
- DEBUG/RELEASE両ビルドでログ出力をサポート
- ログサイズ制限（100KB）とローテーション
- ログのエクスポート機能（Desktopへコピー）
- ログ出力先: `Application Support/<BundleID>/debug.log`

**DebugLogger（actor）** - テキストファイルにログを出力:
- ログフォーマット: `[ISO8601 timestamp] [CATEGORY] message`
- カテゴリ別ログ出力（例: "FETCH", "ENGINE", "NOTIFICATION"）
- ログローテーション（サイズ超過時に古いログから削除）

## セキュリティ

- **APIキーはKeychainのみ保存**（`service=zai_api_key`）
- ディスク（UserDefaults/Application Support）に平文保存禁止

## バックオフ仕様

- 初期 `backoffFactor = 1`
- レート制限時: `factor * 2`、最大15分 + ジッター(0-15秒)
- 成功時: `factor = 1` にリセット
- 非レート失敗: 次回は通常間隔でリトライ

## 通知仕様

- 1分周期で `now >= lastKnownResetEpoch` を判定（フェッチ間隔に依存しない）
- `lastNotifiedResetEpoch != lastKnownResetEpoch` の場合のみ通知
- 通知後、epochを+5時間進めて重複防止
- `UNNotificationRequest.interruptionLevel = .timeSensitive` 推奨

## コーディング規約

- **Swift 6** で実装
- **OSLog** でカテゴリ別ロギング（システムログ）
- **LoggerManager** でデバッグログ出力（DEBUG/RELEASE両対応）
- **async/await** を優先
- **actor** による競合回避

## Gitワークフロー

> **🚨 重要: 作業は必ずfeatureブランチで行うこと**
> - **mainブランチへの直接コミットは禁止**
> - **必ずPRを作成してマージすること**

### なぜPRが必要か

> **コードレビューによる品質保証**
> - バグ、セキュリティ問題、設計の問題を早期に発見
> - 知識共有とチームの成長
> - 履歴のクリーン維持（squash mergeによる）
>
> **GitHub Flowの採用理由**
> - mainブランチは常にデプロイ可能な状態を保つ
> - 小さな変更を頻繁にマージすることでリスクを低減
> - 変更の履歴が明確になる

### コミットメッセージ規約（Conventional Commits）

コミットメッセージには以下のプレフィックスを使用します：

| プレフィックス | 用途 | 例 |
|--------------|------|-----|
| `feat:` | 新機能 | `feat: バックオフ計算ロジックを実装` |
| `fix:` | バグ修正 | `fix: レート制限時のバックオフ係数が倍増しない問題を修正` |
| `docs:` | ドキュメント | `docs: PR作成ワークフローを追加` |
| `refactor:` | リファクタリング | `refactor: Providerプロトコルの設計を見直し` |
| `test:` | テスト追加・修正 | `test: バックオフ計算のテストケースを追加` |
| `chore:` | その他 | `chore: Xcodeのビルド設定を更新` |

**形式**: `<type>: <short description>`

**Breaking Change**（後方互換性のない変更）の場合は、`!`を付けるかフッターに記載：
- `feat!: 認証システムを再設計`
- `feat: 新しいAPIを追加\nBREAKING CHANGE: 古いエンドポイントは削除されました`

### 作業開始時

```bash
# 1. mainを最新にする
git checkout main
git pull origin main

# 2. 作業ブランチを作成（必ず実行すること）
# - feature-xxx: 新機能開発
# - issue-N-xxx: Issue対応
git checkout -b feature-xxx  # または issue-N-xxx
```

### 作業完了時

```bash
# 1. 変更をコミット＆プッシュ
git add .
git commit -m "feat: コミットメッセージ"
git push -u origin feature-xxx
```

#### PRタイトルの形式

```
<type>: <短い説明>
```

例:
- `feat: バックオフ計算ロジックを実装`
- `fix: レート制限時のバックオフ係数が倍増しない問題を修正`
- `docs: PR作成ワークフローを追加`

#### PR本文のテンプレート

```bash
# 2. PRを作成
gh pr create --title "タイトル" --body "$(cat <<'EOF'
## 概要
<!-- このPRで何をしたか、なぜ必要かを簡潔に説明 -->

## 変更内容
<!-- 具体的な変更点をリスト -->
- ○○を実装
- □□を修正
- △△のドキュメントを追加

## 関連Issue
<!-- 関連するIssue番号を記載 -->
Closes #14

## テスト方法
<!-- 動作確認の手順を記載 -->
1. `xcodebuild test` を実行
2. すべてのテストがパスすることを確認

## チェックリスト
- [ ] テストがパスする
- [ ] ドキュメントを更新した
- [ ] レビューを実施した

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**簡略版（小さな変更の場合）**:
```bash
gh pr create --title "fix: ○○を修正" --body "Closes #XX"
```

#### Squash and Merge を使用する理由

**推奨マージ方法**: `Squash and merge`

| 方法 | メリット | デメリット |
|------|---------|-----------|
| **Squash and merge** ✓ | ✅ 履歴がクリーン（機能単位で1コミット）<br>✅ Work-in-progressコミットが履歴に残らない<br>✅ コミットメッセージを統一できる | ブランチの個別コミット履歴が失われる |
| Merge commit | ブランチのすべてのコミットが残る | 履歴が複雑になる |
| Rebase and merge | 線形履歴になる | コンフリクトのリスクが高い |

```bash
# 3. PRをマージ（レビュー後）
gh pr merge <PR番号> --squash --delete-branch
```

#### レビューチェックリスト

マージ前に以下を確認します：

| 項目 | 確認内容 |
|------|---------|
| **機能** | 仕様通りに動作するか |
| **テスト** | 新規・既存テストがパスするか |
| **ドキュメント** | ドキュメントを更新したか（必要な場合） |
| **セキュリティ** | セキュリティ上の問題がないか |
| **パフォーマンス** | パフォーマンスの劣化がないか |
| **コードスタイル** | プロジェクトのコーディング規約に従っているか |

**自己レビューのポイント**

PRを作成する前に以下を確認：
- [ ] 変更範囲が適切か（過剰/不足がないか）
- [ ] 不要なデバッグコードを削除したか
- [ ] コメントが必要な箇所に説明を追加したか
- [ ] テストカバレッジが適切か

```bash
# 4. 関連IssueをClose（あれば）
gh issue close <Issue番号> --comment "完了"

# 5. mainブランチへ戻して最新にする
git checkout main
git pull origin main

# 6. ローカルブランチを削除
git branch -d <ブランチ名>
```

### 違反した場合の修正手順

誤ってmainブランチで作業してしまった場合:

```bash
# 1. 作業内容をfeatureブランチに移動
git checkout -b feature-xxx
git push -u origin feature-xxx

# 2. mainをリセット
git checkout main
git reset --hard origin/main

# 3. 通常通りPRを作成
gh pr create --title "..." --body "..."
```

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

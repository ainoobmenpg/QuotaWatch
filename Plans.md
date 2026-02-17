# Plans.md - QuotaWatch MCP Server

> **作成日**: 2026-02-16
> **目的**: QuotaWatchのデータをMCPサーバーで公開し、Claude Code/OpenClaw等から確認できるようにする

---

## 🎯 ゴール

QuotaWatchのクォータ情報を他のツールから簡単に確認できるようにする。

**データフロー**:
```
QuotaWatchアプリ
    ↓ （定期書き出し）
~/Library/Application Support/com.quotawatch/*.json
    ↓ （読み取り）
quotawatch-mcp（Node.js）
    ↓ （MCPプロトコル）
Claude Code / OpenClaw / その他MCPクライアント
```

---

## 📋 タスク一覧

### Phase 1: MCPサーバー実装 [feature:tdd] ✅

- [x] **T1-1**: `mcp/` ディレクトリ作成と初期セットアップ
  - `package.json` 作成（@modelcontextprotocol/sdk依存）
  - TypeScript設定

- [x] **T1-2**: データ読み取りユーティリティ実装
  - `~/Library/Application Support/com.quotawatch/usage_cache.json` 読み取り
  - `~/Library/Application Support/com.quotawatch/state.json` 読み取り
  - エラーハンドリング（ファイル不存在時）

- [x] **T1-3**: MCPツール実装
  - `get_quota_status` - 現在のクォータ状態を返す
  - `get_quota_summary` - 人間が読みやすい形式でサマリーを返す

- [x] **T1-4**: ビルド・実行スクリプト
  - `npm run build` でコンパイル
  - `npm start` でSTDIO transport起動

### Phase 2: Claude Code統合 ✅

- [x] **T2-1**: Claude Code設定ファイル更新
  - `.claude/settings.json` または MCP設定に追加

- [x] **T2-2**: 動作確認
  - Claude Codeから `get_quota_status` を呼び出し
  - データが正しく返ることを確認

### Phase 3: ドキュメント ✅

- [x] **T3-1**: `mcp/README.md` 作成
  - セットアップ手順
  - 使用可能なツール一覧
  - 設定方法

---

## 🔧 提供するMCPツール

### `get_quota_status`
現在のクォータ状態を構造化データで返す。

**出力例**:
```json
{
  "providerId": "zai",
  "fetchedAt": "2026-02-16T21:00:00Z",
  "primary": {
    "title": "GLM 5h",
    "percentage": 42,
    "used": 126000,
    "total": 300000,
    "remaining": 174000
  },
  "resetAt": "2026-02-17T02:00:00Z",
  "secondary": [
    { "label": "Time Limit", "percentage": 15, "remaining": 255 }
  ]
}
```

### `get_quota_summary`
人間が読みやすい形式でサマリーを返す。

**出力例**:
```
📊 GLM 5h: 42% used (126k/300k tokens)
⏰ Resets at 2026-02-17 02:00 JST
📦 Secondary: Time Limit 15%, Monthly 8%
```

---

## 📁 ディレクトリ構成（予定）

```
QuotaWatch/
├── QuotaWatch/              # 既存SwiftUIアプリ
├── mcp/                     # MCPサーバー（新規）
│   ├── src/
│   │   ├── index.ts         # エントリーポイント
│   │   ├── tools.ts         # MCPツール定義
│   │   └── reader.ts        # JSON読み取りユーティリティ
│   ├── package.json
│   ├── tsconfig.json
│   └── README.md
└── Plans.md                 # このファイル
```

---

## ⚡ 優先度マトリックス

| 機能 | 優先度 | 理由 |
|------|--------|------|
| `get_quota_status` | **必須** | コア機能 |
| `get_quota_summary` | 推奨 | UX向上 |
| 履歴データ参照 | オプション | 将来拡張 |

---

### Phase 4: 独立型MCPサーバー（API直接版） ✅

> **目的**: Macのファイルを読まず、Z.ai APIを直接叩く版を実装
> **用途**: Windows/WSL2で常時稼働、個人用

#### 設計

**データフロー**:
```
環境変数 ZAI_API_KEY
    ↓
MCPサーバー（Windows/WSL2）
    ↓ HTTP GET
Z.ai API（https://api.z.ai/api/monitor/usage/quota/limit）
    ↓ レスポンス正規化
OpenCode / MCPクライアント
```

#### タスク

- [x] **T4-1**: APIクライアント実装
  - `fetchApi()` 関数作成
  - `Authorization` ヘッダーでAPIキー送信
  - エラーハンドリング（429, ネットワークエラー等）

- [x] **T4-2**: 環境変数対応
  - `process.env.ZAI_API_KEY` から読み取り
  - 未設定時はエラーメッセージを返す

- [x] **T4-3**: レスポンス正規化
  - APIレスポンス → `UsageSnapshot` 形式に変換
  - 既存の `tools.ts` はそのまま使えるようにする

- [x] **T4-4**: 動作確認
  - ビルド: `npm run build`
  - 実行: `ZAI_API_KEY=xxx npm start`
  - ツール呼び出し確認

- [x] **T4-5**: README更新
  - セットアップ手順（環境変数設定）
  - Windows/WSL2での使い方

---

## 🔧 提供するMCPツール

### `get_quota_status`（変更なし）
現在のクォータ状態を構造化データで返す。

### `get_quota_summary`（変更なし）
人間が読みやすい形式でサマリーを返す。

---

## 🚀 次のアクション

**Phase 4を開始**: `T4-1` APIクライアント実装から

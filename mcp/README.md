# QuotaWatch MCP Server

QuotaWatchアプリのクォータデータをMCP（Model Context Protocol）経由で公開するサーバーです。

## 機能

- `get_quota_status`: 現在のクォータ状態を構造化JSONで取得
- `get_quota_summary`: 人間が読みやすい形式でサマリーを取得

## セットアップ

### 1. 依存関係のインストール

```bash
cd mcp
npm install
```

### 2. ビルド

```bash
npm run build
```

### 3. Claude Codeへの登録

`.claude/settings.json` に以下を追加：

```json
{
  "mcpServers": {
    "quotawatch": {
      "command": "node",
      "args": ["/path/to/QuotaWatch/mcp/dist/index.js"]
    }
  }
}
```

※ パスはプロジェクトのルートディレクトリに合わせて調整してください。

## 使用可能なツール

### get_quota_status

構造化データでクォータ状態を返します。

**出力例:**
```json
{
  "success": true,
  "data": {
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
    "resetAtJST": "2026-02-17 11:00:00",
    "secondary": [
      { "label": "Time Limit", "percentage": 15, "used": 45, "total": 300, "remaining": 255 }
    ]
  },
  "state": {
    "nextFetchAt": "2026-02-16T21:05:00Z",
    "backoffFactor": 1,
    "lastFetchAt": "2026-02-16T21:00:00Z",
    "lastError": "",
    "lastKnownResetAt": "2026-02-17T02:00:00Z",
    "lastNotifiedResetAt": "2026-02-16T17:00:00Z"
  }
}
```

### get_quota_summary

人間が読みやすい形式でサマリーを返します。

**出力例:**
```
📊 GLM 5h: 42% used (126.0k/300.0k tokens)
⏰ Resets at 2026-02-17 11:00:00
📦 Secondary: Time Limit 15%, Monthly 8%
   └─ Time Limit details: Search: 30, Reader: 15
📡 Last fetched at 2026-02-17 06:00:00
```

## データソース

このMCPサーバーは以下のファイルを読み取ります：

- `~/Library/Application Support/com.quotawatch/usage_cache.json` - クォータデータ
- `~/Library/Application Support/com.quotawatch/state.json` - アプリ状態

QuotaWatchアプリが実行され、データがフェッチされている必要があります。

## 開発

```bash
# インストール
npm install

# ビルド
npm run build

# ウォッチモードでビルド
npm run watch

# 手動実行（STDIO transportが必要なため、通常はMCPクライアント経由で使用）
npm start
```

## ライセンス

MIT

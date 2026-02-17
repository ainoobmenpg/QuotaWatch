//
// tools.ts
// QuotaWatch MCP Server
//
// MCPツールの定義 - get_quota_status と get_quota_summary
//

import { Tool } from "@modelcontextprotocol/sdk/types.js";
import {
  readUsageCache,
  readState,
  epochToISOString,
  epochToJSTString,
  convertApiToUsageSnapshot,
  type UsageSnapshot,
  type AppState,
  type ReadResult,
} from "./reader.js";
import { fetchZaiApi, getApiKey } from "./api.js";

// MARK: - Tool Definitions

/** get_quota_status ツール定義 */
export const getQuotaStatusTool: Tool = {
  name: "get_quota_status",
  description:
    "Get the current quota status from QuotaWatch app. Returns structured data including usage percentage, remaining tokens, and reset time.",
  inputSchema: {
    type: "object" as const,
    properties: {},
  },
};

/** get_quota_summary ツール定義 */
export const getQuotaSummaryTool: Tool = {
  name: "get_quota_summary",
  description:
    "Get a human-readable summary of the current quota status. Formatted for easy reading.",
  inputSchema: {
    type: "object" as const,
    properties: {},
  },
};

// MARK: - Response Types

/** get_quota_status のレスポンス形式 */
export interface QuotaStatusResponse {
  success: boolean;
  data?: {
    providerId: string;
    fetchedAt: string | null;
    primary: {
      title: string;
      percentage: number | null;
      used: number | null;
      total: number | null;
      remaining: number | null;
    };
    resetAt: string | null;
    resetAtJST: string | null;
    secondary: Array<{
      label: string;
      percentage: number | null;
      used: number | null;
      total: number | null;
      remaining: number | null;
    }>;
  };
  state?: {
    nextFetchAt: string | null;
    backoffFactor: number;
    lastFetchAt: string | null;
    lastError: string;
    lastKnownResetAt: string | null;
    lastNotifiedResetAt: string | null;
  };
  error?: string;
}

// MARK: - Tool Handlers

/** get_quota_status ツールのハンドラー */
export async function handleGetQuotaStatus(): Promise<QuotaStatusResponse> {
  // APIキーチェック
  if (!getApiKey()) {
    return {
      success: false,
      error: "ZAI_API_KEY environment variable is not set. Please set it before using this tool.",
    };
  }

  // API呼び出し
  const result = await fetchZaiApi();

  if (!result.success) {
    return {
      success: false,
      error: `API Error (${result.error.type}): ${result.error.message}`,
    };
  }

  // レスポンス変換
  const limits = result.data.data?.limits ?? [];
  const usageCache = convertApiToUsageSnapshot(limits);
  const state = readState(); // stateは引き続きローカルファイルから（オプション）

  // プライマリクォータ情報
  const primary = {
    title: usageCache.primaryTitle,
    percentage: usageCache.primaryPct,
    used: usageCache.primaryUsed,
    total: usageCache.primaryTotal,
    remaining: usageCache.primaryRemaining,
  };

  // セカンダリクォータ情報
  const secondary = usageCache.secondary.map((limit) => ({
    label: limit.label,
    percentage: limit.pct,
    used: limit.used,
    total: limit.total,
    remaining: limit.remaining,
  }));

  // リセット時刻
  const resetAt = epochToISOString(usageCache.resetEpoch);
  const resetAtJST = epochToJSTString(usageCache.resetEpoch);

  // 取得時刻
  const fetchedAt = epochToISOString(usageCache.fetchedAtEpoch);

  // ステート情報（あれば）
  let stateInfo: QuotaStatusResponse["state"] | undefined;
  if (state) {
    stateInfo = {
      nextFetchAt: epochToISOString(state.fetch.nextFetchEpoch),
      backoffFactor: state.fetch.backoffFactor,
      lastFetchAt: epochToISOString(state.fetch.lastFetchEpoch),
      lastError: state.fetch.lastError,
      lastKnownResetAt: epochToISOString(state.notification.lastKnownResetEpoch),
      lastNotifiedResetAt: epochToISOString(state.notification.lastNotifiedResetEpoch),
    };
  }

  return {
    success: true,
    data: {
      providerId: usageCache.providerId,
      fetchedAt,
      primary,
      resetAt,
      resetAtJST,
      secondary,
    },
    state: stateInfo,
  };
}

/** get_quota_summary ツールのハンドラー */
export async function handleGetQuotaSummary(): Promise<{ content: string }> {
  // APIキーチェック
  if (!getApiKey()) {
    return {
      content: "⚠️ ZAI_API_KEY environment variable is not set.",
    };
  }

  // API呼び出し
  const result = await fetchZaiApi();

  if (!result.success) {
    return {
      content: `⚠️ API Error (${result.error.type}): ${result.error.message}`,
    };
  }

  // レスポンス変換
  const limits = result.data.data?.limits ?? [];
  const usageCache = convertApiToUsageSnapshot(limits);

  const lines: string[] = [];

  // プライマリクォータ
  const pct = usageCache.primaryPct ?? 0;
  const used = usageCache.primaryUsed ?? 0;
  const total = usageCache.primaryTotal ?? 0;
  lines.push(`📊 ${usageCache.primaryTitle}: ${pct}% used (${formatNumber(used)}/${formatNumber(total)} tokens)`);

  // リセット時刻
  const resetAtJST = epochToJSTString(usageCache.resetEpoch);
  if (resetAtJST) {
    lines.push(`⏰ Resets at ${resetAtJST}`);
  }

  // セカンダリクォータ
  if (usageCache.secondary.length > 0) {
    const secondaryParts: string[] = [];
    for (const limit of usageCache.secondary) {
      const limitPct = limit.pct ?? 0;
      secondaryParts.push(`${limit.label} ${limitPct}%`);
    }
    lines.push(`📦 Secondary: ${secondaryParts.join(", ")}`);

    // 使用量内訳がある場合の詳細表示
    for (const limit of usageCache.secondary) {
      if (limit.usageDetails && limit.usageDetails.length > 0) {
        const detailParts = limit.usageDetails.map(
          (d) => `${formatModelCode(d.modelCode)}: ${d.usage}`
        );
        lines.push(`   └─ ${limit.label} details: ${detailParts.join(", ")}`);
      }
    }
  }

  // 取得時刻
  const fetchedAtJST = epochToJSTString(usageCache.fetchedAtEpoch);
  if (fetchedAtJST) {
    lines.push(`📡 Last fetched at ${fetchedAtJST}`);
  }

  return {
    content: lines.join("\n"),
  };
}

// MARK: - Utilities

/** 数値を読みやすい形式にフォーマット（k/M suffix） */
function formatNumber(num: number): string {
  if (num >= 1_000_000) {
    return `${(num / 1_000_000).toFixed(1)}M`;
  }
  if (num >= 1_000) {
    return `${(num / 1_000).toFixed(1)}k`;
  }
  return num.toString();
}

/** モデルコードを読みやすいラベルに変換 */
function formatModelCode(code: string): string {
  const lower = code.toLowerCase();
  switch (lower) {
    case "search-prime":
      return "Search";
    case "web-reader":
      return "Reader";
    case "zread":
      return "Zread";
    default:
      return code;
  }
}

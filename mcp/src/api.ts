//
// api.ts
// QuotaWatch MCP Server
//
// Z.ai APIを直接叩くクライアント
//

// MARK: - Type Definitions

/** Z.ai API の生レスポンス形式 */
export interface ZaiApiResponse {
  code: number;
  data?: {
    limits: ZaiApiLimit[];
  };
  error?: {
    code: number;
    message: string;
  };
  errorCode?: number;
}

/** Z.ai API の limit エントリ */
export interface ZaiApiLimit {
  type: string;
  percentage?: number;
  usage: number;
  number: number;
  remaining: number;
  nextResetTime: number | string; // epoch秒 または ISO文字列
}

/** APIエラー情報 */
export interface ApiError {
  type: "network" | "rate_limit" | "auth" | "server" | "parse" | "config";
  message: string;
  code?: number;
}

// MARK: - Constants

const ZAI_API_URL = "https://api.z.ai/api/monitor/usage/quota/limit";
const REQUEST_TIMEOUT_MS = 10000;

// レート制限エラーコード
const RATE_LIMIT_CODES = new Set([1302, 1303, 1305]);

// MARK: - API Client

/** 環境変数からAPIキーを取得 */
export function getApiKey(): string | null {
  return process.env.ZAI_API_KEY ?? null;
}

/** Z.ai APIを叩いてクォータ情報を取得 */
export async function fetchZaiApi(): Promise<
  { success: true; data: ZaiApiResponse } | { success: false; error: ApiError }
> {
  // APIキーチェック
  const apiKey = getApiKey();
  if (!apiKey) {
    return {
      success: false,
      error: {
        type: "config",
        message: "ZAI_API_KEY environment variable is not set",
      },
    };
  }

  // リクエスト実行
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  try {
    const response = await fetch(ZAI_API_URL, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        Accept: "application/json",
      },
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    // HTTPステータスチェック
    if (response.status === 401 || response.status === 403) {
      return {
        success: false,
        error: {
          type: "auth",
          message: `Authentication failed: ${response.status}`,
          code: response.status,
        },
      };
    }

    if (response.status === 429) {
      return {
        success: false,
        error: {
          type: "rate_limit",
          message: "Rate limited (HTTP 429)",
          code: 429,
        },
      };
    }

    if (!response.ok) {
      return {
        success: false,
        error: {
          type: "server",
          message: `Server error: ${response.status}`,
          code: response.status,
        },
      };
    }

    // JSONパース
    let data: ZaiApiResponse;
    try {
      data = (await response.json()) as ZaiApiResponse;
    } catch {
      return {
        success: false,
        error: {
          type: "parse",
          message: "Failed to parse JSON response",
        },
      };
    }

    // APIレート制限コードチェック
    const apiCode = data.code ?? data.errorCode ?? data.error?.code;
    if (apiCode !== undefined && RATE_LIMIT_CODES.has(apiCode)) {
      return {
        success: false,
        error: {
          type: "rate_limit",
          message: `Rate limited (code ${apiCode})`,
          code: apiCode,
        },
      };
    }

    // 成功
    return { success: true, data };
  } catch (error) {
    clearTimeout(timeoutId);

    if (error instanceof Error) {
      if (error.name === "AbortError") {
        return {
          success: false,
          error: {
            type: "network",
            message: "Request timeout",
          },
        };
      }
      return {
        success: false,
        error: {
          type: "network",
          message: error.message,
        },
      };
    }

    return {
      success: false,
      error: {
        type: "network",
        message: "Unknown network error",
      },
    };
  }
}

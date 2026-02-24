//
//  MiniMaxProvider.swift
//  QuotaWatch
//
//  MiniMax Coding Plan API Provider implementation
//

import Foundation
import OSLog

/// MiniMax Coding Plan API Provider implementation
public struct MiniMaxProvider: Provider {
    private static let logger = Logger(
        subsystem: "com.quotawatch.provider",
        category: "MiniMaxProvider"
    )

    // MARK: - Provider Conformance

    public let id = "minimax"
    public let displayName = "MiniMax"
    public let dashboardURL = URL(string: "https://platform.minimax.io/user-center/payment/coding-plan")
    public let keychainService = "minimax_api_key"

    // MARK: - Configuration

    private static let baseURL = "https://www.minimax.io"
    private static let endpoint = "/v1/api/openplatform/coding_plan/remains"
    private static let timeout: TimeInterval = 10.0

    public init() {}

    // MARK: - Provider Protocol

    public func fetchUsage(apiKey: String) async throws -> UsageSnapshot {
        guard let url = URL(string: Self.baseURL + Self.endpoint) else {
            Self.logger.error("Invalid URL")
            throw ProviderError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = Self.timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        Self.logger.debug("Fetching: \(url)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                Self.logger.error("Invalid response")
                throw ProviderError.invalidResponse
            }

            Self.logger.debug("HTTP status: \(httpResponse.statusCode)")

            // HTTP status code check
            if httpResponse.statusCode != 200 {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    Self.logger.error("Unauthorized: \(httpResponse.statusCode)")
                    throw ProviderError.unauthorized
                }
                if httpResponse.statusCode == 429 {
                    Self.logger.error("Rate limited: HTTP 429")
                    throw ProviderError.httpError(statusCode: 429)
                }
                Self.logger.error("HTTP error: \(httpResponse.statusCode)")
                throw ProviderError.httpError(statusCode: httpResponse.statusCode)
            }

            // Debug: log received data
            if let dataString = String(data: data, encoding: .utf8) {
                Self.logger.debug("Received data (first 500 chars): \(dataString.prefix(500))")
            }

            // Decode JSON
            let miniMaxResponse = try JSONDecoder().decode(MiniMaxRemainsResponse.self, from: data)

            // Check response success (some APIs don't return success field, so we check modelRemains instead)
            guard let modelRemains = miniMaxResponse.modelRemains, !modelRemains.isEmpty else {
                Self.logger.error("API error: no model_remains in response")
                throw ProviderError.invalidResponse
            }

            // Use first model remain
            let remain = modelRemains[0]

            // Convert to UsageSnapshot
            let snapshot = UsageSnapshot(from: remain, providerId: self.id)

            Self.logger.log("Fetch success: \(snapshot.primaryTitle)")
            return snapshot

        } catch let error as ProviderError {
            throw error
        } catch let error as DecodingError {
            Self.logger.error("Decoding error: \(error)")
            throw ProviderError.decodingError(underlying: error)
        } catch {
            Self.logger.error("Network error: \(error)")
            throw ProviderError.networkError(underlying: error)
        }
    }

    public func classifyBackoff(error: ProviderError) -> BackoffDecision {
        switch error {
        case .httpError(let statusCode) where statusCode == 429:
            Self.logger.warning("Rate limit detected: HTTP 429")
            return .backoff()

        case .networkError, .decodingError:
            Self.logger.debug("Non-rate error: normal retry")
            return .proceed()

        case .unauthorized, .quotaNotAvailable, .invalidResponse:
            Self.logger.error("Fatal error: \(error)")
            return BackoffDecision(
                action: .stop,
                isRetryable: false,
                description: error.localizedDescription
            )

        case .unknown:
            return .proceed()

        default:
            return .proceed()
        }
    }
}

// MARK: - MiniMax API Response Models

/// MiniMax Coding Plan remains API response
public struct MiniMaxRemainsResponse: Codable, Sendable {
    public let success: Bool?
    public let modelRemains: [MiniMaxModelRemain]?

    enum CodingKeys: String, CodingKey {
        case success
        case modelRemains = "model_remains"
    }

    public init(success: Bool?, modelRemains: [MiniMaxModelRemain]?) {
        self.success = success
        self.modelRemains = modelRemains
    }
}

/// MiniMax model remain data
public struct MiniMaxModelRemain: Codable, Sendable {
    public let endTime: Int64
    public let currentIntervalTotalCount: Int
    public let currentIntervalUsageCount: Int
    public let modelName: String

    enum CodingKeys: String, CodingKey {
        case endTime = "end_time"
        case currentIntervalTotalCount = "current_interval_total_count"
        case currentIntervalUsageCount = "current_interval_usage_count"
        case modelName = "model_name"
    }

    public init(
        endTime: Int64,
        currentIntervalTotalCount: Int,
        currentIntervalUsageCount: Int,
        modelName: String
    ) {
        self.endTime = endTime
        self.currentIntervalTotalCount = currentIntervalTotalCount
        self.currentIntervalUsageCount = currentIntervalUsageCount
        self.modelName = modelName
    }
}

// MARK: - UsageSnapshot Extension for MiniMax

extension UsageSnapshot {
    /// Create UsageSnapshot from MiniMax model remain data
    ///
    /// - Parameters:
    ///   - remain: MiniMax API response data
    ///   - providerId: Provider identifier (default: "minimax")
    init(from remain: MiniMaxModelRemain, providerId: String = "minimax") {
        let fetchedAtEpoch = Int(Date().timeIntervalSince1970)

        // Calculate usage from API response fields
        // Note: current_interval_usage_count is actually the REMAINING count, not used
        let total = Double(remain.currentIntervalTotalCount)
        let remaining = Double(remain.currentIntervalUsageCount)
        let used = total - remaining

        // Calculate percentage
        let pct: Int?
        if total > 0 {
            pct = Int(floor(100 * used / total))
        } else {
            pct = nil
        }

        // Convert endTime from milliseconds to epoch seconds
        let resetEpoch = Int(remain.endTime / 1000)

        self.init(
            providerId: providerId,
            fetchedAtEpoch: fetchedAtEpoch,
            primaryTitle: remain.modelName,
            primaryPct: pct,
            primaryUsed: used,
            primaryTotal: total,
            primaryRemaining: remaining,
            resetEpoch: resetEpoch,
            secondary: [],
            rawDebugJson: nil
        )
    }
}

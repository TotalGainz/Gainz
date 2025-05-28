//
//  HTTPMethod.swift
//  CoreNetworking
//
//  Compact, type-safe representation of HTTP verbs for Gainz API calls.
//  Designed for extensibility (custom verbs) and Swift Concurrency.
//
//  ───────────── Mission Invariants ─────────────
//  • Foundation-only import (platform-agnostic).
//  • Raw value ≡ the exact wire-protocol verb (uppercase).
//  • Codable + Sendable for async transport across tasks.
//  • Provides `allowsRequestBody` convenience flag.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation

/// HTTP verb recognised by the Gainz backend.
/// Extend via `extension HTTPMethod { static let foo = HTTPMethod(rawValue: "FOO") }`
/// if the server adopts custom semantics.
public struct HTTPMethod: RawRepresentable, Hashable, Codable, Sendable {

    // Underlying verb string exactly as sent on the wire (e.g., “POST”).
    public let rawValue: String

    // MARK: Canonical Verbs
    public static let get     = HTTPMethod(rawValue: "GET")
    public static let head    = HTTPMethod(rawValue: "HEAD")
    public static let post    = HTTPMethod(rawValue: "POST")
    public static let put     = HTTPMethod(rawValue: "PUT")
    public static let patch   = HTTPMethod(rawValue: "PATCH")
    public static let delete  = HTTPMethod(rawValue: "DELETE")
    public static let options = HTTPMethod(rawValue: "OPTIONS")

    // MARK: - Initialiser

    public init(rawValue: String) {
        precondition(!rawValue.isEmpty, "HTTPMethod cannot be empty")
        self.rawValue = rawValue.uppercased()
    }

    // MARK: - Helpers

    /// `true` when the verb typically carries a request body.
    public var allowsRequestBody: Bool {
        switch self {
        case .post, .put, .patch:
            return true
        default:
            return false
        }
    }

    /// Commonly idempotent verbs (GET, HEAD, PUT, DELETE, OPTIONS).
    public var isIdempotent: Bool {
        switch self {
        case .get, .head, .put, .delete, .options:
            return true
        default:
            return false
        }
    }
}

// MARK: - CustomStringConvertible

extension HTTPMethod: CustomStringConvertible {
    public var description: String { rawValue }
}

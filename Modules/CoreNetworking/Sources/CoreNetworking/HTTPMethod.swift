// HTTPMethod.swift
// CoreNetworking
//
// Minimal set of HTTP verbs supported by the Gainz backend.

import Foundation

/// HTTP methods used by Gainz API endpoints.
public enum HTTPMethod: String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case patch  = "PATCH"
    case delete = "DELETE"
}

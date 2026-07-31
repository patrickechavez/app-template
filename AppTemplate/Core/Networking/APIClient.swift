//
//  APIClient.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case server(status: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .server(_, let message):
            return message ?? "Something went wrong. Please try again."
        }
    }
}

protocol APIClient {
    func get<T: Decodable>(_ path: String, query: [URLQueryItem]) async throws -> T
    func post<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T
    func upload<T: Decodable>(_ path: String, multipart: MultipartFormData) async throws -> T
}

extension APIClient {
    // Convenience for a GET without query parameters.
    func get<T: Decodable>(_ path: String) async throws -> T {
        try await get(path, query: [])
    }
}

final class URLSessionAPIClient: APIClient {
    private let baseURL: URL
    private let tokenStore: TokenStore
    private let metadata: RequestMetadataProviding
    private let session: URLSession
    private let encoder = JSONEncoder.api
    private let decoder = JSONDecoder.api

    init(baseURL: URL,
         tokenStore: TokenStore,
         metadata: RequestMetadataProviding = ClientMetadata(),
         session: URLSession = .shared) {
        self.baseURL = baseURL
        self.tokenStore = tokenStore
        self.metadata = metadata
        self.session = session
    }

    func get<T: Decodable>(_ path: String, query: [URLQueryItem]) async throws -> T {
        try await send(path, method: "GET", query: query, body: nil)
    }

    func post<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        try await send(path, method: "POST", body: try encoder.encode(body))
    }

    func upload<T: Decodable>(_ path: String, multipart: MultipartFormData) async throws -> T {
        try await send(path,
                       method: "POST",
                       body: multipart.encoded(),
                       contentType: multipart.contentType)
    }

    private func send<T: Decodable>(_ path: String,
                                    method: String,
                                    query: [URLQueryItem] = [],
                                    body: Data?,
                                    contentType: String? = nil) async throws -> T {
        var url = baseURL.appendingPathComponent(path)
        if !query.isEmpty {
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw APIError.invalidResponse
            }
            components.queryItems = query
            guard let composed = components.url else { throw APIError.invalidResponse }
            url = composed
        }
        var request = URLRequest(url: url)
        request.httpMethod = method

        // App + device metadata on every request.
        for (field, value) in metadata.headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        if let body {
            request.httpBody = body
            request.setValue(contentType ?? "application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token = tokenStore.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        switch http.statusCode {
        case 200..<300:
            return try decoder.decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.server(status: http.statusCode, message: nil)
        }
    }
}

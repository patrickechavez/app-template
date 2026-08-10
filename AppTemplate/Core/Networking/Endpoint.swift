//
//  Endpoint.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

enum HTTPBody: Sendable, Equatable {
    case data(Data, contentType: String)

    static func json(_ value: some Encodable) throws -> HTTPBody {
        .data(try JSONEncoder.api.encode(value), contentType: "application/json")
    }

    static func multipart(_ form: MultipartFormData) -> HTTPBody {
        .data(form.encoded(), contentType: form.contentType)
    }

    var data: Data {
        switch self {
        case let .data(data, _): data
        }
    }

    var contentType: String {
        switch self {
        case let .data(_, contentType): contentType
        }
    }
}

struct Endpoint: Sendable, Equatable {

    var path: String

    var method: HTTPMethod = .get

    var query: [URLQueryItem] = []

    var headers: [String: String] = [:]

    var body: HTTPBody?

    var requiresAuth: Bool = true

    var timeout: TimeInterval?

    init(
        _ path: String,
        method: HTTPMethod = .get,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: HTTPBody? = nil,
        requiresAuth: Bool = true,
        timeout: TimeInterval? = nil
    ) {
        self.path = path
        self.method = method
        self.query = query
        self.headers = headers
        self.body = body
        self.requiresAuth = requiresAuth
        self.timeout = timeout
    }

    func urlRequest(baseURL: URL, defaultTimeout: TimeInterval) throws -> URLRequest {

        var url = baseURL
        for component in path.split(separator: "/") where !component.isEmpty {
            url.appendPathComponent(String(component))
        }

        if !query.isEmpty {
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw APIError.invalidURL
            }
            components.queryItems = query
            guard let composed = components.url else { throw APIError.invalidURL }
            url = composed
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeout ?? defaultTimeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = body.data
            request.setValue(body.contentType, forHTTPHeaderField: "Content-Type")
        }

        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        return request
    }
}

extension Endpoint {

    static func get(_ path: String, query: [URLQueryItem] = [], requiresAuth: Bool = true) -> Endpoint {
        Endpoint(path, method: .get, query: query, requiresAuth: requiresAuth)
    }

    static func post(_ path: String, body: some Encodable, requiresAuth: Bool = true) throws -> Endpoint {
        Endpoint(path, method: .post, body: try .json(body), requiresAuth: requiresAuth)
    }

    static func put(_ path: String, body: some Encodable, requiresAuth: Bool = true) throws -> Endpoint {
        Endpoint(path, method: .put, body: try .json(body), requiresAuth: requiresAuth)
    }

    static func patch(_ path: String, body: some Encodable, requiresAuth: Bool = true) throws -> Endpoint {
        Endpoint(path, method: .patch, body: try .json(body), requiresAuth: requiresAuth)
    }

    static func delete(_ path: String, requiresAuth: Bool = true) -> Endpoint {
        Endpoint(path, method: .delete, requiresAuth: requiresAuth)
    }

    static func upload(
        _ path: String,
        form: MultipartFormData,
        method: HTTPMethod = .post,
        requiresAuth: Bool = true
    ) -> Endpoint {
        Endpoint(
            path,
            method: method,
            body: .multipart(form),
            requiresAuth: requiresAuth,
            timeout: 120
        )
    }
}

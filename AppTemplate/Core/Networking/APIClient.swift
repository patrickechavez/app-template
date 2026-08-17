//
//  APIClient.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import os

struct EmptyResponse: Decodable, Sendable, Equatable {
    init() {}
    init(from decoder: any Decoder) throws { self.init() }
}

protocol APIClient: Sendable {
    func send<T: Decodable & Sendable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T
}

extension APIClient {

    func send<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        try await send(endpoint, as: T.self)
    }

    func send(_ endpoint: Endpoint) async throws {
        _ = try await send(endpoint, as: EmptyResponse.self)
    }

    func get<T: Decodable & Sendable>(
        _ path: String,
        query: [URLQueryItem] = [],
        requiresAuth: Bool = true
    ) async throws -> T {
        try await send(.get(path, query: query, requiresAuth: requiresAuth), as: T.self)
    }

    func post<T: Decodable & Sendable>(
        _ path: String,
        body: some Encodable,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await send(try .post(path, body: body, requiresAuth: requiresAuth), as: T.self)
    }

    func post(_ path: String, body: some Encodable, requiresAuth: Bool = true) async throws {
        _ = try await send(try .post(path, body: body, requiresAuth: requiresAuth), as: EmptyResponse.self)
    }

    func put<T: Decodable & Sendable>(
        _ path: String,
        body: some Encodable,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await send(try .put(path, body: body, requiresAuth: requiresAuth), as: T.self)
    }

    func patch<T: Decodable & Sendable>(
        _ path: String,
        body: some Encodable,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await send(try .patch(path, body: body, requiresAuth: requiresAuth), as: T.self)
    }

    func delete(_ path: String, requiresAuth: Bool = true) async throws {
        _ = try await send(.delete(path, requiresAuth: requiresAuth), as: EmptyResponse.self)
    }

    func upload<T: Decodable & Sendable>(
        _ path: String,
        form: MultipartFormData,
        method: HTTPMethod = .post,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await send(.upload(path, form: form, method: method, requiresAuth: requiresAuth), as: T.self)
    }
}

nonisolated final class URLSessionAPIClient: APIClient {

    private let baseURL: URL
    private let session: URLSession
    private let interceptors: [any RequestInterceptor]
    private let retryPolicy: RetryPolicy
    private let defaultTimeout: TimeInterval

    private static let maxInterceptorRetries = 1

    init(
        baseURL: URL = APIConfig.baseURL,
        session: URLSession = .shared,
        interceptors: [any RequestInterceptor] = [],
        retryPolicy: RetryPolicy = APIConfig.retryPolicy,
        defaultTimeout: TimeInterval = APIConfig.timeout
    ) {
        self.baseURL = baseURL
        self.session = session
        self.interceptors = interceptors
        self.retryPolicy = retryPolicy
        self.defaultTimeout = defaultTimeout
    }

    func send<T: Decodable & Sendable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let data = try await perform(endpoint)

        if data.isEmpty || data.count <= 2 {
            if let empty = EmptyResponse() as? T { return empty }
        }

        do {
            return try JSONDecoder.api.decode(T.self, from: data)
        } catch {

            let detail = Self.describe(decodingError: error, type: T.self)
            AppLogger.network.error(
                "Decoding failed for \(endpoint.path, privacy: .public): \(detail, privacy: .public)"
            )
            throw APIError.decodingFailed(detail: detail)
        }
    }

    private func perform(_ endpoint: Endpoint) async throws -> Data {
        var attempt = 0
        var interceptorRetries = 0

        while true {
            attempt += 1

            try Task.checkCancellation()

            let apiError: APIError
            do {

                return try await attemptOnce(endpoint)
            } catch let error as APIError {
                apiError = error
            } catch {
                apiError = APIError.from(transportError: error)
            }

            if apiError == .cancelled { throw apiError }

            switch await recoveryDecision(for: apiError, endpoint: endpoint, attempt: attempt) {
            case let .fail(replacement):
                throw replacement

            case .retry:
                guard interceptorRetries < Self.maxInterceptorRetries else {
                    AppLogger.network.error(
                        "Giving up on \(endpoint.path, privacy: .public): recovery did not resolve the failure"
                    )
                    throw apiError
                }
                interceptorRetries += 1

                continue

            case .proceed:
                break
            }

            guard retryPolicy.shouldRetry(
                apiError,
                attempt: attempt,
                method: endpoint.method,
                sentBody: endpoint.body != nil
            ) else {
                throw apiError
            }

            let delay = retryPolicy.delay(afterAttempt: attempt, error: apiError)
            AppLogger.network.debug(
                """
                Retrying \(endpoint.method.rawValue, privacy: .public) \
                \(endpoint.path, privacy: .public) after \(delay.seconds, privacy: .public)s \
                (attempt \(attempt + 1, privacy: .public))
                """
            )
            try await Task.sleep(for: delay)
        }
    }

    private func attemptOnce(_ endpoint: Endpoint) async throws -> Data {
        var request = try endpoint.urlRequest(baseURL: baseURL, defaultTimeout: defaultTimeout)
        for interceptor in interceptors {
            request = try await interceptor.adapt(request, for: endpoint)
        }

        let (data, response) = try await data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        for interceptor in interceptors {
            await interceptor.didReceive(http, data: data, for: endpoint)
        }

        guard !(200..<300).contains(http.statusCode) else {
            return data
        }

        throw APIError.from(
            statusCode: http.statusCode,
            data: data,
            headers: http.allHeaderFields
        )
    }

    /// Runs a request through the session's delegate so certificate-pinning
    /// server-trust challenges reach `CertificatePinner`. `session.data(for:)`
    /// would bypass the delegate, so a completion-handler task is bridged with
    /// a continuation instead.
    private func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let box = DataTaskBox()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let dataTask = session.dataTask(with: request) { data, response, error in
                    if let error {

                        // A cancellation we didn't ask for came from the pinner
                        // rejecting the server, which cancels the challenge.
                        let isPinRejection = (error as? URLError)?.code == .cancelled
                            && !box.wasCancelled
                        continuation.resume(throwing: isPinRejection ? APIError.serverTrustFailed : error)
                    } else if let data, let response {
                        continuation.resume(returning: (data, response))
                    } else {
                        continuation.resume(throwing: APIError.invalidResponse)
                    }
                }
                box.store(dataTask)
                dataTask.resume()
            }
        } onCancel: {
            box.cancel()
        }
    }

    private func recoveryDecision(
        for error: APIError,
        endpoint: Endpoint,
        attempt: Int
    ) async -> InterceptorDecision {
        for interceptor in interceptors {
            let decision = await interceptor.handle(error, for: endpoint, attempt: attempt)
            if decision != .proceed { return decision }
        }
        return .proceed
    }

    private static func describe(decodingError error: any Error, type: Any.Type) -> String {
        guard let error = error as? DecodingError else {
            return "\(type): \(error.localizedDescription)"
        }

        func path(_ context: DecodingError.Context) -> String {
            let keys = context.codingPath.map(\.stringValue)
            return keys.isEmpty ? "<root>" : keys.joined(separator: ".")
        }

        return switch error {
        case let .keyNotFound(key, context):
            "\(type): missing key '\(key.stringValue)' at \(path(context))"
        case let .typeMismatch(expected, context):
            "\(type): expected \(expected) at \(path(context))"
        case let .valueNotFound(expected, context):
            "\(type): null value for non-optional \(expected) at \(path(context))"
        case let .dataCorrupted(context):
            "\(type): corrupted data at \(path(context)) — \(context.debugDescription)"
        @unknown default:
            "\(type): \(error.localizedDescription)"
        }
    }
}

/// Holds the in-flight data task so the surrounding async task can cancel it.
/// `onCancel` runs on any thread and can arrive before the task exists, so the
/// cancellation is remembered and applied on arrival.
private final class DataTaskBox: Sendable {

    private struct State {
        var task: URLSessionDataTask?
        var isCancelled = false
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    /// Whether the surrounding async task cancelled this request. A cancellation
    /// that didn't come from here came from the session delegate.
    var wasCancelled: Bool {
        state.withLock { $0.isCancelled }
    }

    func store(_ task: URLSessionDataTask) {
        let alreadyCancelled = state.withLock { state in
            state.task = task
            return state.isCancelled
        }
        if alreadyCancelled { task.cancel() }
    }

    func cancel() {
        let task = state.withLock { state in
            state.isCancelled = true
            return state.task
        }
        task?.cancel()
    }
}

private extension Duration {

    var seconds: Double {
        Double(components.seconds) + Double(components.attoseconds) / 1e18
    }
}

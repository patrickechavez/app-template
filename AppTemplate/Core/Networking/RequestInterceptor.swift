//
//  RequestInterceptor.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

enum InterceptorDecision: Sendable, Equatable {

    case proceed

    case retry

    case fail(APIError)
}

protocol RequestInterceptor: Sendable {

    func adapt(_ request: URLRequest, for endpoint: Endpoint) async throws -> URLRequest

    func didReceive(_ response: HTTPURLResponse, data: Data, for endpoint: Endpoint) async

    func handle(_ error: APIError, for endpoint: Endpoint, attempt: Int) async -> InterceptorDecision
}

extension RequestInterceptor {

    func adapt(_ request: URLRequest, for endpoint: Endpoint) async throws -> URLRequest {
        request
    }

    func didReceive(_ response: HTTPURLResponse, data: Data, for endpoint: Endpoint) async {}

    func handle(_ error: APIError, for endpoint: Endpoint, attempt: Int) async -> InterceptorDecision {
        .proceed
    }
}

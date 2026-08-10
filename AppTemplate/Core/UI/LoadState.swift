//
//  LoadState.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

enum LoadState<Value: Sendable>: Sendable {

    case idle

    case loading

    case loaded(Value)

    case empty

    case failed(APIError)

    var value: Value? {
        if case let .loaded(value) = self { return value }
        return nil
    }

    var error: APIError? {
        if case let .failed(error) = self { return error }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isSettled: Bool {
        switch self {
        case .idle, .loading: false
        case .loaded, .empty, .failed: true
        }
    }

    var needsLoad: Bool {
        if case .idle = self { return true }
        return false
    }

    func map<T>(_ transform: (Value) -> T) -> LoadState<T> {
        switch self {
        case .idle: .idle
        case .loading: .loading
        case let .loaded(value): .loaded(transform(value))
        case .empty: .empty
        case let .failed(error): .failed(error)
        }
    }
}

extension LoadState: Equatable where Value: Equatable {}

extension LoadState {

    static func from(_ value: Value, isEmpty: (Value) -> Bool) -> LoadState {
        isEmpty(value) ? .empty : .loaded(value)
    }
}

extension LoadState where Value: Collection {

    static func from(_ value: Value) -> LoadState {
        value.isEmpty ? .empty : .loaded(value)
    }
}

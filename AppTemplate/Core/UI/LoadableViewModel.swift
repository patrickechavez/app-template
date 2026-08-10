//
//  LoadableViewModel.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

@MainActor
protocol LoadableViewModel: AnyObject {
    associatedtype Value: Sendable
    var state: LoadState<Value> { get set }
}

extension LoadableViewModel {

    func perform(
        isRefresh: Bool = false,
        isEmpty: @escaping (Value) -> Bool = { _ in false },
        _ operation: @Sendable () async throws -> Value
    ) async {
        if !isRefresh, state.value == nil {
            state = .loading
        }

        do {
            let value = try await operation()

            try Task.checkCancellation()
            state = .from(value, isEmpty: isEmpty)
        } catch {
            let apiError = error as? APIError ?? APIError.from(transportError: error)

            guard apiError.isUserFacing else { return }

            if isRefresh, state.value != nil { return }

            state = .failed(apiError)
        }
    }
}

extension LoadableViewModel where Value: Collection {

    func perform(isRefresh: Bool = false, _ operation: @Sendable () async throws -> Value) async {
        await perform(isRefresh: isRefresh, isEmpty: { $0.isEmpty }, operation)
    }
}

@Observable
@MainActor
final class ActionState {

    private(set) var isRunning = false
    private(set) var error: APIError?

    var fieldErrors: [String: [String]] {
        error?.validationErrors?.fields ?? [:]
    }

    var errorMessage: String? {
        error?.localizedDescription
    }

    func message(for field: String) -> String? {
        error?.validationErrors?.first(for: field)
    }

    func clear() {
        error = nil
    }

    @discardableResult
    func run<T>(_ operation: @Sendable () async throws -> T) async -> T? {
        guard !isRunning else { return nil }

        error = nil
        isRunning = true
        defer { isRunning = false }

        do {
            return try await operation()
        } catch {
            let apiError = error as? APIError ?? APIError.from(transportError: error)
            guard apiError.isUserFacing else { return nil }
            self.error = apiError
            return nil
        }
    }
}

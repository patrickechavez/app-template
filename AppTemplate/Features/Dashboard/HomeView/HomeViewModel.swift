//
//  HomeViewModel.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    private(set) var products: [Product] = []
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored private let repository: ProductRepository

    init(repository: ProductRepository) {
        self.repository = repository
    }

    func load() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await repository.products()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

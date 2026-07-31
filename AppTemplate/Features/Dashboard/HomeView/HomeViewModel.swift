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
    private(set) var items: [Item] = []
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored private let repository: ItemRepository

    init(repository: ItemRepository) {
        self.repository = repository
    }

    func load() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await repository.items()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

//
//  ItemDetailViewModel.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class ItemDetailViewModel {
    private(set) var item: Item

    @ObservationIgnored private let repository: ItemRepository

    init(item: Item, repository: ItemRepository) {
        self.item = item
        self.repository = repository
    }

    func refresh() async {
        // Fetch the full detail; ignore errors and keep showing what we have.
        if let fresh = try? await repository.item(id: item.id) {
            item = fresh
        }
    }
}

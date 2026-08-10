//
//  ItemDetailViewModel.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class ItemDetailViewModel: LoadableViewModel {

    var state: LoadState<Item> = .idle

    @ObservationIgnored private let itemID: Int
    @ObservationIgnored private let repository: any ItemRepository

    init(item: Item, repository: any ItemRepository) {
        self.itemID = item.id
        self.repository = repository
        self.state = .loaded(item)
    }

    init(itemID: Int, repository: any ItemRepository) {
        self.itemID = itemID
        self.repository = repository
    }

    func load(isRefresh: Bool = false) async {
        await perform(isRefresh: isRefresh || state.value != nil) { [repository, itemID] in
            try await repository.item(id: itemID)
        }
    }
}

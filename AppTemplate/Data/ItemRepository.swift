//
//  ItemRepository.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

protocol ItemRepository {
    func items() async throws -> [Item]
    func item(id: Int) async throws -> Item
}

final class LiveItemRepository: ItemRepository {
    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func items() async throws -> [Item] {
        let response: ItemListResponse = try await api.get(
            Endpoints.items,
            query: [URLQueryItem(name: "limit", value: "20")]
        )
        return response.items
    }

    func item(id: Int) async throws -> Item {
        try await api.get(Endpoints.item(id))
    }
}

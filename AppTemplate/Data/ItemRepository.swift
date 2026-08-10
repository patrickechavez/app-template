//
//  ItemRepository.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

protocol ItemRepository: Sendable {
    func items(_ request: PageRequest) async throws -> Page<Item>
    func search(_ term: String, page: PageRequest) async throws -> Page<Item>
    func item(id: Int) async throws -> Item
    func create(_ draft: ItemDraft) async throws -> Item
    func update(id: Int, draft: ItemDraft) async throws -> Item
    func delete(id: Int) async throws
}

extension ItemRepository {

    func items() async throws -> Page<Item> {
        try await items(.first)
    }
}

nonisolated struct LiveItemRepository: ItemRepository {

    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    func items(_ request: PageRequest) async throws -> Page<Item> {
        try await api.get(APIRoute.Items.list, query: request.queryItems)
    }

    func search(_ term: String, page: PageRequest) async throws -> Page<Item> {
        var query = page.queryItems
        query.append(URLQueryItem(name: "q", value: term))
        return try await api.get(APIRoute.Items.search, query: query)
    }

    func item(id: Int) async throws -> Item {
        try await api.get(APIRoute.Items.detail(id))
    }

    func create(_ draft: ItemDraft) async throws -> Item {
        try await api.post(APIRoute.Items.list, body: draft)
    }

    func update(id: Int, draft: ItemDraft) async throws -> Item {
        try await api.patch(APIRoute.Items.detail(id), body: draft)
    }

    func delete(id: Int) async throws {
        try await api.delete(APIRoute.Items.detail(id))
    }
}

//
//  ProductRepository.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

protocol ProductRepository {
    func products() async throws -> [Product]
    func product(id: Int) async throws -> Product
}

final class LiveProductRepository: ProductRepository {
    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func products() async throws -> [Product] {
        let response: ProductsResponse = try await api.get("products?limit=20")
        return response.products
    }

    func product(id: Int) async throws -> Product {
        try await api.get("products/\(id)")
    }
}

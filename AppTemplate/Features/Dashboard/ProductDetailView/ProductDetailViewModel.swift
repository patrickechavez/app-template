//
//  ProductDetailViewModel.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class ProductDetailViewModel {
    private(set) var product: Product

    @ObservationIgnored private let repository: ProductRepository

    init(product: Product, repository: ProductRepository) {
        self.product = product
        self.repository = repository
    }

    func refresh() async {
        // Fetch the full detail; ignore errors and keep showing what we have.
        if let fresh = try? await repository.product(id: product.id) {
            product = fresh
        }
    }
}

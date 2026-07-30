//
//  ProductDetailView.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct ProductDetailView: View {
    @State private var viewModel: ProductDetailViewModel

    init(viewModel: ProductDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: viewModel.product.thumbnail.flatMap(URL.init)) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.secondary.opacity(0.15)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(viewModel.product.price, format: .currency(code: "USD"))
                    .font(.title2).bold()

                Text(viewModel.product.description)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(viewModel.product.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.refresh() }
    }
}

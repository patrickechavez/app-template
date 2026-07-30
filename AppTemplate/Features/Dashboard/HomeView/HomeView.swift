//
//  HomeView.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @Environment(Router.self) private var router

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage, viewModel.products.isEmpty {
                ContentUnavailableView("Couldn't load products",
                                       systemImage: "wifi.exclamationmark",
                                       description: Text(errorMessage))
            }
            ForEach(viewModel.products) { product in
                Button {
                    router.push(product)
                } label: {
                    ProductRow(product: product)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.products.isEmpty {
                ProgressView()
            }
        }
        .navigationTitle("Products")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }
}

private struct ProductRow: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: product.thumbnail.flatMap(URL.init)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.secondary.opacity(0.15)
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(product.title)
                Text(product.price, format: .currency(code: "USD"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
    }
}

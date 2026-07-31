//
//  ItemDetailView.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct ItemDetailView: View {
    @State private var viewModel: ItemDetailViewModel

    init(viewModel: ItemDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CachedAsyncImage(url: viewModel.item.thumbnail.flatMap(URL.init)) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.secondary.opacity(0.15)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(viewModel.item.price, format: .currency(code: "USD"))
                    .font(.title2).bold()

                Text(viewModel.item.description)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(viewModel.item.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.refresh() }
    }
}

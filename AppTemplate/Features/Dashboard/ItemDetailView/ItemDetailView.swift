//
//  ItemDetailView.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct ItemDetailView: View {

    @State private var viewModel: ItemDetailViewModel

    init(viewModel: ItemDetailViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        AsyncContentView(
            state: viewModel.state,
            emptyTitle: "Item unavailable",
            emptyIcon: "questionmark.folder",
            retry: { await viewModel.load() }
        ) { item in
            detail(item)
        }
        .navigationTitle(viewModel.state.value?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {

            guard viewModel.state.needsLoad else { return }
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load(isRefresh: true)
        }
    }

    private func detail(_ item: Item) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                CachedAsyncImage(url: item.thumbnailURL) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    SkeletonView(cornerRadius: Theme.Radius.lg)
                        .aspectRatio(4 / 3, contentMode: .fit)
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text(item.title)
                        .font(Theme.Font.sectionTitle)
                        .testID(AccessibilityID.ItemDetail.title)

                    Text(item.price, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(Theme.Font.cardTitle)
                        .foregroundStyle(Theme.Color.accent)
                        .testID(AccessibilityID.ItemDetail.price)
                }

                Text(item.description)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.secondaryText)
            }
            .padding(Theme.Spacing.lg)
        }
    }
}

#if DEBUG

#Preview {
    PreviewHost { dependencies in
        NavigationStack {
            ItemDetailView(viewModel: dependencies.makeItemDetailViewModel(id: 1))
        }
    }
}

#endif

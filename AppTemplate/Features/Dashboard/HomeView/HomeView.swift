//
//  HomeView.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct HomeView: View {

    @State private var viewModel: HomeViewModel
    @Environment(Router<HomeRoute>.self) private var router

    init(viewModel: HomeViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        AsyncContentView(
            state: viewModel.state,
            emptyTitle: viewModel.isSearching ? "No matches" : "No items yet",
            emptyMessage: viewModel.isSearching
                ? "Try a different search term."
                : "Items you add will appear here.",
            emptyIcon: viewModel.isSearching ? "magnifyingglass" : "tray",
            retry: { await viewModel.load() }
        ) { items in
            list(items)
        }
        .navigationTitle(Text("Items", comment: "Title of the items list screen"))
        .searchable(
            text: $viewModel.searchText,
            prompt: Text("Search items", comment: "Placeholder in the items search field")
        )

        .task(id: viewModel.searchText) {
            if !viewModel.searchText.isEmpty {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
            }
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load(isRefresh: true)
        }
    }

    private func list(_ items: [Item]) -> some View {
        List {
            ForEach(items) { item in
                Button {
                    router.push(.itemDetail(id: item.id))
                } label: {
                    ItemRow(item: item)
                }
                .buttonStyle(.plain)
                .testID(AccessibilityID.Home.row(item.id))
                .task {

                    if viewModel.shouldLoadMore(after: item) {
                        await viewModel.loadMore()
                    }
                }
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .accessibilityLabel(Text(
                    "Loading more items",
                    comment: "Accessibility label for the pagination spinner"
                ))
            }
        }
        .listStyle(.plain)
        .testID(AccessibilityID.Home.list)
    }
}

private struct ItemRow: View {

    let item: Item

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            CachedAsyncImage(url: item.thumbnailURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                SkeletonView(cornerRadius: Theme.Radius.md)
            }
            .frame(width: Theme.Size.thumbnail, height: Theme.Size.thumbnail)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))

            VStack(alignment: .leading, spacing: Theme.Spacing.xs / 2) {
                Text(item.title)
                    .font(Theme.Font.cardTitle)
                    .lineLimit(2)

                Text(item.price, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(Theme.Font.secondary)
                    .foregroundStyle(Theme.Color.secondaryText)
            }

            Spacer(minLength: Theme.Spacing.sm)

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Theme.Color.tertiaryText)
                .accessibilityHidden(true)
        }
        .padding(.vertical, Theme.Spacing.xs)

        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

#if DEBUG

#Preview("Loaded") {
    PreviewHost { dependencies in
        NavigationStack {
            HomeView(viewModel: dependencies.makeHomeViewModel())
        }
        .environment(Router<HomeRoute>())
    }
}

#Preview("Empty") {
    PreviewHost(scenario: .empty) { dependencies in
        NavigationStack {
            HomeView(viewModel: dependencies.makeHomeViewModel())
        }
        .environment(Router<HomeRoute>())
    }
}

#Preview("Offline") {
    PreviewHost(scenario: .failure(.offline)) { dependencies in
        NavigationStack {
            HomeView(viewModel: dependencies.makeHomeViewModel())
        }
        .environment(Router<HomeRoute>())
    }
}

#endif

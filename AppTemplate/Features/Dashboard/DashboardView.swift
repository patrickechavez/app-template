//
//  DashboardView.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct DashboardView: View {
    let dependencies: AppDependencies

    var body: some View {
        TabView {
            HomeTab(dependencies: dependencies)
                .tabItem { Label("Home", systemImage: "square.grid.2x2") }

            ProfileTab(dependencies: dependencies)
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}

// MARK: - Home tab

private enum HomeSheet: Identifiable { case example; var id: Self { self } }
private enum HomeCover: Identifiable { case example; var id: Self { self } }

private struct HomeTab: View {
    let dependencies: AppDependencies
    @State private var router = Router()
    @State private var sheet: HomeSheet?
    @State private var cover: HomeCover?

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(viewModel: dependencies.makeHomeViewModel())
                .navigationDestination(for: Item.self) { item in
                    ItemDetailView(
                        viewModel: dependencies.makeItemDetailViewModel(item: item)
                    )
                }
                .toolbar { modalMenu }
        }
        .environment(router)
        .appAlert($router.alert)
        .sheet(item: $sheet) { route in
            switch route {
            case .example: HomeSheetView(viewModel: dependencies.makeHomeSheetViewModel())
            }
        }
        .fullScreenCover(item: $cover) { route in
            switch route {
            case .example: HomeCoverView(viewModel: dependencies.makeHomeCoverViewModel())
            }
        }
    }

    private var modalMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Show Sheet") { sheet = .example }
                Button("Show Cover") { cover = .example }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}

// MARK: - Profile tab

private enum ProfileSheet: Identifiable { case example; var id: Self { self } }
private enum ProfileCover: Identifiable { case example; var id: Self { self } }

private struct ProfileTab: View {
    let dependencies: AppDependencies
    @State private var router = Router()
    @State private var sheet: ProfileSheet?
    @State private var cover: ProfileCover?

    var body: some View {
        NavigationStack(path: $router.path) {
            ProfileView(viewModel: dependencies.makeProfileViewModel())
                .toolbar { modalMenu }
        }
        .environment(router)
        .appAlert($router.alert)
        .sheet(item: $sheet) { route in
            switch route {
            case .example: ProfileSheetView(viewModel: dependencies.makeProfileSheetViewModel())
            }
        }
        .fullScreenCover(item: $cover) { route in
            switch route {
            case .example: ProfileCoverView(viewModel: dependencies.makeProfileCoverViewModel())
            }
        }
    }

    private var modalMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Show Sheet") { sheet = .example }
                Button("Show Cover") { cover = .example }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}

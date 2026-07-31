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

private struct HomeTab: View {
    let dependencies: AppDependencies
    @State private var router = Router()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(viewModel: dependencies.makeHomeViewModel())
                .navigationDestination(for: Item.self) { item in
                    ItemDetailView(
                        viewModel: dependencies.makeItemDetailViewModel(item: item)
                    )
                }
        }
        .environment(router)
    }
}

private struct ProfileTab: View {
    let dependencies: AppDependencies
    @State private var router = Router()

    var body: some View {
        NavigationStack(path: $router.path) {
            ProfileView(viewModel: dependencies.makeProfileViewModel())
        }
        .environment(router)
    }
}

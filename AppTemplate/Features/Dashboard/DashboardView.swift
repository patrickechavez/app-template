//
//  DashboardView.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct DashboardView: View {

    let dependencies: AppDependencies

    @Environment(AppNavigator.self) private var navigator

    var body: some View {
        @Bindable var navigator = navigator

        TabView(selection: $navigator.selectedTab) {
            HomeTab(dependencies: dependencies)
                .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.systemImage) }
                .tag(AppTab.home)

            ProfileTab(dependencies: dependencies)
                .tabItem { Label(AppTab.profile.title, systemImage: AppTab.profile.systemImage) }
                .tag(AppTab.profile)
        }
        .testID(AccessibilityID.Shell.tabBar)
    }
}

private enum HomeSheet: Identifiable { case example; var id: Self { self } }
private enum HomeCover: Identifiable { case example; var id: Self { self } }

private struct HomeTab: View {

    let dependencies: AppDependencies

    @Environment(AppNavigator.self) private var navigator
    @State private var sheet: HomeSheet?
    @State private var cover: HomeCover?

    @SceneStorage("home.path") private var storedPath: Data?

    var body: some View {
        @Bindable var router = navigator.home

        NavigationStack(path: $router.path) {
            HomeView(viewModel: dependencies.makeHomeViewModel())
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case let .itemDetail(id):
                        ItemDetailView(viewModel: dependencies.makeItemDetailViewModel(id: id))
                    }
                }
                .toolbar { modalMenu }
        }
        .environment(navigator.home)
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
        .task {
            navigator.home.restore(from: storedPath)
        }
        .onChange(of: navigator.home.path) { _, _ in
            storedPath = navigator.home.restorationData
        }
    }

    private var modalMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    sheet = .example
                } label: {
                    Text("Show Sheet", comment: "Menu item that presents an example sheet")
                }
                Button {
                    cover = .example
                } label: {
                    Text("Show Cover", comment: "Menu item that presents an example full-screen cover")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel(Text("More", comment: "Accessibility label for the overflow menu"))
        }
    }
}

private struct ProfileTab: View {

    let dependencies: AppDependencies

    @Environment(AppNavigator.self) private var navigator

    var body: some View {
        @Bindable var router = navigator.profile

        NavigationStack(path: $router.path) {
            ProfileView(viewModel: dependencies.makeProfileViewModel())
                .navigationDestination(for: ProfileRoute.self) { route in
                    switch route {
                    case .editProfile:
                        Text("Edit Profile", comment: "Title of the placeholder edit-profile screen")
                    case .settings:
                        Text("Settings", comment: "Title of the placeholder settings screen")
                    }
                }
        }
        .environment(navigator.profile)
        .appAlert($router.alert)
    }
}

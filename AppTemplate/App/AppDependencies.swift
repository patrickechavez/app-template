//
//  AppDependencies.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

@MainActor
final class AppDependencies {
    let session: SessionManager

    private let auth: AuthRepository
    private let users: UserRepository
    private let items: ItemRepository
    private let imageLoader: any ImageLoading

    private init(session: SessionManager,
                 auth: AuthRepository,
                 users: UserRepository,
                 items: ItemRepository,
                 imageLoader: any ImageLoading) {
        self.session = session
        self.auth = auth
        self.users = users
        self.items = items
        self.imageLoader = imageLoader
    }

    static func live() -> AppDependencies {
        let tokenStore = KeychainTokenStore()
        let api = URLSessionAPIClient(baseURL: APIConfig.baseURL, tokenStore: tokenStore)

        return AppDependencies(
            session: SessionManager(tokenStore: tokenStore),
            auth: LiveAuthRepository(api: api),
            users: LiveUserRepository(api: api),
            items: LiveItemRepository(api: api),
            imageLoader: ImageLoader.shared
        )
    }

    // MARK: - ViewModel factories

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(auth: auth, session: session)
    }

    func makeRegisterViewModel() -> RegisterViewModel {
        RegisterViewModel(auth: auth, users: users)
    }

    func makeForgotPasswordViewModel() -> ForgotPasswordViewModel {
        ForgotPasswordViewModel(auth: auth)
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(repository: items)
    }

    func makeItemDetailViewModel(item: Item) -> ItemDetailViewModel {
        ItemDetailViewModel(item: item, repository: items)
    }

    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(repository: users, session: session, imageLoader: imageLoader)
    }
}

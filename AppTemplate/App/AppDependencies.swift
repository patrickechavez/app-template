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
    private let products: ProductRepository

    private init(session: SessionManager,
                 auth: AuthRepository,
                 users: UserRepository,
                 products: ProductRepository) {
        self.session = session
        self.auth = auth
        self.users = users
        self.products = products
    }

    static func live() -> AppDependencies {
        let baseURL = URL(string: "https://dummyjson.com")!
        let tokenStore = KeychainTokenStore()
        let api = URLSessionAPIClient(baseURL: baseURL, tokenStore: tokenStore)

        return AppDependencies(
            session: SessionManager(tokenStore: tokenStore),
            auth: LiveAuthRepository(api: api),
            users: LiveUserRepository(api: api),
            products: LiveProductRepository(api: api)
        )
    }

    // MARK: - ViewModel factories

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(auth: auth, session: session)
    }

    func makeRegisterViewModel() -> RegisterViewModel {
        RegisterViewModel(auth: auth)
    }

    func makeForgotPasswordViewModel() -> ForgotPasswordViewModel {
        ForgotPasswordViewModel(auth: auth)
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(repository: products)
    }

    func makeProductDetailViewModel(product: Product) -> ProductDetailViewModel {
        ProductDetailViewModel(product: product, repository: products)
    }

    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(repository: users, session: session)
    }
}

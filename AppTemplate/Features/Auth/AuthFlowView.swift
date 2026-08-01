//
//  AuthFlowView.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

enum AuthRoute: Hashable {
    case register
    case forgotPassword
}

struct AuthFlowView: View {
    let dependencies: AppDependencies
    @State private var router = Router()

    var body: some View {
        NavigationStack(path: $router.path) {
            LoginView(viewModel: dependencies.makeLoginViewModel())
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .register:
                        RegisterView(viewModel: dependencies.makeRegisterViewModel())
                    case .forgotPassword:
                        ForgotPasswordView(viewModel: dependencies.makeForgotPasswordViewModel())
                    }
                }
        }
        .environment(router)
        .appAlert($router.alert)
    }
}

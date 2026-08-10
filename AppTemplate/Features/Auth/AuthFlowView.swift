//
//  AuthFlowView.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct AuthFlowView: View {

    let dependencies: AppDependencies

    @Environment(AppNavigator.self) private var navigator

    var body: some View {
        @Bindable var router = navigator.auth

        NavigationStack(path: $router.path) {
            LoginView(viewModel: dependencies.makeLoginViewModel())
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .register:
                        RegisterView(viewModel: dependencies.makeRegisterViewModel())
                    case .forgotPassword:
                        ForgotPasswordView(viewModel: dependencies.makeForgotPasswordViewModel())
                    case let .resetPassword(token):
                        ResetPasswordView(token: token)
                    }
                }
        }
        .environment(navigator.auth)
        .appAlert($router.alert)
    }
}

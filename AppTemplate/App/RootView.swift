//
//  RootView.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies

    var body: some View {
        // Reading `session.state` here makes Observation re-render on change.
        switch dependencies.session.state {
        case .unauthenticated:
            AuthFlowView(dependencies: dependencies)
        case .authenticated:
            DashboardView(dependencies: dependencies)
        }
    }
}

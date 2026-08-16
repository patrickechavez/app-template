//
//  PrivacyShieldView.swift
//  AppTemplate
//  Created by John Patrick Echavez on 8/16/26.
//

import SwiftUI

/// Opaque overlay shown while the app is not active, so the task-switcher
/// snapshot hides the user's content instead of revealing it.
struct PrivacyShieldView: View {

    var body: some View {
        Rectangle()
            .fill(Color("LaunchBackground"))
            .ignoresSafeArea()
            .overlay {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.Color.secondaryText)
            }
            .accessibilityHidden(true)
    }
}

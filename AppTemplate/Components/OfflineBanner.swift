//
//  OfflineBanner.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

/// Shown while the device has no route to the network, so a failing screen
/// reads as a connection problem rather than a broken app.
struct OfflineBanner: View {

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "wifi.exclamationmark")
            Text("No internet connection", comment: "Banner shown while the device is offline")
                .font(Theme.Font.caption)
        }
        .foregroundStyle(.white)
        .padding(.vertical, Theme.Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(Theme.Color.danger)
        .accessibilityElement(children: .combine)
        .testID(AccessibilityID.Shell.offlineBanner)
    }
}

extension View {

    /// Drops an offline banner in from the top while `monitor` reports no
    /// connection. Placed above the safe area so it never covers content.
    func offlineBanner(_ monitor: NetworkMonitor) -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            if !monitor.isConnected {
                OfflineBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(Theme.Animation.standard, value: monitor.isConnected)
    }
}

#if DEBUG

#Preview("Offline") {
    VStack {
        Spacer()
        Text("Screen content")
        Spacer()
    }
    .frame(maxWidth: .infinity)
    .safeAreaInset(edge: .top, spacing: 0) { OfflineBanner() }
}

#endif

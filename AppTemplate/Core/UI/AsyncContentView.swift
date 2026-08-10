//
//  AsyncContentView.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct AsyncContentView<Value: Sendable, Content: View>: View {

    let state: LoadState<Value>

    var emptyTitle: LocalizedStringKey = "Nothing here yet"
    var emptyMessage: LocalizedStringKey?
    var emptyIcon: String = "tray"

    var retry: (@Sendable () async -> Void)?

    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel(Text("Loading", comment: "Accessibility label for a loading spinner"))

        case let .loaded(value):
            content(value)

        case .empty:
            ContentUnavailableView {
                Label(emptyTitle, systemImage: emptyIcon)
            } description: {
                if let emptyMessage { Text(emptyMessage) }
            }
            .testID(AccessibilityID.Home.emptyState)

        case let .failed(error):
            ErrorStateView(error: error, retry: retry)
        }
    }
}

struct ErrorStateView: View {

    let error: APIError
    var retry: (@Sendable () async -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(error.localizedDescription)
        } actions: {
            if let retry, error.isRetryable {
                Button {
                    Task { await retry() }
                } label: {
                    Text("Try Again", comment: "Button that retries a failed network request")
                }
                .buttonStyle(.borderedProminent)
                .testID(AccessibilityID.Home.retryButton)
            }
        }
        .testID(AccessibilityID.Home.errorState)
    }

    private var title: LocalizedStringKey {
        switch error {
        case .offline: "You're offline"
        case .timedOut: "That took too long"
        case .notFound: "Not found"
        case .forbidden: "No access"
        case .maintenance: "Temporarily unavailable"
        case .updateRequired: "Update required"
        default: "Something went wrong"
        }
    }

    private var icon: String {
        switch error {
        case .offline, .transport: "wifi.exclamationmark"
        case .timedOut: "clock.badge.exclamationmark"
        case .notFound: "questionmark.folder"
        case .forbidden, .unauthorized: "lock"
        case .maintenance: "wrench.and.screwdriver"
        case .updateRequired: "arrow.down.circle"
        default: "exclamationmark.triangle"
        }
    }
}

struct SkeletonView: View {

    var cornerRadius: CGFloat = Theme.Radius.sm

    @State private var isAnimating = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Theme.Color.placeholder)
            .opacity(isAnimating ? 0.45 : 1)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
            .accessibilityHidden(true)
    }
}

struct SkeletonList: View {

    var rows = 6

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: Theme.Spacing.md) {
                    SkeletonView(cornerRadius: Theme.Radius.md)
                        .frame(width: Theme.Size.thumbnail, height: Theme.Size.thumbnail)

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        SkeletonView().frame(height: 14)
                        SkeletonView().frame(width: 80, height: 12)
                    }
                }
            }
        }
        .screenPadding()
        .accessibilityHidden(true)
    }
}

//
//  Theme.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

enum Theme {

    enum Spacing {

        static let xs: CGFloat = 4

        static let sm: CGFloat = 8

        static let md: CGFloat = 12

        static let lg: CGFloat = 16

        static let xl: CGFloat = 24

        static let xxl: CGFloat = 32
    }

    enum Radius {

        static let sm: CGFloat = 6

        static let md: CGFloat = 10

        static let lg: CGFloat = 16

        static let pill: CGFloat = 999
    }

    enum Size {
        static let avatarSmall: CGFloat = 40
        static let avatarMedium: CGFloat = 64
        static let avatarLarge: CGFloat = 96
        static let thumbnail: CGFloat = 56

        static let minimumTapTarget: CGFloat = 44
    }

    enum Color {

        static let accent = SwiftUI.Color.accentColor

        static let primaryText = SwiftUI.Color.primary
        static let secondaryText = SwiftUI.Color.secondary
        static let tertiaryText = SwiftUI.Color(uiColor: .tertiaryLabel)

        static let background = SwiftUI.Color(uiColor: .systemBackground)
        static let secondaryBackground = SwiftUI.Color(uiColor: .secondarySystemBackground)
        static let groupedBackground = SwiftUI.Color(uiColor: .systemGroupedBackground)

        static let separator = SwiftUI.Color(uiColor: .separator)

        static let danger = SwiftUI.Color.red
        static let warning = SwiftUI.Color.orange
        static let success = SwiftUI.Color.green

        static let placeholder = SwiftUI.Color(uiColor: .tertiarySystemFill)
    }

    enum Font {
        static let screenTitle = SwiftUI.Font.largeTitle.weight(.bold)
        static let sectionTitle = SwiftUI.Font.title3.weight(.semibold)
        static let cardTitle = SwiftUI.Font.headline
        static let body = SwiftUI.Font.body
        static let secondary = SwiftUI.Font.callout
        static let caption = SwiftUI.Font.footnote
        static let fieldLabel = SwiftUI.Font.footnote
        static let fieldError = SwiftUI.Font.caption
    }

    enum Animation {

        static let standard = SwiftUI.Animation.smooth(duration: 0.25)

        static let content = SwiftUI.Animation.easeInOut(duration: 0.2)
    }
}

extension View {

    func screenPadding() -> some View {
        padding(.horizontal, Theme.Spacing.lg)
    }

    func cardStyle() -> some View {
        padding(Theme.Spacing.lg)
            .background(Theme.Color.secondaryBackground, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }

    func minimumTapTarget() -> some View {
        frame(minWidth: Theme.Size.minimumTapTarget, minHeight: Theme.Size.minimumTapTarget)
    }
}

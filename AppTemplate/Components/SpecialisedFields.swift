//
//  SpecialisedFields.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI
import UIKit

struct EmailField: View {

    @Binding var text: String

    var label: String? = String(localized: "Email", comment: "Label for the email field")
    var error: String?
    var isRequired: Bool = false
    var identifier: String?

    var body: some View {
        AppTextField(
            text: $text,
            placeholder: String(localized: "name@example.com", comment: "Placeholder for the email field"),
            label: label,
            error: error,
            isRequired: isRequired,
            keyboard: .emailAddress,
            capitalization: .never,
            contentType: .emailAddress,
            disableAutocorrection: true,
            identifier: identifier
        )
    }
}

struct UsernameField: View {

    @Binding var text: String

    var label: String? = String(localized: "Username", comment: "Label for the username field")
    var error: String?
    var isRequired: Bool = false
    var identifier: String?

    var body: some View {
        AppTextField(
            text: $text,
            placeholder: String(localized: "Username", comment: "Placeholder for the username field"),
            label: label,
            error: error,
            isRequired: isRequired,
            capitalization: .never,
            contentType: .username,
            disableAutocorrection: true,
            identifier: identifier
        )
    }
}

struct PasswordField: View {

    @Binding var text: String

    var label: String? = String(localized: "Password", comment: "Label for the password field")
    var error: String?
    var isRequired: Bool = false
    var isNewPassword: Bool = false
    var identifier: String?

    @State private var isRevealed = false
    @FocusState private var isFocused: Bool

    var body: some View {
        FieldContainer(label: label, isRequired: isRequired, error: error) {
            Group {
                if isRevealed {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(isNewPassword ? .newPassword : .password)
            .focused($isFocused)
            .accessibilityIdentifier(identifier ?? "")
            .accessibilityLabel(label.map(Text.init) ?? Text(placeholder))

            Button {
                isRevealed.toggle()

                isFocused = true
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .foregroundStyle(Theme.Color.secondaryText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isRevealed
                    ? Text("Hide password", comment: "Accessibility label for the password reveal toggle")
                    : Text("Show password", comment: "Accessibility label for the password reveal toggle")
            )
        }
    }

    private var placeholder: String {
        String(localized: "Password", comment: "Placeholder for the password field")
    }
}

struct SearchField: View {

    @Binding var text: String

    var placeholder: String = String(localized: "Search", comment: "Placeholder for a search field")
    var identifier: String?

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.Color.secondaryText)
                .accessibilityHidden(true)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .accessibilityIdentifier(identifier ?? "")

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.Color.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Clear search", comment: "Accessibility label for the clear-search button"))
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 2)
        .background(Theme.Color.secondaryBackground, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
    }
}

struct DateField: View {

    @Binding var date: Date

    var label: String?
    var error: String?
    var isRequired: Bool = false
    var range: ClosedRange<Date>?
    var displayedComponents: DatePicker.Components = .date

    var body: some View {
        FieldContainer(label: label, isRequired: isRequired, error: error) {
            Group {
                if let range {
                    DatePicker("", selection: $date, in: range, displayedComponents: displayedComponents)
                } else {
                    DatePicker("", selection: $date, displayedComponents: displayedComponents)
                }
            }
            .labelsHidden()
            .accessibilityLabel(label.map(Text.init) ?? Text("Date", comment: "Accessibility label for a date field"))
        }
    }
}

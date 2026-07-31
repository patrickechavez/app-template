//
//  PasswordField.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI
import UIKit

struct PasswordField: View {
    @Binding var text: String
    var label: String? = "Password"
    var placeholder: String = "Password"
    var error: String? = nil
    var isRequired: Bool = false
    var contentType: UITextContentType = .password

    @State private var isRevealed = false

    var body: some View {
        FieldContainer(label: label, isRequired: isRequired, error: error) {
            Group {
                if isRevealed {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textContentType(contentType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
        }
    }
}

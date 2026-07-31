//
//  AppTextField.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI
import UIKit

struct AppTextField: View {
    @Binding var text: String

    var placeholder: String = ""
    var label: String? = nil
    var error: String? = nil
    var isRequired: Bool = false

    var keyboard: UIKeyboardType = .default
    var capitalization: TextInputAutocapitalization = .sentences
    var contentType: UITextContentType? = nil
    var disableAutocorrection: Bool = false
    var submitLabel: SubmitLabel = .return

    var body: some View {
        FieldContainer(label: label, isRequired: isRequired, error: error) {
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(capitalization)
                .textContentType(contentType)
                .autocorrectionDisabled(disableAutocorrection)
                .submitLabel(submitLabel)
        }
    }
}

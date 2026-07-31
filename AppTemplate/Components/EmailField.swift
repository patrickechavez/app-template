//
//  EmailField.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct EmailField: View {
    @Binding var text: String
    var label: String? = "Email"
    var placeholder: String = "you@example.com"
    var error: String? = nil
    var isRequired: Bool = false

    var body: some View {
        AppTextField(
            text: $text,
            placeholder: placeholder,
            label: label,
            error: error,
            isRequired: isRequired,
            keyboard: .emailAddress,
            capitalization: .never,
            contentType: .emailAddress,
            disableAutocorrection: true
        )
    }
}

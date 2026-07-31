//
//  UsernameField.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct UsernameField: View {
    @Binding var text: String
    var label: String? = "Username"
    var placeholder: String = "Username"
    var error: String? = nil
    var isRequired: Bool = false

    var body: some View {
        AppTextField(
            text: $text,
            placeholder: placeholder,
            label: label,
            error: error,
            isRequired: isRequired,
            capitalization: .never,
            contentType: .username,
            disableAutocorrection: true
        )
    }
}

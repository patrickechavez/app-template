//
//  AlertState.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct AlertState: Identifiable {
    let id = UUID()
    let title: String
    var message: String?
    var buttons: [AlertButton]

    static func error(_ title: String, _ message: String? = nil) -> AlertState {
        AlertState(title: title, message: message, buttons: [AlertButton(title: "OK")])
    }

    static func confirmDestructive(_ title: String,
                                   message: String? = nil,
                                   confirm: String,
                                   onConfirm: @escaping () -> Void) -> AlertState {
        AlertState(title: title, message: message, buttons: [
            AlertButton(title: "Cancel", role: .cancel),
            AlertButton(title: confirm, role: .destructive, action: onConfirm)
        ])
    }
}

struct AlertButton: Identifiable {
    let id = UUID()
    let title: String
    var role: ButtonRole?
    var action: () -> Void = {}
}

extension View {
    func appAlert(_ state: Binding<AlertState?>) -> some View {
        alert(
            state.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { state.wrappedValue != nil },
                set: { if !$0 { state.wrappedValue = nil } }
            ),
            presenting: state.wrappedValue
        ) { alert in
            ForEach(alert.buttons) { button in
                Button(button.title, role: button.role, action: button.action)
            }
        } message: { alert in
            if let message = alert.message { Text(message) }
        }
    }
}

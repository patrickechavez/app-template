//
//  FieldContainer.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct FieldContainer<Content: View>: View {
    let label: String?
    let isRequired: Bool
    let error: String?
    @ViewBuilder let content: () -> Content

    private var hasError: Bool { !(error ?? "").isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let label {
                HStack(spacing: 2) {
                    Text(label)
                    if isRequired { Text("*").foregroundStyle(.red) }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                content()
                if isRequired && label == nil {
                    Text("*").foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(hasError ? Color.red : Color.secondary.opacity(0.4), lineWidth: 1)
            )

            if hasError, let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

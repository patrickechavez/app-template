//
//  ProfileSheetView.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct ProfileSheetView: View {
    @State private var viewModel: ProfileSheetViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ProfileSheetViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "person.text.rectangle")
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
                Text(viewModel.title).font(.title2.bold())
                Text(viewModel.subtitle)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("Sheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

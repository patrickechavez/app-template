//
//  DateField.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct DateField: View {
    @Binding var date: Date?
    var label: String? = "Date"
    var placeholder: String = "Select date"
    var error: String? = nil
    var isRequired: Bool = false

    var format: Date.FormatStyle = .dateTime.month(.abbreviated).day().year()
    var displayedComponents: DatePickerComponents = .date
    var range: ClosedRange<Date>? = nil

    @State private var isPresented = false
    @State private var draft = Date()

    var body: some View {
        FieldContainer(label: label, isRequired: isRequired, error: error) {
            Button {
                draft = date ?? Date()
                isPresented = true
            } label: {
                HStack {
                    Text(date.map { $0.formatted(format) } ?? placeholder)
                        .foregroundStyle(date == nil ? Color.secondary : Color.primary)
                    Spacer(minLength: 8)
                    Image(systemName: "calendar").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $isPresented) { pickerSheet }
    }

    private var pickerSheet: some View {
        NavigationStack {
            Group {
                if let range {
                    DatePicker("", selection: $draft, in: range, displayedComponents: displayedComponents)
                } else {
                    DatePicker("", selection: $draft, displayedComponents: displayedComponents)
                }
            }
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        date = draft
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

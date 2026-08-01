//
//  ImagePicker.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI
import PhotosUI

struct ImagePicker<Label: View>: View {
    @Binding var image: UIImage?
    @ViewBuilder var label: () -> Label

    @State private var item: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $item, matching: .images) {
            label()
        }
        .onChange(of: item) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    image = uiImage
                }
            }
        }
    }
}

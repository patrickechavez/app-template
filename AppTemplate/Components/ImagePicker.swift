//
//  ImagePicker.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import PhotosUI
import SwiftUI
import os

struct ImagePicker<Label: View>: View {

    @Binding var image: UIImage?
    @ViewBuilder var label: () -> Label

    var onError: ((any Error) -> Void)?

    @State private var selection: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
            label()
        }
        .task(id: selection) {
            await loadSelection()
        }
    }

    private func loadSelection() async {
        guard let selection else { return }

        do {
            guard let data = try await selection.loadTransferable(type: Data.self) else { return }

            let decoded = await Task.detached(priority: .userInitiated) {
                UIImage(data: data)
            }.value

            guard !Task.isCancelled, let decoded else { return }
            image = decoded
        } catch {
            AppLogger.images.error("Could not load picked photo: \(error.localizedDescription, privacy: .public)")
            onError?(error)
        }
    }
}

struct AvatarView: View {

    let user: User?
    var size: CGFloat = Theme.Size.avatarMedium

    var body: some View {
        CachedAsyncImage(url: user?.avatarURL) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            ZStack {
                Theme.Color.placeholder
                if let initials = user?.initials, !initials.isEmpty {
                    Text(initials)

                        .font(.system(size: size * 0.36, weight: .semibold))
                        .foregroundStyle(Theme.Color.secondaryText)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.4))
                        .foregroundStyle(Theme.Color.secondaryText)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel(
            user.map { Text("Profile photo for \($0.fullName)") }
                ?? Text("Profile photo", comment: "Accessibility label for a placeholder avatar")
        )
    }
}

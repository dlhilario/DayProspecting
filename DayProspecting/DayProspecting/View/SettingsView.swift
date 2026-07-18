//
//  Settings.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 6/26/26.
//

import PhotosUI  // 💡 Required framework for the system photo gallery picker interface
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [SettingsBO]

    @AppStorage("app_language") private var appLanguage: String = "en"
    @AppStorage("is_dark_mode") private var isDarkMode: Bool = false
    @AppStorage("my_portal_url") private var inputUrl: String = ""
    @AppStorage("app_logo_base64") private var logoBase64: String = ""
    // 💡 NEW: State storage fields to hold selected photo items and UI display states
    @State private var pickedItem: PhotosPickerItem? = nil

    // Computed property to turn our AppStorage base64 string back into a UIImage instantly for the UI
    private var displayImage: UIImage? {
        guard let data = Data(base64Encoded: logoBase64) else { return nil }
        return UIImage(data: data)
    }

    private let availableLanguages = [
        "en": "English", "es": "Español", "fr": "Français",
    ]

    var body: some View {
        Form {
            // 💡 NEW: Business Logo Upload and Live Profile Frame Section
            Section(header: Text("Business Branding")) {
                VStack(spacing: 14) {
                    if let imageToRender = displayImage {
                        Image(uiImage: imageToRender)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color.black.opacity(0.1), radius: 4)
                    } else {
                        // Default fallback placeholder graphic asset
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No Logo Uploaded")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Native modal presentation picker component wrapper
                    PhotosPicker(
                        selection: $pickedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label(
                            displayImage == nil
                                ? "Select Logo Image" : "Change Logo Image",
                            systemImage: "photo.on.rectangle.angled"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .buttonStyle(.borderedProminent)
                    }

                    if displayImage != nil {
                        Button(role: .destructive, action: removeLogoAction) {
                            Label("Remove Logo", systemImage: "trash")
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.vertical, 6)
            }

            Section(header: Text("Appearance")) {
                Toggle(isOn: $isDarkMode) {
                    Label("Dark Mode", systemImage: "moon.circle.fill")
                        .foregroundColor(isDarkMode ? .purple : .gray)
                }
                .onChange(of: isDarkMode) { _, _ in syncSettings() }

                Picker("App Language", selection: $appLanguage) {
                    ForEach(availableLanguages.keys.sorted(), id: \.self) {
                        key in
                        Text(availableLanguages[key] ?? "").tag(key)
                    }
                }
                .pickerStyle(.navigationLink)
                .onChange(of: appLanguage) { _, _ in syncSettings() }
            }

            Section(header: Text("Portal Link Configuration")) {
                HStack {
                    Image(systemName: "link.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    TextField("https://myportal.com", text: $inputUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }

            if !inputUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                Section(header: Text("Your Portal QR Code")) {
                    VStack(alignment: .center, spacing: 16) {
                        Text(
                            "Scan this image to navigate directly to your assigned setup portal."
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                        if let qrImage = QRCodeGenerator.generateMatrix(
                            from: inputUrl
                        ) {
                            Image(uiImage: qrImage)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        } else {
                            ContentUnavailableView(
                                "Invalid Format",
                                systemImage: "exclamationmark.triangle"
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Settings")
        // 💡 Load database values cleanly when the user navigates into the interface layout view
        .onAppear {
            // If AppStorage is empty but SwiftData has an image, recover it!
            if logoBase64.isEmpty, let savedRecord = settings.first, let databaseData = savedRecord.logoImageData {
                self.logoBase64 = databaseData.base64EncodedString()
            }
        }
        .onChange(of: inputUrl) { _, _ in syncSettings() }
        // 💡 Trigger safe background decoding payload execution when an item layout selection changes
        .onChange(of: pickedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(
                    type: Data.self
                ) {
                    // Compress image slightly to optimize storage performance size
                    if let uiImage = UIImage(data: data),
                        let compressedData = uiImage.jpegData(
                            compressionQuality: 0.6
                        )
                    {

                        let base64String = compressedData.base64EncodedString()

                        await MainActor.run {
                            // 1. Save directly to AppStorage for immediate UI rendering
                            self.logoBase64 = base64String

                            // 2. Instantly mirror data over to your persistent database model container
                            self.syncSettings()
                        }
                    }
                }
            }
        }

    }

    private func syncSettings() {
        // Convert our AppStorage base64 string back to binary Data for SwiftData storage
        let binaryImageData = Data(base64Encoded: logoBase64)

        if let currentSettings = settings.first {
            currentSettings.myPortalUrl = inputUrl
            currentSettings.isDarkMode = isDarkMode
            currentSettings.selectedLanguage = appLanguage
            currentSettings.logoImageData = binaryImageData  // Syncs to SwiftData
        } else {
            let newSettings = SettingsBO(
                logoImageData: binaryImageData,
                selectedLanguage: appLanguage,
                isDarkMode: isDarkMode,
                myPortalUrl: inputUrl
            )
            modelContext.insert(newSettings)
        }
        try? modelContext.save()
    }

    private func removeLogoAction() {
        withAnimation {
            self.logoBase64 = ""  // Clears AppStorage instantly
            self.pickedItem = nil
            self.syncSettings()  // Clears SwiftData context
        }
    }
}

#Preview {
    SettingsView()
}

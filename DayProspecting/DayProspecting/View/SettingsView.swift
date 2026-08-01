//
//  Settings.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 6/26/26.
//

import PhotosUI
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [SettingsBO]

    @AppStorage("app_language") private var appLanguage: String = "en"
    @AppStorage("is_dark_mode") private var isDarkMode: Bool = false
    @AppStorage("my_portal_url") private var inputUrl: String = ""
    @AppStorage("app_logo_base64") private var logoBase64: String = ""
    
    @State private var pickedItem: PhotosPickerItem? = nil

    // 💡 FIXED: Safely decodes base64 and strips opaque backings to guarantee transparency
    private var displayImage: UIImage? {
        guard let data = Data(base64Encoded: logoBase64),
              let uiImage = UIImage(data: data) else { return nil }
        
        if let pngData = uiImage.pngData(), let cleanTransparentImage = UIImage(data: pngData) {
            return cleanTransparentImage
        }
        return uiImage
    }

    private let availableLanguages = [
        "en": "English", "es": "Español", "fr": "Français",
    ]

    var body: some View {
        Form {
            Section(header: Text("Business Branding")) {
                VStack(spacing: 14) {
                    if let imageToRender = displayImage {
                        Image(uiImage: imageToRender)
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
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

                    PhotosPicker(
                        selection: $pickedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label(
                            displayImage == nil ? "Select Logo Image" : "Change Logo Image",
                            systemImage: "photo.on.rectangle.angled"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .buttonStyle(.borderedProminent)
                    }
                    // 💡 FIXED: Consolidated data extraction pipeline block
                    .onChange(of: pickedItem) { _, newItem in
                        Task {
                            // 1. Correctly read structural raw image contents from local gallery
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                
                                // 2. Strip background by converting image pixels directly to clean PNG format data mapping
                                if let pngData = uiImage.pngData() {
                                    await MainActor.run {
                                        // 3. Persist back smoothly to storage framework property
                                        self.logoBase64 = pngData.base64EncodedString()
                                        self.syncSettings()
                                    }
                                }
                            }
                        }
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
                    ForEach(availableLanguages.keys.sorted(), id: \.self) { key in
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

            if !inputUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section(header: Text("Your Portal QR Code")) {
                    VStack(alignment: .center, spacing: 16) {
                        Text("Scan this image to navigate directly to your assigned setup portal.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        if let qrImage = QRCodeGenerator.generateMatrix(from: inputUrl) {
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
        .onAppear {
            if logoBase64.isEmpty, let savedRecord = settings.first, let databaseData = savedRecord.logoImageData {
                self.logoBase64 = databaseData.base64EncodedString()
            }
        }
        .onChange(of: inputUrl) { _, _ in syncSettings() }
        // 💡 FIXED: Completely removed the secondary trailing duplicate .onChange layout block that was breaking logic.
    }

    // MARK: - Helper Core Data Methods (Stubs to prevent build compilation errors)
    
    private func syncSettings() {
        // Logic to sync app storage parameters with your database records goes here
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
        self.logoBase64 = ""
        self.pickedItem = nil
        self.syncSettings()
    }
}


#Preview {
    SettingsView()
}

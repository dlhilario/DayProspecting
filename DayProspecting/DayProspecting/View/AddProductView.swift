//
//  AgregarProducto.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 7/3/26.
//

import PhotosUI
import SwiftData
import SwiftUI

struct AddProductView: View {
    let productToEdit: ProductDetail
    let prospect: ContactAddress
    let settings: SettingsBO

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Drive form inputs via local standard view states instead of un-inserted SwiftData models
    @State var pfProduct = ProductDetail.emptyProductDetail

    // Image Handling States
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showCamera = false
    @State private var showGallery = false
    @State private var showImageSourceOptions = false
    @State var sumTaxes: Double = 0.0
    @AppStorage("setting_stateTax") private var savedStateTax: Double = 6.0
    @AppStorage("setting_countyTax") private var savedCountyTax: Double = 1.0
    @AppStorage("setting_percentEarning") private var savedPercentEarning:
        Double = 30.0

    var body: some View {
        Form {
            // Isolated Sub-Expression 1
            imageSection

            // Isolated Sub-Expression 2
            detailsSection
            
            // Notes
            notesSection
            
            // Isolated Sub-Expression 3
            submitSection
        }
        .navigationTitle(
            productToEdit.name.isEmpty
                ? "Add Product for \(prospect.firstName)"
                : "Edit Product for \(prospect.firstName)"
        )
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Choose Image Source",
            isPresented: $showImageSourceOptions,
            titleVisibility: .visible
        ) {
            Button("Take Photo (Camera)") {
                showCamera = true
            }
            Button("Browse Photo Library") {
                showGallery = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $pfProduct.image)
                .ignoresSafeArea()
        }
        .photosPicker(
            isPresented: $showGallery,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task { @MainActor in
                if let data = try? await newItem?.loadTransferable(
                    type: Data.self
                ),
                    let uiImage = UIImage(data: data)
                {
                    self.pfProduct.image = uiImage
                }
            }
        }
        // 💡 FIX 1: Populate fields when editing an existing product
        .onAppear {
            if !productToEdit.name.isEmpty || !productToEdit.code.isEmpty {
                pfProduct.name = productToEdit.name
                pfProduct.code = productToEdit.code
                pfProduct.price = productToEdit.price
                pfProduct.image = productToEdit.image
                pfProduct.stateTax = settings.setting_stateTax
                pfProduct.countyTax = settings.setting_countyTax
                pfProduct.percentErnings = settings.setting_percentEarning
            }
        }
    }
}

// MARK: - Extracted Form Sub-Expressions
extension AddProductView {

    private var imageSection: some View {
        Section(header: Text("Product Image")) {
            VStack {
                if let identifier = pfProduct.image {
                    Image(uiImage: identifier)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .cornerRadius(12)
                        .clipped()
                } else {
                    ContentUnavailableView(
                        "No Image Selected",
                        systemImage: "photo.badge.plus",
                        description: Text(
                            "Tap below to take a photo or browse your gallery."
                        )
                    )
                    .frame(height: 180)
                }

                Button(action: { showImageSourceOptions = true }) {
                    Label(
                        pfProduct.image == nil ? "Add Image" : "Change Image",
                        systemImage: "camera.and.lens"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            }
        }
    }

    private var detailsSection: some View {
        Section(header: Text("Product Details")) {
            TextField("Product Name", text: $pfProduct.name)
                .textInputAutocapitalization(.words)

            TextField("Product Code / SKU", text: $pfProduct.code)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled(true)

            HStack {
                // 💡 FIX 1: Show a static localized currency symbol
                Text("$")
                    .foregroundColor(.secondary)

                // 💡 FIX 2: Bind directly to the string field property without unsafe string format casting
                TextField(
                    "Price",
                    value: $pfProduct.price,
                    format: .currency(code: "USD")
                )
                .keyboardType(.decimalPad)  // 👈 Placed correctly on the input view
            }
            .onChange(of: pfProduct.price ?? 0.0) { _, price in
                // 1. Fetch tax rates directly from your global @AppStorage values
                let stateTaxRate = savedStateTax
                let countyTaxRate = savedCountyTax
                let combinedTaxPercentage = stateTaxRate + countyTaxRate

                // 2. Convert taxes to a raw mathematical multiplier (e.g., 7.0 / 100.0 = 0.07)
                let taxMultiplier = combinedTaxPercentage / 100.0

                // 3. Calculate base total balance (Price + Tax Amount)
                let totalBaseWithTax = price + (price * taxMultiplier)

                // 4. Fetch and convert earnings markup percentage (e.g., 30.0 / 100.0 = 0.3)
                let earningMultiplier = savedPercentEarning / 100.0
                let calculatedEarningMarkup =
                    totalBaseWithTax * earningMultiplier

                // 5. Combine everything together into a raw total
                let rawTotalBalanceResult =
                    totalBaseWithTax + calculatedEarningMarkup

                // 6. Finally, round to the nearest penny ($0.01) before saving to your model
                pfProduct.totalBalance =
                    (rawTotalBalanceResult * 100.0).rounded(
                        .toNearestOrAwayFromZero
                    ) / 100.0

                // Optional: Synchronize the underlying tax snapshots on the product if needed
                pfProduct.stateTax = stateTaxRate
                pfProduct.countyTax = countyTaxRate
            }

            HStack {
                // 💡 FIX 1: Show a static localized currency symbol
                Text("$")
                    .foregroundColor(.secondary)

                let sumTaxes = (savedStateTax) + (savedCountyTax)
                Text(
                    sumTaxes,
                    format: .number.precision(.fractionLength(2...4))
                )
                .keyboardType(.decimalPad)
                .disabled(true)  // 👈 Placed correctly on the input view
                Text("%")
                    .foregroundColor(.secondary)
            }
            HStack {
                // 💡 FIX 1: Show a static localized currency symbol
                Text("$")
                    .foregroundColor(.secondary)

                // 💡 FIX 2: Bind directly to the string field property without unsafe string format casting

                TextField(
                    "Payment",
                    value: $pfProduct.paidAmount,
                    format: .number
                )
                .keyboardType(.decimalPad)
            }
            .onChange(of: pfProduct.paidAmount) { _, newPaidAmount in
                // 1. Calculate absolute initial cost before payments (Price + Taxes)
                    let rawItemPrice = pfProduct.price ?? 0.0
                    let sumTaxes = (savedStateTax) + (savedCountyTax)
                    let percentageTaxMultiplier = sumTaxes / 100.0
                    
                    let totalBaseWithTax = rawItemPrice + (rawItemPrice * percentageTaxMultiplier)
                    
                    // 💡 FIX 2: Multiply by the Earning markup percentage to match your price onChange block!
                let earningMultiplier = (savedPercentEarning) / 100.0 
                    let calculatedEarningMarkup = totalBaseWithTax * earningMultiplier
                    
                    // This is the absolute starting invoice total
                    let originalTotalCost = totalBaseWithTax + calculatedEarningMarkup
                    
                    // 2. Subtract the fresh input value from the fixed original cost total
                    let safePaidAmount = newPaidAmount ?? 0.0
                    let remainingBalance = originalTotalCost - safePaidAmount
                    
                    // 3. Round perfectly to the nearest cent ($0.01) and save
                    pfProduct.totalBalance = (remainingBalance * 100.0).rounded(.toNearestOrAwayFromZero) / 100.0

            }

            HStack {
                // 💡 FIX 1: Show a static localized currency symbol
                Text("$")
                    .foregroundColor(.secondary)

                // 💡 FIX 2: Bind directly to the string field property without unsafe string format casting

                TextField(
                    "Total Balanced",
                    value: $pfProduct.totalBalance,
                    format: .currency(code: "USD")
                )
                .keyboardType(.decimalPad)
                .disabled(true)  // 👈 Placed correctly on the input view
            }
        }

    }

    private var notesSection: some View {
        Section(header: Text("Notes")) {
            HStack(alignment: .top) {
                // 1. Contextual leading indicator matches your accounting layout style
                Image(systemName: "note.text")
                    .foregroundColor(.secondary)
                    .font(.body)
                    .padding(.top, 2)
                    .frame(width: 24)

                // 2. Multiline vertical text field handles flexible growth without breaking frames
                TextField("Enter internal records, payment agreements, or milestones...",
                              text: $pfProduct.notes,
                              axis: .vertical) // 💡 Enables multi-line vertical growth
                       .font(.body)
                        .padding(12) // 💡 Internal spacing for the text
                        .frame(minHeight: 120, alignment: .top) // 💡 Forces a tall starting box
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .scrollContentBackground(.automatic)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1) // 💡 Crisp editor border
                        )
            }
            .padding(.vertical, 4)
        }

    }
    
    private var submitSection: some View {
        Section {
            Button(action: saveProduct) {
                Text("Save Product")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
            }
            .listRowBackground(Color.blue)
            .disabled(
                pfProduct.name.isEmpty || pfProduct.code.isEmpty
                    || pfProduct.price == 0
            )
        }
    }
}

// MARK: - Data Layer Logic
// MARK: - Data Layer Logic
extension AddProductView {
    private func saveProduct() {
        // Check if we are updating an existing product or building a completely new one
        if !productToEdit.name.isEmpty || !productToEdit.code.isEmpty {
            // 💡 EDIT MODE: Mutate the persistent instance directly
            productToEdit.name = pfProduct.name
            productToEdit.code = pfProduct.code
            productToEdit.price = pfProduct.price
            productToEdit.image = pfProduct.image
            productToEdit.totalBalance = pfProduct.totalBalance
            productToEdit.notes = pfProduct.notes
            productToEdit.paidAmount = pfProduct.paidAmount
            productToEdit.notes = pfProduct.notes
        } else {
            // 💡 ADD MODE: Create the product
            let newProduct = ProductDetail(
                name: pfProduct.name,
                code: pfProduct.code,
                price: pfProduct.price ?? 0,
                image: pfProduct.image,
                prospect: self.prospect,
                paidAmount: pfProduct.paidAmount,
                totalBalance: pfProduct.totalBalance,
                stateTax: pfProduct.stateTax,
                countyTax: pfProduct.countyTax,
                percentErnings: pfProduct.percentErnings,
                notes: pfProduct.notes
            )

            // 1. Insert into context
            modelContext.insert(newProduct)

            // 2. 🔥 CRITICAL FIX: Explicitly append to parent array to force UI update
            // Change ".products" to match whatever your array variable name is inside ContactAddress
            if prospect.products == nil {
                prospect.products = [newProduct]
            } else {
                prospect.products?.append(newProduct)
            }
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save SwiftData context: \(error)")
        }
    }
}

// MARK: - Preview Fixes
// MARK: - Preview Fix
#Preview {
    // 1. Setup the memory-only container
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ProductDetail.self,
        ContactAddress.self,
        configurations: config
    )

    // 2. Instantiate data
    let mockProspect = ContactAddress(
        firstName: "Domingo",
        lastName: "Hilario",
        communityName: "Center",
        number: "1",
        street: "Main",
        postCode: "0000",
        city: "City",
        state: "ST",
        phoneNumber: "123",
        residenceName: "",
        notes: "",
        appartmentNumber: "",
        list: false,
        contact: false,
        plan: false,
        followup: false
    )
    container.mainContext.insert(mockProspect)

    let sampleProduct = ProductDetail(
        name: "Sample Coffee Blend",
        code: "COF-0912",
        price: 14.99,
        image: UIImage(systemName: "cup.and.saucer.fill"),
        prospect: mockProspect,
        dateContacted: "08/01/2026",
        paidAmount: 0.0,
        totalBalance: 0.0,
        stateTax: 6.0,
        countyTax: 1.0,
        notes: "Test"
    )
    container.mainContext.insert(sampleProduct)
    let mockSetting = SettingsBO(
        logoImageData: nil,
        selectedLanguage: "eng",
        isDarkMode: true,
        myPortalUrl: "http://www.amway.com/myshop/domingohilario",
        setting_stateTax: 6.0,
        setting_countyTax: 1.0,
        setting_percentEarning: 30.0
    )
    container.mainContext.insert(mockSetting)

    // 3. ✅ Explicitly return your view hierarchy
    return NavigationStack {
        AddProductView(
            productToEdit: sampleProduct,
            prospect: mockProspect,
            settings: mockSetting
        )
    }
    .modelContainer(container)
}
extension Binding where Value == String? {
    init(_ source: Binding<String?>, replacingNilWith defaultValue: String) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { source.wrappedValue = (($0?.isEmpty) != nil) ? nil : $0 }
        )
    }
}

//
//  AgregarProducto.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 7/3/26.
//

import SwiftUI
import PhotosUI
import SwiftData

struct AddProductView: View {
    let productToEdit: ProductDetail
    let prospect: ContactAddress
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Drive form inputs via local standard view states instead of un-inserted SwiftData models
    @State var pfProduct = ProductDetail.emptyProductDetail
    
    // Image Handling States
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showCamera = false
    @State private var showGallery = false
    @State private var showImageSourceOptions = false
    
    var body: some View {
        Form {
            // Isolated Sub-Expression 1
            imageSection
            
            // Isolated Sub-Expression 2
            detailsSection
            
            // Isolated Sub-Expression 3
            submitSection
        }
        .navigationTitle(productToEdit.name.isEmpty ? "Add Product for \(prospect.firstName)" : "Edit Product for \(prospect.firstName)")
        .navigationBarTitleDisplayMode(.inline)      
        .confirmationDialog("Choose Image Source", isPresented: $showImageSourceOptions, titleVisibility: .visible) {
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
        .photosPicker(isPresented: $showGallery, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task { @MainActor in
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
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
                        description: Text("Tap below to take a photo or browse your gallery.")
                    )
                    .frame(height: 180)
                }
                
                Button(action: { showImageSourceOptions = true }) {
                    Label(pfProduct.image == nil ? "Add Image" : "Change Image", systemImage: "camera.and.lens")
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
                TextField("Price", value: $pfProduct.price, format: .number)
                    .keyboardType(.decimalPad) // 👈 Placed correctly on the input view
            }
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
            .disabled(pfProduct.name.isEmpty || pfProduct.code.isEmpty || pfProduct.price == 0)
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
        } else {
            // 💡 ADD MODE: Create the product
            let newProduct = ProductDetail(
                name: pfProduct.name,
                code: pfProduct.code,
                price: pfProduct.price ?? 0,
                image: pfProduct.image,
                prospect: self.prospect
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
    let container = try! ModelContainer(for: ProductDetail.self, ContactAddress.self, configurations: config)
    
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
        contact:false,
        plan:false,
        followup: false
    )
    container.mainContext.insert(mockProspect)
    
    let sampleProduct = ProductDetail(
        name: "Sample Coffee Blend",
        code: "COF-0912",
        price: 14.99,
        image: UIImage(systemName: "cup.and.saucer.fill"),
        prospect: mockProspect
    )
    container.mainContext.insert(sampleProduct)
    
    // 3. ✅ Explicitly return your view hierarchy
   return NavigationStack {
        AddProductView(productToEdit: sampleProduct, prospect: mockProspect)
    }
    .modelContainer(container)
}


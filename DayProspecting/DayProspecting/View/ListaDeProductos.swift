//
//  ListaDeProductos.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 7/3/26.
//

//
//  ListaDeProductos.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 7/3/26.
//

import SwiftData
import SwiftUI

struct ListaDeProductos: View {
    @Environment(\.modelContext) private var modelContext
    let prospect: ContactAddress
    let settingsBo: SettingsBO
    @Query(sort: \ProductDetail.CreatedDate, order: .forward)  private var products: [ProductDetail]

    @State private var selectedProduct: ProductDetail? = nil
    @State private var showAddProductSheet = false

    @State private var searchText = ""

    private var filteredProducts: [ProductDetail] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return products
        } else {
            return products.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText)
                || product.code.localizedCaseInsensitiveContains(searchText)
                || product.CreatedDate.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    init(prospect: ContactAddress, settings: SettingsBO) {
        self.prospect = prospect
        self.settingsBo = settings
        let targetPersistentID = prospect.persistentModelID
        
        let predicate = #Predicate<ProductDetail> { product in
            if let associatedProspect = product.prospect {
                return associatedProspect.persistentModelID == targetPersistentID
            } else {
                return false
            }
        }
        
        _products = Query(filter: predicate, sort: \ProductDetail.name)
    }

    var body: some View {
        VStack(spacing: 0) {
            if products.isEmpty {
                ContentUnavailableView(
                    "No Products Added",
                    systemImage: "cube.box.dash",
                    description: Text("Tap the '+' button above to link a product to \(prospect.firstName).")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                NavigationStack {
                    List {
                        ForEach(filteredProducts) { product in
                            Button(action: { selectedProduct = product }) {
                                productRow(for: product) // 💡 FIX 1: Extracted into its own sub-expression
                            }
                        }
                        .onDelete(perform: deleteProduct)
                        
                    }
                    .searchable(text: $searchText, placement:.navigationBarDrawer(displayMode: .always))
                }
            }
        }
        .navigationTitle("\(prospect.firstName)'s Products")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddProductSheet) {
           NavigationStack {
                AddProductView(
                    productToEdit: ProductDetail.emptyProductDetail,
                    prospect: prospect,
                    settings: settingsBo
                )
            }
        }
        .sheet(item: $selectedProduct) { product in
            NavigationView {
                AddProductView(productToEdit: product, prospect: prospect, settings: settingsBo)
            }
        }
        .toolbar {
            #if os(iOS)
            if !products.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            #endif
            
            ToolbarItem {
                Button(action: addProduct) {
                    Label("Add Product", systemImage: "plus")
                }
            }
        }
    }

    // 💡 FIX 1: Extracted Row View Sub-Expression to prevent compiler timeouts
    @ViewBuilder
    private func productRow(for product: ProductDetail) -> some View {
        HStack(alignment: .center, spacing: 12) {
            if let imageData = product.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    .clipped()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.secondary)
                    .frame(width: 50, height: 50)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(product.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    
                    // 💡 FIX 2: Safe type handling for price layout evaluation
                    Text(formattedPrice(product.totalBalance ?? 0))
                        .font(.headline)
                        .layoutPriority(1)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                Text(product.code)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Date added:\(product.CreatedDate)")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
    }
    
    // Helper to safely format prices whether stored as String or Double
    private func formattedPrice(_ price: Any) -> String {
        if let doublePrice = price as? Double {
            return String(format: "$%.2f", doublePrice)
        } else if let stringPrice = price as? String, let doubleValue = Double(stringPrice) {
            return String(format: "$%.2f", doubleValue)
        }
        return "$\(price)"
    }

    private func addProduct() {
        showAddProductSheet = true
    }
    
    func deleteProduct(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let productToDelete = products[index]
                modelContext.delete(productToDelete)
            }
            try? modelContext.save()
        }
    }
}

// MARK: - Preview Configuration
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ProductDetail.self, ContactAddress.self, configurations: config)
    
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
    
    let product1  = ProductDetail(
        name: "Sample Coffee",
        code: "COF-0911",
        price: 40.99,
        image: UIImage(systemName: "cup.and.saucer.fill"),
        prospect: mockProspect,
        dateContacted: "08/01/2026",
        paidAmount: 0.0,
        totalBalance: 0.0,
        stateTax:6.0,
        countyTax: 1.0,
        notes: "Test"
    )
    
    let product2  = ProductDetail(
        name: "Sample Coffee Blend",
        code: "COF-0912",
        price: 14.99,
        image: UIImage(systemName: "cup.and.saucer.fill"),
        prospect: mockProspect,
        dateContacted: "08/01/2026",
        paidAmount: 0.0,
        totalBalance: 0.0,
        stateTax:6.0,
        countyTax: 1.0,
        notes: "Test"
    )
    
    let mockSetting = SettingsBO(
        logoImageData: nil,
        selectedLanguage: "eng",
        isDarkMode: true,
        myPortalUrl: "http://www.amway.com/myshop/domingohilario",
        setting_stateTax: 6.0,
        setting_countyTax: 1.0,
        setting_percentEarning: 30.0
    )
    
    container.mainContext.insert(product1)
    container.mainContext.insert(product2)
    container.mainContext.insert(mockSetting)
    
    return NavigationStack {
        ListaDeProductos(prospect: mockProspect, settings: mockSetting)
    }
    .modelContainer(container)
}



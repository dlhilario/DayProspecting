//
//  ProspectForm.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 6/23/26.
//

import SwiftData
import SwiftUI

struct ProspectForm: View {
    @Environment(\.modelContext) private var modelContext
    
    // 💡 FIX 1: Removed inline initialization to support direct model tracking passes
    @State var contactAddress: ContactAddress
    
    @State private var selectedDecision: Decision = .NoResponse
    @StateObject private var locationManager = LocationManager()
    @State private var inputAddress: String = ""
    @State private var selectedTab = 1
    @State private var isActionExpanded = false
    @Environment(\.dismiss) private var dismiss
    
    // 💡 FIX 2: Custom initializer lets you view an existing contact OR cleanly seed a new one
    init(contactAddress: ContactAddress? = nil) {
        _contactAddress = State(initialValue: contactAddress ?? ContactAddress.emptyContactAddress)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Prospect", systemImage: "person.crop.circle.fill", value: 1) {
                NavigationStack {
                    Form {
                        infoAndDecisionSections
                        actionSection
                        addressSection
                        notesAndSaveSection
                    }
                }
            }
            
            Tab("Map", systemImage: "map.circle.fill", value: 2) {
                NavigationStack {
                    ProspectMapView(contact: contactAddress)
                }
            }
            .disabled(isMapDisabled)
            
            Tab("Products", systemImage: "cube.box", value: 3) {
               NavigationView{
                    ListaDeProductos(prospect: contactAddress)
                } .navigationViewStyle(.stack)
            }
            .disabled(contactAddress.firstName.isEmpty)
        }
        .onAppear {
            // 💡 FIX 4: Secure database assignment right on component registration
            if contactAddress.modelContext == nil {
                modelContext.insert(contactAddress)
            }
            
            if let decision = contactAddress.decision {
                selectedDecision = decision
            }
        }
    }
    
    // MARK: - Extracted Form Sub-Expressions
    
    @ViewBuilder
    private var infoAndDecisionSections: some View {
        Section(header: Text("Contact INFO")) {
            TextInputField("First Name", text: $contactAddress.firstName)
            TextInputField("Last Name", text: $contactAddress.lastName)
            TextInputField("Phone", text: $contactAddress.phoneNumber)
                .keyboardType(.numberPad)
                .onChange(of: contactAddress.phoneNumber) { _, newValue in
                    let formatted = format(phoneNumber: newValue)
                    if newValue != formatted {
                        Task { @MainActor in
                            contactAddress.phoneNumber = formatted
                        }
                    }
                }
        }
        
        Section(header: Text("Decision")) {
            Picker("Select Status", selection: $selectedDecision) {
                ForEach(Decision.allCases) { caseItem in
                    Text(caseItem.displayName).tag(caseItem)
                }
            }
            .onChange(of: selectedDecision) { _, newValue in
                contactAddress.decision = newValue
            }
        }
    }

    @ViewBuilder
    private var actionSection: some View {
        Section {
            DisclosureGroup("Action", isExpanded: $isActionExpanded) {
                HStack {
                    // 💡 Bind directly to Boolean? properties using custom getter/setter wrappers
                    Toggle(isOn: Binding(
                        get: { contactAddress.list ?? false },
                        set: { contactAddress.list = $0 }
                    )) { Label("List", systemImage: "list.bullet") }
                    
                    Toggle(isOn: Binding(
                        get: { contactAddress.contact ?? false },
                        set: { contactAddress.contact = $0 }
                    )) { Label("Contact", systemImage: "person") }
                }
                HStack {
                    Toggle(isOn: Binding(
                        get: { contactAddress.plan ?? false },
                        set: { contactAddress.plan = $0 }
                    )) { Label("Plan", systemImage: "calendar") }
                    
                    Toggle(isOn: Binding(
                        get: { contactAddress.followup ?? false },
                        set: { contactAddress.followup = $0 }
                    )) { Label("Followup", systemImage: "arrow.clockwise") }
                }
            }
        }
    }


    @ViewBuilder
    private var addressSection: some View {
        Section(header: Text("Address")) {
            Button(action: { locationManager.requestLocationString() }) {
                HStack {
                    if locationManager.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "location.fill")
                    }
                    Text(locationManager.isLoading ? "Locating..." : "Use My Current Location")
                }
                .font(.body)
                .bold()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(locationManager.isLoading)
            
            TextInputField("Community Name", text: $contactAddress.communityName)
            TextInputField("Number", text: $contactAddress.number)
            TextInputField("Street", text: $contactAddress.street)
                .onChange(of: locationManager.addressString) { _, newAddress in
                    if !newAddress.isEmpty {
                        contactAddress.street = newAddress
                    }
                }
            TextInputField("Appartment Number", text: $contactAddress.appartmentNumber)
            TextInputField("City", text: $contactAddress.city)
            TextInputField("State", text: $contactAddress.state)
            TextInputField("Zip", text: $contactAddress.postCode)
        }
    }
    
    @ViewBuilder
    private var notesAndSaveSection: some View {
        Section(header: Text("Notes")) {
            TextEditor(text: $contactAddress.notes)
                .frame(height: 17.0)
                .lineLimit(4, reservesSpace: false)
        }
        
        Button("Save", action: addItem)
            .frame(maxWidth: .infinity)
    }
    
    // MARK: - Logic & Properties
    
    private var isMapDisabled: Bool {
        contactAddress.number.isEmpty ||
        contactAddress.street.isEmpty ||
        contactAddress.city.isEmpty ||
        contactAddress.postCode.isEmpty
    }
    
    func format(phoneNumber: String) -> String {
        let cleanNumber = phoneNumber.filter { $0.isNumber }
        let digits = String(cleanNumber.prefix(10))
        let count = digits.count

        if count == 0 {
            return ""
        } else if count <= 3 {
            return "(\(digits)"
        } else if count <= 6 {
            let areaCode = digits.prefix(3)
            let prefix = digits.dropFirst(3)
            return "(\(areaCode)) \(prefix)"
        } else {
            let areaCode = digits.prefix(3)
            let prefix = digits.dropFirst(3).prefix(3)
            let line = digits.dropFirst(6)
            return "(\(areaCode)) \(prefix)-\(line)"
        }
    }
    
    private func addItem() {
        do {
            // Data properties update live through text fields; commit to storage device disk here
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save prospect record: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview Provider Fix
#Preview {
    let container = try! ModelContainer(
        for: ContactAddress.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let mockContact = ContactAddress.emptyContactAddress
    container.mainContext.insert(mockContact)
    
    return ProspectForm(contactAddress: mockContact)
        .modelContainer(container)
}



#Preview {
    
    // 1. Create an isolated in-memory model container for the canvas preview
    let container = try! ModelContainer(
        for: ContactAddress.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    // 2. Instantiate a mock customer contact address object with realistic preview details
    let mockContact = ContactAddress(
        firstName: "Domingo",
        lastName: "Hilario",
        communityName: "Downtown",
        number: "1600",
        street: "Pennsylvania Avenue NW",
        postCode: "20500",
        city: "Washington",
        state: "DC",
        phoneNumber: "555-0199",
        residenceName: "White House",
        notes: "Test prospect location pin validation rules.",
        appartmentNumber: "Apt 1",
        list: false,
        contact: false,
        plan: false,
        followup: false
    )
    
    // 3. Insert the mock contact object directly into our active canvas memory store
    container.mainContext.insert(mockContact)
    
    return ProspectForm(contactAddress: mockContact)
           .modelContainer(container)
}

struct TextInputField: View {
    var title: String
    @Binding var text: String
    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }
    var body: some View {
        VStack(alignment: .leading) {
            if !text.isEmpty {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            TextField(title, text: $text)

        }.animation(Animation.easeInOut, value: text)
    }
}

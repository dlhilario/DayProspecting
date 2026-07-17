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
    @State var contactAddress = ContactAddress.emptyContactAddress
    @State private var selectedDecision: Decision = .NoResponse
    @StateObject private var locationManager = LocationManager()
    @State private var inputAddress: String = ""
    @State private var selectedTab = 1 // 💡 Changed to match your Tab values (1, 2, 3)
    @State private var isActionExpanded = false
    @Environment(\.dismiss) private var dismiss
    
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
                NavigationView {
                    ProspectMapView(contact: contactAddress)
                }
            }
            .disabled(isMapDisabled)
            
            Tab("Products", systemImage: "cube.box", value: 3) {
                NavigationView {
                    ListaDeProductos(prospect: contactAddress)
                }
            }
            .disabled(contactAddress.firstName.isEmpty)
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
                .onChange(of: contactAddress.phoneNumber) { oldValue, newValue in
                    // Prevent infinite loop if the value is already formatted
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
            .onAppear {
                if let decision = contactAddress.decision {
                    selectedDecision = decision
                }
            }
        }
    }

    
    @ViewBuilder
    private var actionSection: some View {
        Section {
            DisclosureGroup("Action", isExpanded: $isActionExpanded){
                HStack {
                    Toggle(isOn: Binding($contactAddress.list) ?? .constant(false)) { Label("List", systemImage: "list.bullet") }
                    Toggle(isOn: Binding($contactAddress.contact) ?? .constant(false)) { Label("Contact", systemImage: "person") }
                }
                HStack{
                    Toggle(isOn: Binding($contactAddress.plan) ?? .constant(false)) { Label("Plan", systemImage: "calendar") }
                    Toggle(isOn: Binding($contactAddress.followup) ?? .constant(false)) { Label("Followup", systemImage: "arrow.clockwise") }
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
    
    /*private func addItem() {
        // Implement save logic here
        try? modelContext.save()
    }*/
    
    // ✅ The Formatting logic
    func format(phoneNumber: String) -> String {
    // 1. Remove all non-numeric characters
    let cleanNumber = phoneNumber.filter { $0.isNumber }

    // 2. Enforce a maximum length of 10 digits
    let digits = String(cleanNumber.prefix(10))

    // 3. Build the format piece by piece based on length
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
            // 1. Stage the record in memory (does not throw)
            modelContext.insert(contactAddress)
            
            // 2. Commit changes to the disk database (THIS throws!)
            try modelContext.save()
            
            // 3. Navigate back to the home screen
            dismiss()
        } catch {
            print("Failed to save prospect record: \(error.localizedDescription)")
        }
    }


}
 


#Preview {
    ProspectForm()
        .modelContainer(for: ContactAddress.self, inMemory: true)
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

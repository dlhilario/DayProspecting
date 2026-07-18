//
//  ContentView.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 6/22/26.
//


import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContactAddress.dateContacted, order: .reverse) private var contactAddress: [ContactAddress]

    @State private var showProspectForm = false
    @State private var selectedTab = 1
    @State private var showSettings = false
    @AppStorage("my_portal_url") private var inputUrl: String = ""
    @State private var isMyshopExpanded = false

    // 💡 NEW: State variable to track search text input
    @State private var searchText = ""

    // 💡 NEW: Computed property to handle dynamic list filtering live
    private var filteredContacts: [ContactAddress] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return contactAddress
        } else {
            return contactAddress.filter { contact in
                contact.firstName.localizedCaseInsensitiveContains(searchText)
                    || contact.lastName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                Tab("Prospect", systemImage: "person.crop.circle.fill", value: 1) {
                    prospectListView
                }

                Tab("My Biz", systemImage: "storefront.circle", value: 2) {
                    MyBusinessView
                }

                Tab("Survey", systemImage: "pencil.and.list.clipboard", value: 3) {
                    Survey()
                }

                Tab("Map", systemImage: "map.circle.fill", value: 4) {
                    ProspectDashboardView()
                }
                .disabled(isMapDisabled)
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search prospects..."
            )
            .onAppear {
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil {
                    NotificationManager.shared.requestAuthorization()
                }
            }
        }
    }

    // MARK: - Extracted Sub-Expressions

    @ViewBuilder
    private var prospectListView: some View {
        // 💡 Fix: List is now the primary structural view container so it stays inside screen boundaries
        List {
            ForEach(filteredContacts) { contact in
                NavigationLink {
                    ProspectForm(contactAddress: contact)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("\(contact.firstName) \(contact.lastName)")
                                .fontWeight(.medium)
                                .minimumScaleFactor(0.8) // Prevents running off screen on small layouts
                            
                            Spacer()

                            HStack(spacing: 8) {
                                Image(systemName: "list.bullet")
                                    .opacity(contact.list == true ? 1.0 : 0.2)
                                Image(systemName: "person")
                                    .opacity(contact.contact == true ? 1.0 : 0.2)
                                Image(systemName: "calendar")
                                    .opacity(contact.plan == true ? 1.0 : 0.2)
                                Image(systemName: "arrow.clockwise")
                                    .opacity(contact.followup == true ? 1.0 : 0.2)
                            }
                            .font(.caption)
                        }

                        Text("Contacted on: \(contact.dateContacted)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground).opacity(0.6))
                )
            }
            .onDelete(perform: deleteProspect)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        // 💡 Fix: Layer backgrounds natively under the list window frame bounds
        .background {
            ZStack {
                Image("bgimage1")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Image("managementCycle")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220, maxHeight: 220)
                    .opacity(0.2)
            }
        }
        #if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        #else
            .navigationDestination(isPresented: $showProspectForm) {
                ProspectForm()
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
        #endif
        .toolbar {
            #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedTab == 1 && !contactAddress.isEmpty {
                        EditButton()
                    }
                }
            #endif
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if selectedTab == 1 {
                        Button(action: addProspect) {
                            Label("Add Contact", systemImage: "person.crop.circle.badge.plus")
                        }
                        Button(action: openSettings) {
                            Label("Settings", systemImage: "gearshape")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").font(.title3)
                }
            }
        }
    }

    @ViewBuilder
    private var MyBusinessView: some View {
        ZStack {
            DisclosureGroup("My Shop", isExpanded: $isMyshopExpanded) {
                if !inputUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
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
            .padding(.all, 5.0)
        }
        .padding(.all, 5.0)
    }

    private var isMapDisabled: Bool {
        guard let firstContact = contactAddress.first else { return true }
        return firstContact.number.isEmpty || firstContact.street.isEmpty
            || firstContact.city.isEmpty || firstContact.state.isEmpty
            || firstContact.postCode.isEmpty
    }

    private func addProspect() {
        showProspectForm = true
    }

    private func openSettings() {
        showSettings = true
    }

    private func deleteProspect(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let targetContact = filteredContacts[index]
                modelContext.delete(targetContact)
            }
            try? modelContext.save()
        }
    }
}

#Preview {
    // 1. Define an explicit in-memory preview configuration layout
    let schema = Schema([ContactAddress.self, SettingsBO.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)

    do {
        let container = try ModelContainer(for: schema, configurations: config)

        // Create your mock customer record
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
        // Create your mock customer record
        let mockContact2 = ContactAddress(
            firstName: "Yordania",
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

        // 💡 FIX 1: Explicitly insert your mock components straight into the memory workspace database
        container.mainContext.insert(mockContact)
        container.mainContext.insert(mockContact2)

        // 💡 FIX 2: Pre-seed a default configuration record to ensure AppStorage background layers align
        let mockSettings = SettingsBO(
            selectedLanguage: "en",
            isDarkMode: false,
            myPortalUrl: "https://apple.com"
        )
        container.mainContext.insert(mockSettings)

        // 3. Return the view with the populated container properly attached
        return ContentView()
            .modelContainer(container)
    } catch {
        fatalError(
            "Failed to initialize preview container: \(error.localizedDescription)"
        )
    }
}

struct storyboardview: UIViewControllerRepresentable {

    func makeUIViewController(context content: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(
            identifier: "MainStoryBoard"
        )
        return controller
    }
    func updateUIViewController(
        _ uiViewController: UIViewController,
        context: Context
    ) {

    }
}

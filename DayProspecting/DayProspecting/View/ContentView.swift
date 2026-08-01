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

    @State private var searchText = ""

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
        // 🛠️ CRITICAL FIX 1: Completely removed the outer NavigationStack that wrapped TabView
        TabView(selection: $selectedTab) {
            
            Tab("Prospect", systemImage: "person.crop.circle.fill", value: 1) {
                // 🛠️ CRITICAL FIX 2: This is the ONLY NavigationStack needed for your list view
                NavigationStack {
                    prospectListView
                        .navigationTitle("Prospects") // Added title to make space for the toolbar/search
                        .searchable(
                            text: $searchText,
                            placement: .navigationBarDrawer(displayMode: .always),
                            prompt: "Search prospects..."
                        )
                        // 🛠️ CRITICAL FIX 3: Placed the toolbar directly inside the NavigationStack hierarchy
                        .toolbar {
                            #if os(iOS)
                            ToolbarItem(placement: .navigationBarTrailing) {
                                if !contactAddress.isEmpty {
                                    EditButton()
                                }
                            }
                            #endif
                            ToolbarItem(placement: .primaryAction) {
                                Menu {
                                    Button(action: addProspect) {
                                        Label("Add Contact", systemImage: "person.crop.circle.badge.plus")
                                    }
                                    Button(action: openSettings) {
                                        Label("Settings", systemImage: "gearshape")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle").font(.title3)
                                }
                            }
                        }
                }
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
        .onAppear {
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil {
                NotificationManager.shared.requestAuthorization()
            }
        }
    }

    // MARK: - Extracted Sub-Expressions

    @ViewBuilder
    private var prospectListView: some View {
        List {
            ForEach(filteredContacts) { contact in
                NavigationLink {
                    ProspectForm(contactAddress: contact)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("\(contact.firstName) \(contact.lastName)")
                                .fontWeight(.medium)
                                .minimumScaleFactor(0.8)
                            
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
        // 🛠️ REMOVED toolbar modifier from here to attach it directly inside the main body navigation view context instead.
    }

    
    
    @ViewBuilder
    private var MyBusinessView: some View {
        ZStack {
            DisclosureGroup("My Shop", isExpanded: $isMyshopExpanded) {
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
                                ContentUnavailableView("Invalid Format", systemImage: "exclamationmark.triangle")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Placeholder actions to prevent compiler errors
    private func addProspect() { showProspectForm = true }
    private func openSettings() { showSettings = true }
    private func deleteProspect(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let targetContact = filteredContacts[index]
                modelContext.delete(targetContact)
            }
            try? modelContext.save()
        }
    }
    
    private var isMapDisabled: Bool { false }
}

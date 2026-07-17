//
//  ContentView.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 6/22/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContactAddress.dateContacted, order: .reverse) private var contactAddress: [ContactAddress]

    @State private var showProspectForm = false
    @State private var selectedTab = 1
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                Tab("Prospect", systemImage: "person.crop.circle.fill", value: 1) {
                    prospectListView // 💡 FIX 1: Extracted into a distinct sub-expression
                }
                
                Tab("Survey", systemImage: "pencil.and.list.clipboard", value: 2) {
                    Survey()
                }
                
                Tab("Map", systemImage: "map.circle.fill", value: 3) {
                    ProspectDashboardView()
                }
                .disabled(isMapDisabled) // 💡 FIX 2: Extracted complex logic check
            }
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
        ZStack {
            Image("managementCycle")
                .resizable()
                .scaledToFit()
                .frame(width: 256, height: 256)
                .opacity(0.5)
            
            List {
                ForEach(contactAddress) { contact in
                    NavigationLink {
                        ProspectForm(contactAddress: contact)
                    } label: {
                        VStack(alignment: .leading) {
                            HStack(spacing: 15){
                                Text("\(contact.firstName) \(contact.lastName)")
                                Spacer()
                                Label("", systemImage: "list.bullet")
                                    .frame(width: 10, height: 10)
                                    .disabled(contact.list == false)
                                Label("", systemImage: "person")
                                    .frame(width: 10, height: 10)
                                    .disabled(contact.contact == false)
                                Label("", systemImage: "calendar")
                                    .frame(width: 10, height: 10)
                                    .disabled(contact.plan == false)
                                Label("", systemImage: "arrow.clockwise")
                                    .frame(width: 10, height: 10)
                                    .disabled(contact.followup == false)
                            }
                           
                            Text("Contacted on: \(contact.dateContacted)")
                                .font(.system(size: 10))
                            
                        }
                    }
                }
                .onDelete(perform: deleteProspect)
            }
            .scrollContentBackground(.hidden)
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            #else
            .navigationDestination(isPresented: $showProspectForm) {
                ProspectForm()
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
                ToolbarItem {
                    if selectedTab == 1 {
                        Button(action: addProspect) {
                            Label("Add Contact", systemImage: "person.crop.circle.badge.plus")
                        }
                    }
                }
            }
        }
    }
    
    // Computes whether the map tab should be disabled cleanly outside the view layout
    private var isMapDisabled: Bool {
        guard let firstContact = contactAddress.first else { return true }
        return firstContact.number.isEmpty ||
               firstContact.street.isEmpty ||
               firstContact.city.isEmpty ||
               firstContact.state.isEmpty ||
               firstContact.postCode.isEmpty
    }

    // MARK: - Action Functions
    
    private func addProspect() {
        showProspectForm = true
    }

    private func deleteProspect(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let deleteProspect = contactAddress[index]
                modelContext.delete(deleteProspect)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ContactAddress.self, inMemory: true)
}

struct storyboardview: UIViewControllerRepresentable{
        
    func makeUIViewController(context content: Context) -> UIViewController{
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(identifier: "MainStoryBoard")
        return controller
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context){
        
    }
}

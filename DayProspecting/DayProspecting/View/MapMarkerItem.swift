//
//  MapMarkerItem.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 6/26/26.
//

import SwiftUI
import MapKit
import SwiftData

// 1 a clean wrapper to hold our resolved coordinates for the map
struct MapMarkerItem: Identifiable {
    let id = UUID()
    let contact: ContactAddress
    let coordinate: CLLocationCoordinate2D
}

struct ProspectDashboardView: View {
    //2 Fetch all prospects automatically from swiftData storage
    @Query private var prospects: [ContactAddress]
    
    //3 Track map camera framing state and resolved pins
    @State private var position: MapCameraPosition = .automatic
    @State private var annotatedPins: [MapMarkerItem] = []
    @State private var isGeocoding = false
    // 1. State variable tracking which contact address record is actively selected
       @State private var selectedContact: ContactAddress?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isGeocoding {
                    ProgressView("Updating map pins...")
                        .padding()
                        .background(.ultraThinMaterial)
                }
                
                if annotatedPins.isEmpty && !isGeocoding {
                    ContentUnavailableView(
                        "No Map Data",
                        systemImage: "mappin.slash",
                        description: Text("Add prospects with valid addresses to see them pinned here.")
                    )
                } else {
                    // 4. Modern SwiftUI multi-marker Map setup
                    Map(position: $position, selection: $selectedContact) {
                        mapPins
                    }
                    .mapControls {
                        MapUserLocationButton()
                        MapCompass()
                        MapUserLocationButton()
                    }
                    .tint(Color(.label))
                }
            }
            .navigationTitle("Prospect Dashboard")
            .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.automatic)
            .navigationDestination(item: $selectedContact){ contact in
                ProspectDetails(contactAddress: contact)
            }
            // 5. Re-run geocoding whenever the database records update
            .onChange(of: prospects) { _, _ in
                geocodeAllProspects()
            }
            .onAppear {
                geocodeAllProspects()
            }
        }
    }
    
    @MapContentBuilder
    private var mapPins: some MapContent {
        ForEach(annotatedPins) { pin in
            Marker(
                "\(pin.contact.firstName) \(pin.contact.lastName)",
                                systemImage: "person.text.rectangle.fill",
                                coordinate: pin.coordinate
            )
            .tint(getMarkerColor(for: pin.contact.decision ?? .NoResponse))
            //Critical step: assign a unique identifiable tag to match your selection state
            .tag(pin.contact)
               
        }
        
    }
    
    //6 Asynchronously convert string addresses into map coordinates
    private func geocodeAllProspects() {
        guard !prospects.isEmpty else {
            annotatedPins = []
            return
        }
        
        isGeocoding = true
        let geocoder = CLGeocoder()
        var temporaryPins: [MapMarkerItem] = []
        let group = DispatchGroup()
        
        let isolationQueue = DispatchQueue(label: "com.dayprospecting.arrayIsolation")
        
        // Track our pacing timeline sequentially
        var delayOffset: Double = 0.0
        
        for prospect in prospects {
            let addressString = "\(prospect.number) \(prospect.street), \(prospect.city), \(prospect.state) \(prospect.postCode)"
            
            group.enter()
            
            // ✅ Fix: Stagger requests by scheduling each one 0.5 seconds after the previous one
            DispatchQueue.global().asyncAfter(deadline: .now() + delayOffset) {
                print("DEBUG: Sending geocode request for: '\(addressString)'")
                
                geocoder.geocodeAddressString(addressString) { placemarks, errors in
                    if let coordinate = placemarks?.first?.location?.coordinate {
                        let pin = MapMarkerItem(contact: prospect, coordinate: coordinate)
                        
                        isolationQueue.async {
                            temporaryPins.append(pin)
                        }
                        print("DEBUG: Successfully located pin for \(prospect.firstName)")
                    } else {
                        print("DEBUG: Rate-limit or Geocoding failure for \(prospect.firstName): \(errors?.localizedDescription ?? "Unknown")")
                    }
                    group.leave()
                }
            }
            
            // Increment the delay so the next loop cycle waits 0.5 seconds longer
            delayOffset += 0.5
        }
        
        group.notify(queue: .main) {
            self.annotatedPins = temporaryPins
            self.isGeocoding = false
            
            print("DEBUG: Total successfully rendered pins: \(temporaryPins.count)")
            
            if !temporaryPins.isEmpty {
                let coordinates = temporaryPins.map { $0.coordinate }
                let latitudes = coordinates.map { $0.latitude }
                let longitudes = coordinates.map { $0.longitude }
                
                guard let minLat = latitudes.min(), let maxLat = latitudes.max(),
                      let minLng = longitudes.min(), let maxLng = longitudes.max() else { return }
                
                let centerLatitude = (minLat + maxLat) / 2.0
                let centerLongitude = (minLng + maxLng) / 2.0
                let center = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
                
                let latDelta = max(0.01, (maxLat - minLat) * 1.2)
                let lngDelta = max(0.01, (maxLng - minLng) * 1.2)
                let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
                
                self.position = .region(MKCoordinateRegion(center: center, span: span))
            }
        }
    }
    
    // Helper function to color-code map markers based on the customer status lifecycle
    private func getMarkerColor(for decision: Decision) -> Color {
        switch decision{
                case .Client, .Sale: return .green
                case .Interested, .FollowUp: return .orange
                case .ThinkingAboutIt: return .yellow
                case .NotInterested: return .red
                case .Vacant, .NoResponse: return .gray
                case .IBO: return .purple
        }
    }

}


// MARK: - Safe Compiled Preview Setup
#Preview {
    // 💡 FIX 2: Create a functional context container layout mock environment
    let container = try! ModelContainer(
        for: ContactAddress.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
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
    
    container.mainContext.insert(mockContact)
    
    // 💡 FIX 3: Instantiated ProspectDashboardView directly instead of the structural item row model
    return ProspectDashboardView()
        .modelContainer(container)
}

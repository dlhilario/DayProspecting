//
//  MapApp.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 6/25/26.
//

import SwiftUI
import MapKit
import SwiftData

struct ProspectMapView: View {
    
    let contact: ContactAddress
    
    //Track map positioning state
    @State private var position: MapCameraPosition = .automatic
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var isLoading = true
    var body: some View {
        
        VStack{
            
            if isLoading {
                ProgressView("Locating Prospect Address...")
            }else if let coordinate = coordinate {
                //moden SwitUI map struture
                Map(position: $position){
                    Marker(
                        "\(contact.firstName) \(contact.lastName)",
                        systemImage: "person.circle.fill",
                        coordinate: coordinate
                    )
                    .tint(.blue)
                }.mapControls{
                    MapPitchToggle()
                    MapCompass()
                }
            }else{
                ContentUnavailableView(
                    "Address Not Found",
                    systemImage: "mappin.slash",
                    description: Text("Could not geocode address: \(contact.fullAddressString)")
                    
                )
            }                
            
        }.onAppear{
            geocodeAddress()
        }
    }
    
    //Converts string addresses to geographical markers
    private func geocodeAddress(){
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(contact.fullAddressString){ placemark, error in
            DispatchQueue.main.async {
                if let location = placemark?.first?.location {
                    let coord = location.coordinate
                    self.coordinate = coord
                    //focus the camera frame directly around the target pin location
                    self.position = .region(
                        MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                }
                self.isLoading = false
            }
        }
    }
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
    
    // 4. Return the view with the mapped contact item and model container attached
    return ProspectMapView(contact: mockContact)
        .modelContainer(container)
}



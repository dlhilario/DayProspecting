//
//  MapApp.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 6/25/26.
//

import SwiftUI
import MapKit

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



//
//  LocationManager.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 7/3/26.
//

import SwiftUI
import CoreLocation

// MARK: - LOCATION MANAGER
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var addressString: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationString() {
        isLoading = true
        errorMessage = nil
        
        // Check authorization status
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            isLoading = false
            errorMessage = "Location access denied. Please enable it in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation() // Triggers a single location update
        @unknown default:
            break
        }
    }
    
    // Handle the location update
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            isLoading = false
            return
        }
        
        // Reverse geocode GPS coordinates to a physical address
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to find address: \(error.localizedDescription)"
                    return
                }
                
                if let placemark = placemarks?.first {
                    // Format the address layout nicely
                    let streetNumber = placemark.subThoroughfare ?? ""
                    let streetName = placemark.thoroughfare ?? ""
                    let city = placemark.locality ?? ""
                    let state = placemark.administrativeArea ?? ""
                    let zip = placemark.postalCode ?? ""
                    
                    let formattedAddress = "\(streetNumber) \(streetName), \(city), \(state) \(zip)"
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    self?.addressString = formattedAddress
                }
            }
        }
    }
    
    // Handle lookup errors
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = "Could not get your location: \(error.localizedDescription)"
        }
    }
}

// MARK: - SWIFTUI VIEW
struct AddressAutofillView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var inputAddress: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Address Details")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // The Address Field
            TextField("Enter or locate your address", text: $inputAddress, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
            
            // Auto-Populate Button
            Button(action: {
                locationManager.requestLocationString()
            }) {
                HStack {
                    if locationManager.isLoading {
                        ProgressView()
                            .tint(.white)
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
            
            // Error messaging if something goes wrong
            if let error = locationManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
        // Automatically transfer the found address into your layout's text box
        .onChange(of: locationManager.addressString) { oldAddress, newValue in
            if !newValue.isEmpty {
                self.inputAddress = newValue
            }
        }
    }
}

// MARK: - PREVIEW
struct AddressAutofillView_Previews: PreviewProvider {
    static var previews: some View {
        AddressAutofillView()
    }
}

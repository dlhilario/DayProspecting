//
//  ClickableAddressRow.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 6/28/26.
//

import SwiftUI

struct ClickableAddressRow: View {
    let contact: ContactAddress

    var body: some View {
        Button(action: openInAppleMaps) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Address")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Display layout values cleanly
                    Text("\(contact.number) \(contact.street)")
                        .font(.body)
                    Text("\(contact.city), \(contact.state) \(contact.postCode)")
                        .font(.body)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.forward.app")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle()) // Ensures the entire white space block is clickable
        }
        .buttonStyle(.plain) // Removes standard blue button coloring from text strings
    }

    // ✅ The Core Opening Engine
    private func openInAppleMaps() {
        // 1. Build the absolute native system maps query link
        // 'q' places a custom pin name dropdown card directly over the coordinates
        let addressURLString = "maps://?address=\(contact.urlEncodedAddress)&q=\(contact.firstName)%20\(contact.lastName)"
        
        guard let url = URL(string: addressURLString) else { return }
        
        // 2. Safely tell iOS to hand execution tracking off to the system Maps application
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            // Fallback backup web address if running in custom sandboxes or external testing loops
            if let webUrl = URL(string: "https://apple.com\(contact.urlEncodedAddress)") {
                UIApplication.shared.open(webUrl)
            }
        }
    }
}


//
//  ProspectDetails.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 6/28/26.
//

import SwiftUI

struct ProspectDetails: View {
    @Environment(\.modelContext) private var modelContext
    @State var contactAddress = ContactAddress.emptyContactAddress
    @State private var selectedDecision: Decision = .NoResponse
    var body: some View {
        NavigationView{
            VStack{
                Form{
                    Section(header: Text("Contact INFO")){
                        TextInputField("First Name", text: $contactAddress.firstName)
                            .disabled(true)
                        TextInputField("Last Name", text: $contactAddress.lastName).disabled(true)
                        TextInputField("Phone", text: $contactAddress.phoneNumber).disabled(true)
                    }
                    Section(header: Text("Decision")){
                      Text("\(contactAddress.decision!)")
                        
                    }
                    Section(header: Text("Address")){                       
                        
                       ClickableAddressRow(contact: contactAddress)
                    }
                    Section(header: Text("Notes")){
                        Text("\(contactAddress.notes)")
                    }
                   
                    
                }
            }
        }
    }
}



#Preview {
    ProspectDetails()
}

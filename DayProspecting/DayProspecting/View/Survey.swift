//
//  Survey.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 6/28/26.
//

import SwiftUI

struct Survey: View {
    var body: some View {
        NavigationStack{
            VStack{
                List{
                    ExtractedView(_text: "Do you think we are in a contry of oportunities?")
                    
                    ExtractedView(_text: "Do you think that base on the oportunities this country offers we get in a confort zone?")
                    ExtractedView(_text: "If there is a way to generate an extra $3800 dollar at month, would you be interested?")
                    
                        .navigationTitle("Survey")
                        .navigationBarTitleDisplayMode(.inline)
                        
                }
            }
            
        }
      
          
    }
}

#Preview {
    Survey()
}

struct ExtractedView: View {
    var _text: String
    var body: some View {
        Text(_text)
            .multilineTextAlignment(.leading)
            .padding(.all, 10.0)
            
    }
}

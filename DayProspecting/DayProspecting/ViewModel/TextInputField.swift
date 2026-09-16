//
//  TextInputField.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 8/1/26.
//

import SwiftUI

struct TextInputField: View {
    var title: String
    @Binding var text: String
    var value: Double? = nil
    
    init(_ title: String, text: Binding<String>, value: Double? = nil) {
        self.title = title
        self._text = text
        self.value = value
    }
    // 💡 FIX: Added a secondary initializer to allow calling without a text binding parameter
        init(_ title: String, value: Double) {
            self.title = title
            self._text = .constant("") // Standard empty mock string binding
            self.value = value
        }
    
    var body: some View {
        VStack(alignment: .leading) {
            // Check if either string text or numerical value is active to show the label
            if !text.isEmpty || (value ?? 0.0) > 0.0 {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            
            // Unpack and display the safe numerical layout
            if let safeValue = value, safeValue > 0.0 {
                // 💡 FIX: Changed parameter label to 'value:' and wrapped it in a constant binding
                TextField(title, value: .constant(safeValue), format: .number.precision(.fractionLength(2...4)))
                    .disabled(true) // Disable because it's a read-only calculated view
            } else {
                TextField(title, text: $text)
            }

        }
        .animation(.easeInOut, value: text)
    }
}

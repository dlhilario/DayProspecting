//
//  LauncherScreenView.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 7/15/26.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isActive = false
    @State private var progressAmount = 0.0
    
    // 💡 NEW: Read the base64 logo string from AppStorage instantly
    @AppStorage("app_logo_base64") private var logoBase64: String = ""
    
    // Timer to update the progress bar smoothly
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    // 💡 NEW: Helper computed property to decode the stored image
    private var uploadedLogo: UIImage? {
        guard let data = Data(base64Encoded: logoBase64) else { return nil }
        return UIImage(data: data)
    }
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                Image("bgimage1")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    
                    Text("Wecome to Day Prospecting")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AccentColor"))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 400.0)
                    // 💡 NEW: Renders the custom uploaded logo if present, else falls back to app-logo
                    if let uiImage = uploadedLogo {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 16)) // Soften edges gracefully
                            .shadow(radius: 5)
                    } else {
                        Image("app-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                    }
                    
                    ProgressView(value: progressAmount, total: 100)
                        .tint(.blue)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(4)
                        .padding(.horizontal, 80)
                    
                    Text("Version 1.0.0.0")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }
            }
            .onReceive(timer) { _ in
                if progressAmount < 100 {
                    progressAmount += 2.0
                } else {
                    self.timer.upstream.connect().cancel()
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    LaunchScreenView()
        .modelContainer(for: ContactAddress.self, inMemory: true)
}

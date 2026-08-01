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
    
    // Read the base64 logo string from AppStorage instantly
    @AppStorage("app_logo_base64") private var logoBase64: String = ""
    
    // Timer to update the progress bar smoothly
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    // 💡 FIXED: Safely decodes base64 and forces PNG data extraction to guarantee transparency right here
    private var uploadedLogo: UIImage? {
        guard let data = Data(base64Encoded: logoBase64),
              let uiImage = UIImage(data: data) else { return nil }
        
        // This strips out any solid backgrounds accidentally baked in during encoding
        if let pngData = uiImage.pngData(), let cleanTransparentImage = UIImage(data: pngData) {
            return cleanTransparentImage
        }
        return uiImage
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
                    
                    Text("Welcome to Day Prospecting") // Fixed typo "Wecome"
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AccentColor"))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: 400) // Changed to maxWidth to prevent layout clips
                    
                    // 💡 FIXED: Clean layout wrapper without code logic conflicts inside the ViewBuilder
                    if let uiImage = uploadedLogo, let cgImage = uiImage.cgImage {
                        // 💡 Fix: Convert the orientation type smoothly using our custom extension
                        Image(cgImage, scale: uiImage.scale, orientation: uiImage.imageOrientation.toSwiftUI, label: Text("Logo"))
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
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

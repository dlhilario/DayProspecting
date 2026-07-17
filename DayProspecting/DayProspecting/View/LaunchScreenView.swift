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
    
    // Timer to update the progress bar smoothly
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if isActive {
            // Transitions to your main screen when loading finishes
            ContentView()
        } else {
            ZStack {
                // Background color or gradient
                //Color(.systemBackground)
                //    .ignoresSafeArea()
                Image("bgImage1")
                    .resizable()
                    .frame(width: .infinity, height: .infinity)
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Your App Logo (Ensure "app-logo" is added to Assets.xcassets)
                    Image("app-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                    
                    // Linear Loading Bar
                    ProgressView(value: progressAmount, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .padding(.horizontal, 50)
                }.background(ignoresSafeAreaEdges: .all)
            }
            .onReceive(timer) { _ in
                if progressAmount < 100 {
                    progressAmount += 2.0 // Adjust speed here
                } else {
                    // Turn off timer and swap views
                    self.timer.upstream.connect().cancel()
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}

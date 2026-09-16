//
//  ManagementCycleView.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 7/6/26.
//

import SwiftUI

// MARK: - Step Model
struct WorkflowStep: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    let color: Color
}

// MARK: - Main View
struct ManagementCycleView: View {
    let steps: [WorkflowStep] = [
        WorkflowStep(title: "LISTA", iconName: "tray.and.arrow.down.fill", color: Color(.systemBlue)),
        WorkflowStep(title: "CONTACT", iconName: "bubble.left.and.bubble.right.fill", color: Color(.systemGreen)),
        WorkflowStep(title: "PLAN", iconName: "map.fill", color: Color(.systemOrange)),
        WorkflowStep(title: "SEGUIMIENTO", iconName: "chart.bar.xaxis", color: Color(.systemRed))
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Text("CICLO DE GESTIÓN")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color(.darkGray))
                .padding(.top, 40)
            
            ZStack {
                // Outer decorative circular bounds
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    .frame(width: 320, height: 320)
                
                // Draw 4 distinct connected arrow wedges
                ForEach(0..<steps.count, id: \.self) { index in
                    let step = steps[index]
                    let anglePerStep = 360.0 / Double(steps.count)
                    // Start angle matches top position (-90 degrees offset in SwiftUI coordinate space)
                    let startAngle = Double(index) * anglePerStep - 90.0
                    
                    // The core arrow wedge shape
                    ArrowWedgeShape(startAngle: startAngle, endAngle: startAngle + anglePerStep)
                        .fill(step.color.gradient)
                    
                    // Positioning the icons and text dynamically over each arc center
                    GeometryReader { geo in
                        let midAngle = (startAngle + (startAngle + anglePerStep)) / 2.0 * .pi / 185.0
                        let radius: CGFloat = 120 // Halfway radius within our 140-300px track
                        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                        let labelPosition = CGPoint(
                            x: center.x + radius * cos(midAngle),
                            y: center.y + radius * sin(midAngle)
                        )
                        
                        VStack(spacing: 4) {
                            Image(systemName: step.iconName)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            Text(step.title)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .position(labelPosition)
                    }
                }
                
                // White mask for the central circle cutout
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 130, height: 130)
                    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
            }
            .frame(width: 300, height: 300)
            .padding(.vertical, 20)
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - Custom Arrow Wedge Shape
struct ArrowWedgeShape: Shape {
    var startAngle: Double
    var endAngle: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = rect.width / 2
        let innerRadius = outerRadius * 0.45
        
        let startRad = startAngle * .pi / 180
        let endRad = endAngle * .pi / 180
        
        // Arrowhead size adjustments
        let arrowOffsetRad = 8.0 * .pi / 180
        let mainEndRad = endRad - arrowOffsetRad
        
        // Outer arc (base of arrow)
        path.addArc(center: center, radius: outerRadius, startAngle: Angle(radians: startRad), endAngle: Angle(radians: mainEndRad), clockwise: false)
        
        // Build the pointed Arrowhead tip
        let tipOuterRadius = outerRadius * 1.12
        let tipInnerRadius = innerRadius * 0.82
        let midTipRadius = (tipOuterRadius + tipInnerRadius) / 2
        
        let tipPoint = CGPoint(
            x: CGFloat(center.x) + CGFloat(midTipRadius) * cos(CGFloat(endRad)),
            y: CGFloat(center.y) + CGFloat(midTipRadius) * sin(CGFloat(endRad))
        )
        let outerFlayerPoint = CGPoint(
            x: CGFloat(center.x) + CGFloat(tipOuterRadius) * cos(CGFloat(mainEndRad)),
            y: CGFloat(center.y) + CGFloat(tipOuterRadius) * sin(CGFloat(mainEndRad))
        )
        let innerFlayerPoint = CGPoint(
            x: CGFloat(center.x) + CGFloat(tipInnerRadius) * cos(CGFloat(mainEndRad)),
            y: CGFloat(center.y) + CGFloat(tipInnerRadius) * sin(CGFloat(mainEndRad))
        )

        
        path.addLine(to: outerFlayerPoint)
        path.addLine(to: tipPoint)
        path.addLine(to: innerFlayerPoint)
        
        // Inner arc returning to the start angle position
        path.addArc(center: center, radius: innerRadius, startAngle: Angle(radians: mainEndRad), endAngle: Angle(radians: startRad), clockwise: true)
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Color Extension Helper
extension Color {
    static let darkLabel = Color(UIColor.label)
}

// MARK: - Preview Provider
#Preview {
    ManagementCycleView()
}

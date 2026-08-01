//
//  Scanner.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 7/3/26.
//

import SwiftUI
import VisionKit

// 1. Create the Scanner View Wrapper
struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    @Binding var isScanning: Bool

    func makeUIViewController(context: Context) -> DataScannerViewController {
        // Configure to scan barcodes only
        let viewController = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if isScanning {
            try? uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: BarcodeScannerView

        init(_ parent: BarcodeScannerView) {
            self.parent = parent
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            // Handle tap-to-select if highlighting is enabled
            process(item: item)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Automatically grab the first detected item
            if let firstItem = addedItems.first {
                process(item: firstItem)
            }
        }

        private func process(item: RecognizedItem) {
            switch item {
            case .barcode(let barcode):
                // Update bindings on the main thread
                DispatchQueue.main.sync {
                    parent.scannedCode = barcode.payloadStringValue ?? "Unknown Barcode"
                    parent.isScanning = false // Stop scanning after a match
                }
            case .text(_):
                DispatchQueue.main.sync {
                    
                }
            @unknown default:
                break
            }
        }
    }
}

// 2. Integration Example
struct BarcodeViewer: View {
    
    @State private var scannedCode = "No code scanned yet"
    @State private var isScanning = false
    
    // Ensure you check for device capability
    private var isSupported: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(scannedCode)
                .font(.headline)
                .padding()

            if isSupported {
                Button(isScanning ? "Stop Scanning" : "Start Scanning") {
                    isScanning.toggle()
                }
                .buttonStyle(.borderedProminent)
                
                if isScanning {
                    BarcodeScannerView(scannedCode: $scannedCode, isScanning: $isScanning)
                        .frame(height: 400)
                        .cornerRadius(12)
                        .padding()
                }
            } else {
                Text("Camera scanning is not supported on this device or permission is denied.")
                    .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    BarcodeViewer()
}

//
//  QRCodeGenerator.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 7/17/26.
//


import UIKit
import CoreImage.CIFilterBuiltins

struct QRCodeGenerator {
    static func generateMatrix(from urlString: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        // Convert input string into a standard data package
        let data = Data(urlString.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction level
        
        // Scale up the CIImage output matrix so it remains crisp and not pixelated
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}

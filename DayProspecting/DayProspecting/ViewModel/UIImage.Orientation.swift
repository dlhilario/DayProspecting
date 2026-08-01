//
//  UIImage.Orientation.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 8/1/26.
//

import SwiftUI
import UIKit

extension UIImage.Orientation {
    var toSwiftUI: Image.Orientation {
        switch self {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

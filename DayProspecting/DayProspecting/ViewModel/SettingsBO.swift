//
//  Untitled.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 7/17/26.
//
import Foundation
import SwiftData
import UIKit

@Model
final class SettingsBO {
    @Attribute(.unique) public var id: UUID
    @Attribute(.externalStorage) public var logoImageData: Data? = nil
    public var selectedLanguage: String = "en"
    public var isDarkMode: Bool = false
    public var myPortalUrl: String = "" // 💡 Added property for your portal URL string
    
    public var logoImage: UIImage? {
        get {
            guard let logoImageData else { return nil }
            return UIImage(data: logoImageData)
        }
        set {
            logoImageData = newValue?.jpegData(compressionQuality: 0.8)
        }
    }
    
    init(id: UUID = UUID(), logoImageData: Data? = nil, selectedLanguage: String = "en", isDarkMode: Bool = false, myPortalUrl: String = "") {
        self.id = id
        self.logoImageData = logoImageData
        self.selectedLanguage = selectedLanguage
        self.isDarkMode = isDarkMode
        self.myPortalUrl = myPortalUrl
    }
}


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
    public var myPortalUrl: String = ""
    public var setting_stateTax: Double = 6.0
    public var setting_countyTax: Double = 1.0
    public var setting_percentEarning: Double = 30.0
    
    public var logoImage: UIImage? {
        get {
            guard let logoImageData else { return nil }
            return UIImage(data: logoImageData)
        }
        set {
            logoImageData = newValue?.jpegData(compressionQuality: 0.8)
        }
    }
    
    init(id: UUID = UUID(), logoImageData: Data? = nil, selectedLanguage: String = "en", isDarkMode: Bool = false, myPortalUrl: String = "", setting_stateTax: Double, setting_countyTax: Double, setting_percentEarning: Double) {
        self.id = id
        self.logoImageData = logoImageData
        self.selectedLanguage = selectedLanguage
        self.isDarkMode = isDarkMode
        self.myPortalUrl = myPortalUrl
        self.setting_stateTax = setting_stateTax
        self.setting_countyTax = setting_countyTax
        self.setting_percentEarning = setting_percentEarning
    }
    
  
}

extension SettingsBO {
    static var emptySettingsBO: SettingsBO {
        SettingsBO(logoImageData: nil, selectedLanguage: "", isDarkMode: false, myPortalUrl: "", setting_stateTax: 0.0, setting_countyTax: 0.0, setting_percentEarning: 0.0)
    }
}

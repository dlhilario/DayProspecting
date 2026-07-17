import Foundation
import SwiftData
import UIKit

@Model
final class ProductDetail {
    public var id = UUID()
    public var name: String = ""
    public var code: String = ""
    public var price: Double? = nil
    public var prospect: ContactAddress?
    public var CreatedDate: String = Date().formatted(date: .numeric, time: .omitted )
    // 1. Store as Data? instead of UIImage, using external storage optimization for images
    @Attribute(.externalStorage) public var imageData: Data? = nil    
       
       // 2. Pure computed property. Lacks a default value assignment (= nil)
       // so SwiftData bypasses persistence processing without macro errors.
       public var image: UIImage? {
           get {
               guard let imageData else { return nil }
               return UIImage(data: imageData)
           }
           set {
               imageData = newValue?.jpegData(compressionQuality: 0.8)
           }
       }
    
    init(name: String, code: String, price: Double? = nil, image: UIImage?, prospect: ContactAddress,dateContacted: String = Date().formatted(date: .numeric, time: .omitted ) ) {
        self.name = name
        self.code = code
        self.price = price
        self.imageData = image?.jpegData(compressionQuality: 0.8)
        self.prospect = prospect
        self.CreatedDate = dateContacted
     
    }
    
}

extension ProductDetail {
    static var emptyProductDetail: ProductDetail {
        ProductDetail(name: "", code: "", price: nil, image: nil, prospect: ProductDetail.emptyProspect )
    }
}
extension ProductDetail {
    static var emptyProspect: ContactAddress{
        ContactAddress(firstName: "", lastName: "", communityName: "", number: "", street: "", postCode: "", city: "", state: "", phoneNumber: "", residenceName: "", notes: "", appartmentNumber: "", list: false, contact: false, plan:false, followup: false)
    }
}

//
//  ContactAddress.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 6/24/26.
//
import Foundation
import SwiftData

@Model
final class ContactAddress{
    @Attribute(.unique) public var id: UUID
    public var firstName:String = ""
    public var lastName:String = ""
    public var communityName:String = ""
    public var number:String = ""
    public var street:String = ""
    public var appartmentNumber:String = ""
    public var postCode:String = ""
    public var city:String = ""
    public var state:String = ""
    public var phoneNumber:String = ""
    public var residenceName:String = ""
    public var notes:String = ""
    public var decision: Decision? = nil
    public var dateContacted: String = Date().formatted(date: .numeric, time: .omitted )
    @Relationship(deleteRule: .cascade, inverse: \ProductDetail.prospect)
    var products: [ProductDetail]? = nil
    public var list:Bool? = false
    public var contact:Bool? = false
    public var plan:Bool? = false
    public var followup:Bool? = false
    
    init(id: UUID = UUID(), firstName: String, lastName: String, communityName:String, number: String, street: String, postCode: String, city: String, state: String, phoneNumber: String, residenceName: String, notes: String, decision: Decision? = nil, dateContacted: String = Date().formatted(date: .numeric, time: .omitted ), appartmentNumber:String, list:Bool?, contact:Bool?, plan:Bool?, followup:Bool? ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.communityName = communityName
        self.number = number
        self.street = street
        self.postCode = postCode
        self.city = city
        self.state = state
        self.phoneNumber = phoneNumber
        self.residenceName = residenceName
        self.notes = notes
        self.decision = decision
        self.dateContacted = dateContacted
        self.appartmentNumber = appartmentNumber
        self.list = list
        self.contact = contact
        self.plan = plan
        self.followup = followup
    }
}

extension ContactAddress{
    static var emptyContactAddress: ContactAddress{
        ContactAddress(firstName: "", lastName: "", communityName: "", number: "", street: "", postCode: "", city: "", state: "", phoneNumber: "", residenceName: "", notes: "", decision: Decision.NoResponse, dateContacted: Date().formatted(date: .numeric, time: .omitted ), appartmentNumber:"", list:false, contact: false, plan: false, followup: false)
    }
    static var emptyProductDetail: ProductDetail{
        ProductDetail(name: "", code: "", price: nil, image: nil, prospect: ProductDetail.emptyProspect,paidAmount: nil,totalBalance:  nil, stateTax: nil, countyTax: nil, percentErnings: nil, notes: "")
      
    }
    var fullAddressString: String{
        "\(number) \(street) \(city) \(state) \(postCode)"
    }
    var urlEncodedAddress: String {
        let fullString = "\(number) \(street), \(city), \(state) \(postCode)"
        return fullString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
}
// ✅ Safe Production Structure: Conforms to both Codable and String RawValue mappings
enum Decision: String, CaseIterable, Identifiable, Codable {
    case Interested
    case NotInterested
    case ThinkingAboutIt 
    case IBO
    case FollowUp
    case Sale
    case Client
    case Vacant
    case NoResponse
    
    var id: Self { self }

    // 💡 Add a computed property for clean user-facing display titles
    var displayName: String {
        switch self {
        case .NotInterested: return "Not Interested"
        case .ThinkingAboutIt: return "Thinking About It"
        case .FollowUp: return "Follow Up"
        case .NoResponse: return "No Response"
        default: return self.rawValue // Keeps normal words untouched
        }
    }
}


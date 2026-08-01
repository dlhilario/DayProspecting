//
//  NotificationManager.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 6/28/26.
//

import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject{
    static let shared = NotificationManager()
    
    private init(){}
    
    // 1 Request user permission to display alerts
    func requestAuthorization(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]){ granted, error in
            if granted {
                print("DEBUG: Notification permission granted")
            }else{
                print("DEBUG: Permission error: \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
    // 2. Schedule the 24 hour follow up alert
    func scheduleFollowUpNotification(for prospect: ContactAddress){
        // Calculate the target time-interval gap (24 hours = 86,400 seconds)
        let dateFromString = ISO8601DateFormatter().date(from: prospect.dateContacted) ?? Date()
        let twentyFoundHoursInSeconds: TimeInterval = 24 * 60 * 60
        let targetDate = dateFromString.addingTimeInterval(twentyFoundHoursInSeconds)
        
        //find out how mahy seconds remain between *now* and that target date
        let timeRemaining = targetDate.timeIntervalSince(Date())
        
        //Safety check: if the contact date is already passed 24 hours, do not schedule
        guard timeRemaining > 0 else {
            print ("DEBUG: Skipped scheduling. 24-Hour mark as already passed for \(prospect.firstName)")
            return
        }
        
        //configured the visible text payload context
        let content = UNMutableNotificationContent()
        content.title = "Prospect Follow-up Alert"
        content.body = "It has been 24 hours since you contacted \(prospect.firstName) \(prospect.lastName). Update the status now!"
        content.sound = .default
       
        // Establish the delivery timing trigger engine
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeRemaining, repeats: false)
        
        //Indetify the request uniquely using the SwiftData record ID persistent string
        let identifier = prospect.persistentModelID.id.hashValue.description
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Commit the alert request senquence to the iOS daemon system
        UNUserNotificationCenter.current().add(request){ error in
            if let error = error{
                print("DEBUG: Failed to schedule alert: \(error.localizedDescription)")
            }else{
                print("DEBUG: Alert successfully schedule for \(prospect.firstName) in \(timeRemaining / 36000) hours")
            }
        }
    }
    
    // 3 cleare pending alerts if a user updates or removes a prospect record
    func cancelPendingNotification(for prospect: ContactAddress){
        let identifier = prospect.persistentModelID.id.hashValue.description
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("DEBUG: Canceled pending notification alerts for \(prospect.firstName)")
    }
}

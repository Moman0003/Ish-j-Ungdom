//
//  NotifikationService.swift
//  IshojUngdom
//
//  Service: Håndterer push-notifikationer og lokale reminders
//

import Foundation
import UserNotifications
import UIKit

class NotifikationService {
    static let shared = NotifikationService()
    
    // MARK: - Anmod om tilladelse (US 40)
    func anmodOmTilladelse() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            return granted
        } catch {
            print("Fejl ved anmodning om notifikationer: \(error)")
            return false
        }
    }
    
    // MARK: - Tjek tilladelsesstatus
    func tjekTilladelse() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Planlæg reminder for event (US 44)
    func planlaegReminder(eventId: String, eventTitel: String, eventStart: Date) {
        let center = UNUserNotificationCenter.current()
        
        // 24-timers reminder
        if let reminderTid = Calendar.current.date(byAdding: .hour, value: -24, to: eventStart),
           reminderTid > Date() {
            planlaegLokal(
                id: "reminder-24h-\(eventId)",
                titel: "I morgen: \(eventTitel)",
                body: "Husk dit event i morgen!",
                dato: reminderTid
            )
        }
        
        // 1-times reminder
        if let reminderTid = Calendar.current.date(byAdding: .hour, value: -1, to: eventStart),
           reminderTid > Date() {
            planlaegLokal(
                id: "reminder-1h-\(eventId)",
                titel: "Om 1 time: \(eventTitel)",
                body: "Dit event starter snart!",
                dato: reminderTid
            )
        }
    }
    
    func annullerReminder(eventId: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            "reminder-24h-\(eventId)",
            "reminder-1h-\(eventId)"
        ])
    }
    
    private func planlaegLokal(id: String, titel: String, body: String, dato: Date) {
        let content = UNMutableNotificationContent()
        content.title = titel
        content.body = body
        content.sound = .default
        
        let komponenter = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dato)
        let trigger = UNCalendarNotificationTrigger(dateMatching: komponenter, repeats: false)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Fejl ved planlægning: \(error)")
            }
        }
    }
}

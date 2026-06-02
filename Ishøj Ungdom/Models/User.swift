//
//  User.swift
//  IshojUngdom
//
//  Model: Bruger med profilbillede, alder, favoritter og indstillinger
//

import Foundation
import FirebaseFirestore

struct NotifikationsIndstillinger: Codable {
    var nyeEvents: Bool = true
    var eventAendringer: Bool = true
    var eventAflysning: Bool = true
    var reminders: Bool = true
    var newsfeedLikes: Bool = true
    var newsfeedKommentarer: Bool = true
}

struct AppUser: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var navn: String
    var oprettetDato: Date
    var rolle: String = "elev"
    
    // NY: Profil
    var profilBilledUrl: String?
    var alder: Int?
    
    // NY: Favoritter
    var favoritEventIds: [String] = []
    
    // NY: Onboarding
    var harSetOnboarding: Bool = false
    
    // NY: FCM device token til notifikationer
    var deviceToken: String?
    
    // NY: Notifikationsindstillinger
    var notifikationer: NotifikationsIndstillinger = NotifikationsIndstillinger()
    
    var erAdmin: Bool {
        rolle == "admin"
    }
    
    var initialer: String {
        let dele = navn.components(separatedBy: " ")
        let foerste = dele.first?.first.map(String.init) ?? ""
        let andet = dele.count > 1 ? (dele.last?.first.map(String.init) ?? "") : ""
        return (foerste + andet).uppercased()
    }
}

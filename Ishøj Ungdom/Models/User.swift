//
//  User.swift
//  IshojUngdom
//
//  Model: Repræsenterer en bruger i systemet
//

import Foundation
import FirebaseFirestore

struct AppUser: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var navn: String
    var oprettetDato: Date
    var rolle: String = "elev"   // "elev" eller "admin"
    
    // Computed property: Tjek om brugeren er admin
    var erAdmin: Bool {
        rolle == "admin"
    }
}

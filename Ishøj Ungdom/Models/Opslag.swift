//
//  Opslag.swift
//  IshojUngdom
//
//  Model: Newsfeed opslag med likes, kommentarer og multi-image support
//

import Foundation
import FirebaseFirestore

struct Opslag: Identifiable, Codable {
    @DocumentID var id: String?
    var brugerId: String
    var brugerNavn: String
    var brugerInitialer: String
    var brugerProfilBilledUrl: String?
    
    var tekst: String
    var billedUrls: [String] = []      // Multi-image support (op til 5)
    var oprettetDato: Date
    
    var erOfficiel: Bool = false       // Admin-opslag fremhævet
    var pinnedTil: Date?               // Pinned øverst indtil denne dato
    
    var likes: [String] = []            // Array af user IDs der har liket
    var antalKommentarer: Int = 0
    
    var antalLikes: Int { likes.count }
    
    func brugerHarLiket(_ brugerId: String) -> Bool {
        likes.contains(brugerId)
    }
    
    var erPinned: Bool {
        guard let pin = pinnedTil else { return false }
        return Date() < pin
    }
}

struct Kommentar: Identifiable, Codable {
    @DocumentID var id: String?
    var opslagId: String
    var brugerId: String
    var brugerNavn: String
    var brugerInitialer: String
    var brugerProfilBilledUrl: String?
    var tekst: String
    var oprettetDato: Date
}

//
//  Event.swift
//  IshojUngdom
//
//  Model: Event med Cloudinary billedURLs
//

import Foundation
import FirebaseFirestore

struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    
    // Grundlæggende
    var titel: String
    var beskrivelse: String
    var lokation: String
    var farveTag: String
    var billedUrl: String?           // Cloudinary URL
    
    // Tid
    var startDato: Date
    var slutDato: Date?
    var ugedag: String?
    var tidspunkt: String?
    
    // Deltagere
    var maxDeltagere: Int
    var antalTilmeldte: Int
    var aldersgruppeMin: Int
    var aldersgruppeMax: Int
    var kraeverTilmelding: Bool
    
    // Underviser
    var underviserNavn: String?
    var underviserBeskrivelse: String?
    var underviserBilledUrl: String? // Cloudinary URL
    
    // Computed properties
    var erFuldtBooket: Bool {
        kraeverTilmelding && antalTilmeldte >= maxDeltagere
    }
    
    var ledigPladser: Int {
        max(0, maxDeltagere - antalTilmeldte)
    }
    
    var aldersgruppeTekst: String {
        "\(aldersgruppeMin)-\(aldersgruppeMax) år"
    }
}

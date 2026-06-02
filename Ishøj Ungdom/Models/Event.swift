//
//  Event.swift
//  IshojUngdom
//
//  Model: Event med alle udvidelser (pakkeliste, kategori, status, feedback)
//

import Foundation
import FirebaseFirestore

enum EventStatus: String, Codable, CaseIterable {
    case aaben = "Åben"
    case faaPladser = "Få pladser"
    case lukket = "Lukket"
    case aflyst = "Aflyst"
    
    var farve: String {
        switch self {
        case .aaben: return "green"
        case .faaPladser: return "orange"
        case .lukket: return "gray"
        case .aflyst: return "red"
        }
    }
}

struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    
    // Grundlæggende
    var titel: String
    var beskrivelse: String
    var lokation: String
    var farveTag: String
    var billedUrl: String?
    var kategori: String?              // NY: "Sport", "Kreativt", "Gaming", "Mad" osv.
    
    // Tid
    var startDato: Date
    var slutDato: Date?
    var ugedag: String?
    var tidspunkt: String?
    var feedbackLukkerDato: Date?      // NY: Hvornår feedback lukker
    
    // Deltagere
    var maxDeltagere: Int
    var antalTilmeldte: Int
    var aldersgruppeMin: Int
    var aldersgruppeMax: Int
    var kraeverTilmelding: Bool
    
    // Underviser
    var underviserNavn: String?
    var underviserBeskrivelse: String?
    var underviserBilledUrl: String?
    
    // NY: Pakkeliste
    var pakkeliste: [String]?
    
    // NY: Status (gemmes som rawValue)
    var status: String?
    
    // Computed properties
    var eventStatus: EventStatus {
        if let s = status, let parsed = EventStatus(rawValue: s) { return parsed }
        // Auto-bereging hvis status ikke er sat
        if !kraeverTilmelding { return .aaben }
        if antalTilmeldte >= maxDeltagere { return .lukket }
        if (maxDeltagere - antalTilmeldte) < 5 { return .faaPladser }
        return .aaben
    }
    
    var erAflyst: Bool { eventStatus == .aflyst }
    
    var erFuldtBooket: Bool {
        kraeverTilmelding && antalTilmeldte >= maxDeltagere
    }
    
    var ledigPladser: Int {
        max(0, maxDeltagere - antalTilmeldte)
    }
    
    var aldersgruppeTekst: String {
        "\(aldersgruppeMin)-\(aldersgruppeMax) år"
    }
    
    var erFaerdigtAfholdt: Bool {
        let slutTid = slutDato ?? startDato
        return Date() > slutTid
    }
    
    var kanGivesFeedback: Bool {
        guard erFaerdigtAfholdt else { return false }
        if let lukker = feedbackLukkerDato {
            return Date() < lukker
        }
        return true
    }
}

// Kategorier - statisk liste til UI
struct EventKategori {
    static let alle = ["Sport", "Kreativt", "Gaming", "Mad", "Udflugt", "Værksted", "Andet"]
}

//
//  Vurdering.swift
//  IshojUngdom
//
//  Model: Vurderinger, beskeder og venteliste
//

import Foundation
import FirebaseFirestore

// MARK: - Vurdering af event
struct Vurdering: Identifiable, Codable {
    @DocumentID var id: String?
    var eventId: String
    var brugerId: String
    var brugerFornavn: String           // Vises anonymiseret
    var stjerner: Int                    // 1-5
    var kommentar: String?
    var oprettetDato: Date
}

// MARK: - Besked fra admin til tilmeldte
struct Besked: Identifiable, Codable {
    @DocumentID var id: String?
    var eventId: String
    var eventTitel: String
    var afsenderNavn: String
    var tekst: String
    var modtagerIds: [String]            // Brugere der skal modtage
    var sendtDato: Date
    var laestAf: [String] = []           // User IDs der har læst
}

// MARK: - Venteliste
struct Venteliste: Identifiable, Codable {
    @DocumentID var id: String?
    var eventId: String
    var brugerId: String
    var brugerNavn: String
    var position: Int                    // Plads i køen
    var tilfojetDato: Date
}

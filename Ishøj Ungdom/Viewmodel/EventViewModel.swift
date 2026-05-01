//
//  EventViewModel.swift
//  IshojUngdom
//
//  ViewModel: Håndterer events fra Firestore med admin CRUD
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class EventViewModel: ObservableObject {
    
    @Published var events: [Event] = []
    @Published var brugerensBookings: [String] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    private let db = Firestore.firestore()
    
    // MARK: - Hent events
    func hentEvents() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let snapshot = try await db.collection("events")
                .order(by: "startDato", descending: false)
                .getDocuments()
            
            self.events = snapshot.documents.compactMap { doc in
                try? doc.data(as: Event.self)
            }
        } catch {
            self.errorMessage = "Kunne ikke hente events: \(error.localizedDescription)"
            print("Fejl: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Bookings
    func hentBrugerensBookings(brugerId: String) async {
        do {
            let snapshot = try await db.collection("bookings")
                .whereField("brugerId", isEqualTo: brugerId)
                .getDocuments()
            
            self.brugerensBookings = snapshot.documents.compactMap {
                $0.data()["eventId"] as? String
            }
        } catch {
            print("Fejl ved hentning af bookings: \(error)")
        }
    }
    
    func erTilmeldt(eventId: String) -> Bool {
        brugerensBookings.contains(eventId)
    }
    
    func tilmeldBruger(eventId: String, brugerId: String) async -> Bool {
        if erTilmeldt(eventId: eventId) {
            self.errorMessage = "Du er allerede tilmeldt dette event"
            return false
        }
        
        do {
            let booking: [String: Any] = [
                "eventId": eventId,
                "brugerId": brugerId,
                "tilmeldtDato": Timestamp(date: Date())
            ]
            try await db.collection("bookings").addDocument(data: booking)
            
            try await db.collection("events").document(eventId).updateData([
                "antalTilmeldte": FieldValue.increment(Int64(1))
            ])
            
            await hentEvents()
            await hentBrugerensBookings(brugerId: brugerId)
            return true
        } catch {
            self.errorMessage = "Kunne ikke tilmelde: \(error.localizedDescription)"
            return false
        }
    }
    
    func afmeldBruger(eventId: String, brugerId: String) async -> Bool {
        do {
            let snapshot = try await db.collection("bookings")
                .whereField("brugerId", isEqualTo: brugerId)
                .whereField("eventId", isEqualTo: eventId)
                .getDocuments()
            
            for doc in snapshot.documents {
                try await doc.reference.delete()
            }
            
            try await db.collection("events").document(eventId).updateData([
                "antalTilmeldte": FieldValue.increment(Int64(-1))
            ])
            
            await hentEvents()
            await hentBrugerensBookings(brugerId: brugerId)
            return true
        } catch {
            self.errorMessage = "Kunne ikke afmelde: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Admin CRUD
    func opretEvent(_ event: Event) async -> Bool {
        do {
            let data = lavEventData(event, includeAntalTilmeldte: true)
            try await db.collection("events").addDocument(data: data)
            await hentEvents()
            return true
        } catch {
            self.errorMessage = "Kunne ikke oprette: \(error.localizedDescription)"
            return false
        }
    }
    
    func opdaterEvent(_ event: Event) async -> Bool {
        guard let id = event.id else { return false }
        
        do {
            let data = lavEventData(event, includeAntalTilmeldte: false)
            try await db.collection("events").document(id).updateData(data)
            await hentEvents()
            return true
        } catch {
            self.errorMessage = "Kunne ikke opdatere: \(error.localizedDescription)"
            return false
        }
    }
    
    func sletEvent(eventId: String) async -> Bool {
        do {
            try await db.collection("events").document(eventId).delete()
            
            // Slet relaterede bookings
            let bookingsSnapshot = try await db.collection("bookings")
                .whereField("eventId", isEqualTo: eventId)
                .getDocuments()
            
            for doc in bookingsSnapshot.documents {
                try await doc.reference.delete()
            }
            
            await hentEvents()
            return true
        } catch {
            self.errorMessage = "Kunne ikke slette: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Hjælper: Konverter Event til Firestore data
    private func lavEventData(_ event: Event, includeAntalTilmeldte: Bool) -> [String: Any] {
        var data: [String: Any] = [
            "titel": event.titel,
            "beskrivelse": event.beskrivelse,
            "lokation": event.lokation,
            "farveTag": event.farveTag,
            "startDato": Timestamp(date: event.startDato),
            "maxDeltagere": event.maxDeltagere,
            "aldersgruppeMin": event.aldersgruppeMin,
            "aldersgruppeMax": event.aldersgruppeMax,
            "kraeverTilmelding": event.kraeverTilmelding,
            "billedUrl": event.billedUrl ?? ""
        ]
        
        if includeAntalTilmeldte {
            data["antalTilmeldte"] = 0
        }
        
        if let slutDato = event.slutDato {
            data["slutDato"] = Timestamp(date: slutDato)
        }
        if let ugedag = event.ugedag, !ugedag.isEmpty {
            data["ugedag"] = ugedag
        }
        if let tidspunkt = event.tidspunkt, !tidspunkt.isEmpty {
            data["tidspunkt"] = tidspunkt
        }
        if let underviserNavn = event.underviserNavn, !underviserNavn.isEmpty {
            data["underviserNavn"] = underviserNavn
        }
        if let underviserBeskrivelse = event.underviserBeskrivelse, !underviserBeskrivelse.isEmpty {
            data["underviserBeskrivelse"] = underviserBeskrivelse
        }
        if let underviserBilledUrl = event.underviserBilledUrl, !underviserBilledUrl.isEmpty {
            data["underviserBilledUrl"] = underviserBilledUrl
        }
        
        return data
    }
}

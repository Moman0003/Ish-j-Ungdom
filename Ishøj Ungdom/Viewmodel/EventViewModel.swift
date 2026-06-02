//
//  EventViewModel.swift
//  IshojUngdom
//
//  ViewModel: Events med alle Sprint 3-6 features
//  - CRUD events med pakkeliste, kategori, status
//  - Tilmelding, afmelding, venteliste
//  - Vurderinger, beskeder
//  - Filter funktionalitet
//

import Foundation
import Combine
import FirebaseFirestore

enum DatoFilter: String, CaseIterable {
    case alle = "Alle"
    case dennesUge = "Denne uge"
    case dennesMaaned = "Denne måned"
}

@MainActor
class EventViewModel: ObservableObject {
    
    @Published var events: [Event] = []
    @Published var brugerensBookings: [String] = []
    @Published var brugerensVentelister: [String] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    // Filtre
    @Published var filterAldersgruppe: Bool = false
    @Published var filterDato: DatoFilter = .alle
    @Published var filterKategorier: Set<String> = []
    
    private let db = Firestore.firestore()
    private var eventsListener: ListenerRegistration?
    
    deinit {
        eventsListener?.remove()
    }
    
    // MARK: - Filtrerede events (computed)
    func filtreredeEvents(brugerAlder: Int?) -> [Event] {
        var resultat = events
        
        // Aldersfilter
        if filterAldersgruppe, let alder = brugerAlder {
            resultat = resultat.filter { e in
                alder >= e.aldersgruppeMin && alder <= e.aldersgruppeMax
            }
        }
        
        // Datofilter
        let kalender = Calendar.current
        let nu = Date()
        switch filterDato {
        case .dennesUge:
            if let ugeSlut = kalender.date(byAdding: .day, value: 7, to: nu) {
                resultat = resultat.filter { $0.startDato >= nu && $0.startDato <= ugeSlut }
            }
        case .dennesMaaned:
            if let maanedSlut = kalender.date(byAdding: .month, value: 1, to: nu) {
                resultat = resultat.filter { $0.startDato >= nu && $0.startDato <= maanedSlut }
            }
        case .alle:
            break
        }
        
        // Kategorifilter
        if !filterKategorier.isEmpty {
            resultat = resultat.filter { e in
                guard let k = e.kategori else { return false }
                return filterKategorier.contains(k)
            }
        }
        
        return resultat
    }
    
    func nulstilFiltre() {
        filterAldersgruppe = false
        filterDato = .alle
        filterKategorier = []
    }
    
    // MARK: - Hent events (med realtime listener)
    func startLytterPaaEvents() {
        eventsListener?.remove()
        
        eventsListener = db.collection("events")
            .order(by: "startDato", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let docs = snapshot?.documents else { return }
                Task { @MainActor in
                    self.events = docs.compactMap { try? $0.data(as: Event.self) }
                }
            }
    }
    
    func hentEvents() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let snapshot = try await db.collection("events")
                .order(by: "startDato", descending: false)
                .getDocuments()
            self.events = snapshot.documents.compactMap { try? $0.data(as: Event.self) }
        } catch {
            self.errorMessage = "Kunne ikke hente events: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Bookings
    func hentBrugerensBookings(brugerId: String) async {
        do {
            let snapshot = try await db.collection("bookings")
                .whereField("brugerId", isEqualTo: brugerId)
                .getDocuments()
            self.brugerensBookings = snapshot.documents.compactMap { $0.data()["eventId"] as? String }
            
            // Hent også ventelister
            let ventelisteSnap = try await db.collection("venteliste")
                .whereField("brugerId", isEqualTo: brugerId)
                .getDocuments()
            self.brugerensVentelister = ventelisteSnap.documents.compactMap { $0.data()["eventId"] as? String }
        } catch {
            print("Fejl ved hentning af bookings: \(error)")
        }
    }
    
    func hentMineTilmeldinger(brugerId: String) async -> [Event] {
        do {
            let snapshot = try await db.collection("bookings")
                .whereField("brugerId", isEqualTo: brugerId)
                .getDocuments()
            
            let eventIds = snapshot.documents.compactMap { $0.data()["eventId"] as? String }
            
            var mineEvents: [Event] = []
            for eventId in eventIds {
                let doc = try await db.collection("events").document(eventId).getDocument()
                if let event = try? doc.data(as: Event.self) {
                    mineEvents.append(event)
                }
            }
            
            return mineEvents.sorted { $0.startDato < $1.startDato }
        } catch {
            return []
        }
    }
    
    func erTilmeldt(eventId: String) -> Bool {
        brugerensBookings.contains(eventId)
    }
    
    func erPaaVenteliste(eventId: String) -> Bool {
        brugerensVentelister.contains(eventId)
    }
    
    func tilmeldBruger(eventId: String, brugerId: String) async -> Bool {
        if erTilmeldt(eventId: eventId) {
            self.errorMessage = "Du er allerede tilmeldt"
            return false
        }
        do {
            try await db.collection("bookings").addDocument(data: [
                "eventId": eventId,
                "brugerId": brugerId,
                "tilmeldtDato": Timestamp(date: Date())
            ])
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
            for doc in snapshot.documents { try await doc.reference.delete() }
            try await db.collection("events").document(eventId).updateData([
                "antalTilmeldte": FieldValue.increment(Int64(-1))
            ])
            
            // Ryk første person på ventelisten op
            await rykVentelisteOp(eventId: eventId)
            
            await hentEvents()
            await hentBrugerensBookings(brugerId: brugerId)
            return true
        } catch {
            self.errorMessage = "Kunne ikke afmelde: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Venteliste
    func tilmeldVenteliste(eventId: String, brugerId: String, brugerNavn: String) async -> Bool {
        do {
            // Find næste position i køen
            let snapshot = try await db.collection("venteliste")
                .whereField("eventId", isEqualTo: eventId)
                .getDocuments()
            let nyPosition = snapshot.documents.count + 1
            
            try await db.collection("venteliste").addDocument(data: [
                "eventId": eventId,
                "brugerId": brugerId,
                "brugerNavn": brugerNavn,
                "position": nyPosition,
                "tilfojetDato": Timestamp(date: Date())
            ])
            
            await hentBrugerensBookings(brugerId: brugerId)
            return true
        } catch {
            self.errorMessage = "Kunne ikke tilmelde venteliste: \(error.localizedDescription)"
            return false
        }
    }
    
    func forladVenteliste(eventId: String, brugerId: String) async -> Bool {
        do {
            let snapshot = try await db.collection("venteliste")
                .whereField("eventId", isEqualTo: eventId)
                .whereField("brugerId", isEqualTo: brugerId)
                .getDocuments()
            for doc in snapshot.documents { try await doc.reference.delete() }
            
            await hentBrugerensBookings(brugerId: brugerId)
            return true
        } catch {
            return false
        }
    }
    
    private func rykVentelisteOp(eventId: String) async {
        do {
            let snapshot = try await db.collection("venteliste")
                .whereField("eventId", isEqualTo: eventId)
                .order(by: "position")
                .limit(to: 1)
                .getDocuments()
            
            guard let foersteDoc = snapshot.documents.first,
                  let brugerId = foersteDoc.data()["brugerId"] as? String else { return }
            
            // Tilmeld brugeren
            try await db.collection("bookings").addDocument(data: [
                "eventId": eventId,
                "brugerId": brugerId,
                "tilmeldtDato": Timestamp(date: Date())
            ])
            try await db.collection("events").document(eventId).updateData([
                "antalTilmeldte": FieldValue.increment(Int64(1))
            ])
            
            // Fjern fra venteliste
            try await foersteDoc.reference.delete()
        } catch {
            print("Fejl ved venteliste-rykning: \(error)")
        }
    }
    
    // MARK: - Admin CRUD
    func opretEvent(_ event: Event) async -> Bool {
        do {
            let data = lavEventData(event, nyt: true)
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
            let data = lavEventData(event, nyt: false)
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
            // Slet relaterede bookings, ventelister, vurderinger
            for collection in ["bookings", "venteliste", "vurderinger"] {
                let snap = try await db.collection(collection)
                    .whereField("eventId", isEqualTo: eventId)
                    .getDocuments()
                for doc in snap.documents { try await doc.reference.delete() }
            }
            await hentEvents()
            return true
        } catch {
            return false
        }
    }
    
    func opdaterStatus(eventId: String, status: EventStatus) async -> Bool {
        do {
            try await db.collection("events").document(eventId).updateData([
                "status": status.rawValue
            ])
            await hentEvents()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Hent tilmeldte til event (admin)
    func hentTilmeldte(eventId: String) async -> [(navn: String, email: String, alder: Int?, tilmeldt: Date)] {
        do {
            let snapshot = try await db.collection("bookings")
                .whereField("eventId", isEqualTo: eventId)
                .getDocuments()
            
            var resultat: [(String, String, Int?, Date)] = []
            for doc in snapshot.documents {
                guard let brugerId = doc.data()["brugerId"] as? String else { continue }
                let tilmeldt = (doc.data()["tilmeldtDato"] as? Timestamp)?.dateValue() ?? Date()
                
                let brugerDoc = try await db.collection("users").document(brugerId).getDocument()
                if let bruger = try? brugerDoc.data(as: AppUser.self) {
                    resultat.append((bruger.navn, bruger.email, bruger.alder, tilmeldt))
                }
            }
            return resultat
        } catch {
            return []
        }
    }
    
    // MARK: - Admin fjerner en tilmeldt
    func fjernTilmeldt(eventId: String, brugerId: String) async -> Bool {
        return await afmeldBruger(eventId: eventId, brugerId: brugerId)
    }
    
    // MARK: - Byg Firestore data
    private func lavEventData(_ event: Event, nyt: Bool) -> [String: Any] {
        var data: [String: Any] = [
            "titel": event.titel,
            "beskrivelse": event.beskrivelse,
            "lokation": event.lokation,
            "farveTag": event.farveTag,
            "startDato": Timestamp(date: event.startDato),
            "maxDeltagere": event.maxDeltagere,
            "aldersgruppeMin": event.aldersgruppeMin,
            "aldersgruppeMax": event.aldersgruppeMax,
            "kraeverTilmelding": event.kraeverTilmelding
        ]
        if nyt { data["antalTilmeldte"] = 0 }
        
        data["billedUrl"] = event.billedUrl ?? ""
        data["underviserBilledUrl"] = event.underviserBilledUrl ?? ""
        
        if let v = event.slutDato { data["slutDato"] = Timestamp(date: v) }
        if let v = event.ugedag, !v.isEmpty { data["ugedag"] = v }
        if let v = event.tidspunkt, !v.isEmpty { data["tidspunkt"] = v }
        if let v = event.underviserNavn, !v.isEmpty { data["underviserNavn"] = v }
        if let v = event.underviserBeskrivelse, !v.isEmpty { data["underviserBeskrivelse"] = v }
        if let v = event.kategori, !v.isEmpty { data["kategori"] = v }
        if let v = event.pakkeliste, !v.isEmpty { data["pakkeliste"] = v }
        if let v = event.status { data["status"] = v }
        if let v = event.feedbackLukkerDato { data["feedbackLukkerDato"] = Timestamp(date: v) }
        
        return data
    }
}

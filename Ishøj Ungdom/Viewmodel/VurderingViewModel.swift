//
//  VurderingViewModel.swift
//  IshojUngdom
//
//  ViewModel: Vurderinger og admin beskeder
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class VurderingViewModel: ObservableObject {
    
    @Published var vurderinger: [Vurdering] = []
    @Published var harAfgivetVurdering: Bool = false
    
    private let db = Firestore.firestore()
    
    // MARK: - Hent vurderinger for event
    func hentVurderinger(eventId: String) async {
        do {
            // Undgår composite index ved at sortere i kode
            let snapshot = try await db.collection("vurderinger")
                .whereField("eventId", isEqualTo: eventId)
                .getDocuments()
            let hentede = snapshot.documents.compactMap { try? $0.data(as: Vurdering.self) }
            self.vurderinger = hentede.sorted { $0.oprettetDato > $1.oprettetDato }
        } catch {
            print("Fejl ved hentning af vurderinger: \(error)")
        }
    }
    
    // MARK: - Beregn gennemsnit
    var gennemsnit: Double {
        guard !vurderinger.isEmpty else { return 0 }
        let sum = vurderinger.reduce(0) { $0 + $1.stjerner }
        return Double(sum) / Double(vurderinger.count)
    }
    
    // MARK: - Tjek om bruger har afgivet vurdering
    func harBrugerAfgivetVurdering(eventId: String, brugerId: String) async -> Bool {
        do {
            let snapshot = try await db.collection("vurderinger")
                .whereField("eventId", isEqualTo: eventId)
                .whereField("brugerId", isEqualTo: brugerId)
                .getDocuments()
            return !snapshot.documents.isEmpty
        } catch {
            return false
        }
    }
    
    // MARK: - Afgiv vurdering
    func afgivVurdering(
        eventId: String,
        brugerId: String,
        brugerFornavn: String,
        stjerner: Int,
        kommentar: String?
    ) async -> Bool {
        if await harBrugerAfgivetVurdering(eventId: eventId, brugerId: brugerId) {
            return false
        }
        
        do {
            var data: [String: Any] = [
                "eventId": eventId,
                "brugerId": brugerId,
                "brugerFornavn": brugerFornavn,
                "stjerner": stjerner,
                "oprettetDato": Timestamp(date: Date())
            ]
            if let k = kommentar, !k.isEmpty { data["kommentar"] = k }
            
            try await db.collection("vurderinger").addDocument(data: data)
            await hentVurderinger(eventId: eventId)
            return true
        } catch {
            return false
        }
    }
}

@MainActor
class BeskedViewModel: ObservableObject {
    
    @Published var beskeder: [Besked] = []
    
    private let db = Firestore.firestore()
    
    // MARK: - Send besked til alle tilmeldte
    func sendBesked(
        eventId: String,
        eventTitel: String,
        afsenderNavn: String,
        tekst: String
    ) async -> Bool {
        do {
            // Hent alle tilmeldte
            let bookingsSnap = try await db.collection("bookings")
                .whereField("eventId", isEqualTo: eventId)
                .getDocuments()
            
            let modtagerIds = bookingsSnap.documents.compactMap { $0.data()["brugerId"] as? String }
            
            try await db.collection("beskeder").addDocument(data: [
                "eventId": eventId,
                "eventTitel": eventTitel,
                "afsenderNavn": afsenderNavn,
                "tekst": tekst,
                "modtagerIds": modtagerIds,
                "sendtDato": Timestamp(date: Date()),
                "laestAf": []
            ])
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Hent brugerens beskeder
    func hentBeskeder(brugerId: String) async {
        do {
            let snapshot = try await db.collection("beskeder")
                .whereField("modtagerIds", arrayContains: brugerId)
                .getDocuments()
            let hentede = snapshot.documents.compactMap { try? $0.data(as: Besked.self) }
            self.beskeder = hentede.sorted { $0.sendtDato > $1.sendtDato }
        } catch {
            print("Fejl: \(error)")
        }
    }
    
    // MARK: - Markér som læst
    func markeerLaest(beskedId: String, brugerId: String) async {
        do {
            try await db.collection("beskeder").document(beskedId).updateData([
                "laestAf": FieldValue.arrayUnion([brugerId])
            ])
        } catch {
            print("Fejl: \(error)")
        }
    }
}

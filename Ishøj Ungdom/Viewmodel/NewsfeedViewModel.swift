//
//  NewsfeedViewModel.swift
//  IshojUngdom
//
//  ViewModel: Newsfeed med opslag, likes og kommentarer
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class NewsfeedViewModel: ObservableObject {
    
    @Published var opslag: [Opslag] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    // MARK: - Hent alle opslag
    func hentOpslag() async {
        isLoading = true
        
        do {
            let snapshot = try await db.collection("opslag")
                .order(by: "oprettetDato", descending: true)
                .getDocuments()
            
            var allePosts = snapshot.documents.compactMap { try? $0.data(as: Opslag.self) }
            
            // Sortér: pinned øverst, derefter kronologisk
            allePosts.sort { p1, p2 in
                if p1.erPinned && !p2.erPinned { return true }
                if !p1.erPinned && p2.erPinned { return false }
                return p1.oprettetDato > p2.oprettetDato
            }
            
            self.opslag = allePosts
        } catch {
            self.errorMessage = "Kunne ikke hente opslag: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Opret nyt opslag
    func opretOpslag(
        tekst: String,
        billedUrls: [String],
        bruger: AppUser,
        erOfficiel: Bool
    ) async -> Bool {
        guard let brugerId = bruger.id else { return false }
        
        do {
            var data: [String: Any] = [
                "brugerId": brugerId,
                "brugerNavn": bruger.navn,
                "brugerInitialer": bruger.initialer,
                "tekst": tekst,
                "billedUrls": billedUrls,
                "oprettetDato": Timestamp(date: Date()),
                "erOfficiel": erOfficiel,
                "likes": [],
                "antalKommentarer": 0
            ]
            
            if let pb = bruger.profilBilledUrl, !pb.isEmpty {
                data["brugerProfilBilledUrl"] = pb
            }
            
            // Hvis officielt: pin i 24 timer
            if erOfficiel {
                let pinTil = Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date()
                data["pinnedTil"] = Timestamp(date: pinTil)
            }
            
            try await db.collection("opslag").addDocument(data: data)
            await hentOpslag()
            return true
        } catch {
            self.errorMessage = "Kunne ikke oprette opslag: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Slet opslag
    func sletOpslag(opslag: Opslag, currentUserId: String, erAdmin: Bool) async -> Bool {
        guard let id = opslag.id else { return false }
        // Bruger kan slette egne, admin kan slette alle
        guard opslag.brugerId == currentUserId || erAdmin else {
            self.errorMessage = "Du har ikke tilladelse til at slette dette opslag"
            return false
        }
        
        do {
            // Slet alle kommentarer først
            let kommentarSnap = try await db.collection("kommentarer")
                .whereField("opslagId", isEqualTo: id)
                .getDocuments()
            for doc in kommentarSnap.documents { try await doc.reference.delete() }
            
            try await db.collection("opslag").document(id).delete()
            await hentOpslag()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Like/unlike
    func toggleLike(opslagId: String, brugerId: String) async {
        do {
            let docRef = db.collection("opslag").document(opslagId)
            let doc = try await docRef.getDocument()
            
            if var data = doc.data(),
               var likes = data["likes"] as? [String] {
                if likes.contains(brugerId) {
                    likes.removeAll { $0 == brugerId }
                } else {
                    likes.append(brugerId)
                }
                try await docRef.updateData(["likes": likes])
                await hentOpslag()
            }
        } catch {
            print("Like fejl: \(error)")
        }
    }
    
    // MARK: - Kommentarer
    func hentKommentarer(opslagId: String) async -> [Kommentar] {
        do {
            // Bemærk: vi undgår .order(by:) her fordi kombinationen whereField + orderBy
            // kræver et composite index i Firestore. Vi sorterer i stedet i koden.
            let snapshot = try await db.collection("kommentarer")
                .whereField("opslagId", isEqualTo: opslagId)
                .getDocuments()
            let kommentarer = snapshot.documents.compactMap { try? $0.data(as: Kommentar.self) }
            return kommentarer.sorted { $0.oprettetDato < $1.oprettetDato }
        } catch {
            print("Fejl ved hentning af kommentarer: \(error)")
            return []
        }
    }
    
    func opretKommentar(opslagId: String, tekst: String, bruger: AppUser) async -> Bool {
        guard let brugerId = bruger.id else { return false }
        
        do {
            var data: [String: Any] = [
                "opslagId": opslagId,
                "brugerId": brugerId,
                "brugerNavn": bruger.navn,
                "brugerInitialer": bruger.initialer,
                "tekst": tekst,
                "oprettetDato": Timestamp(date: Date())
            ]
            if let pb = bruger.profilBilledUrl { data["brugerProfilBilledUrl"] = pb }
            
            try await db.collection("kommentarer").addDocument(data: data)
            
            // Opdater antal kommentarer på opslaget
            try await db.collection("opslag").document(opslagId).updateData([
                "antalKommentarer": FieldValue.increment(Int64(1))
            ])
            
            return true
        } catch {
            return false
        }
    }
    
    func sletKommentar(kommentar: Kommentar, currentUserId: String, erAdmin: Bool) async -> Bool {
        guard let id = kommentar.id else { return false }
        guard kommentar.brugerId == currentUserId || erAdmin else { return false }
        
        do {
            try await db.collection("kommentarer").document(id).delete()
            try await db.collection("opslag").document(kommentar.opslagId).updateData([
                "antalKommentarer": FieldValue.increment(Int64(-1))
            ])
            return true
        } catch {
            return false
        }
    }
}

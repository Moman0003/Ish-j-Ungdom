//
//  AuthViewModel.swift
//  IshojUngdom
//
//  ViewModel: Authentication + Sprint 5 udvidelser
//  - Glemt adgangskode
//  - Slet konto (GDPR)
//  - Favoritter
//  - Profilbillede
//  - Notifikationsindstillinger
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
    
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: AppUser?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var infoMessage: String?
    
    private let db = Firestore.firestore()
    
    init() {
        self.userSession = Auth.auth().currentUser
        Task { await fetchUser() }
    }
    
    // MARK: - Login
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            await fetchUser()
        } catch {
            self.errorMessage = oversaetFejl(error)
        }
        isLoading = false
    }
    
    // MARK: - Opret bruger
    func opretBruger(email: String, password: String, navn: String, alder: Int?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            
            let nyBruger = AppUser(
                id: result.user.uid,
                email: email,
                navn: navn,
                oprettetDato: Date(),
                alder: alder
            )
            
            try db.collection("users").document(result.user.uid).setData(from: nyBruger)
            self.currentUser = nyBruger
        } catch {
            self.errorMessage = oversaetFejl(error)
        }
        isLoading = false
    }
    
    // MARK: - Log ud
    func logUd() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
        } catch {
            self.errorMessage = "Kunne ikke logge ud"
        }
    }
    
    // MARK: - Glemt adgangskode
    func sendNulstilEmail(email: String) async -> Bool {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            self.infoMessage = "Vi har sendt en email til \(email) med instruktioner."
            return true
        } catch {
            self.errorMessage = oversaetFejl(error)
            return false
        }
    }
    
    // MARK: - Slet konto
    func sletKonto(password: String) async -> Bool {
        guard let bruger = Auth.auth().currentUser,
              let brugerId = currentUser?.id,
              let email = currentUser?.email else { return false }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Re-autenticer for sikkerhed (dette SKAL lykkes)
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            try await bruger.reauthenticate(with: credential)
        } catch {
            // Hvis reauth fejler er det næsten altid forkert adgangskode
            self.errorMessage = "Forkert adgangskode. Prøv igen."
            isLoading = false
            return false
        }
        
        // Slet relaterede data som "best effort" - hvis en enkelt sletning
        // fejler (fx pga. security rules), fortsætter vi alligevel så selve
        // kontoen stadig kan slettes.
        await sletBrugerData(brugerId: brugerId)
        
        do {
            // Slet user-dokument
            try await db.collection("users").document(brugerId).delete()
        } catch {
            print("Kunne ikke slette user-dokument: \(error)")
        }
        
        // Slet selve Auth-kontoen (det vigtigste)
        do {
            try await bruger.delete()
            self.userSession = nil
            self.currentUser = nil
            isLoading = false
            return true
        } catch {
            self.errorMessage = "Kunne ikke slette konto: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // Sletter brugerens data fra alle collections - best effort
    private func sletBrugerData(brugerId: String) async {
        // Bookings
        await sletDokumenter(collection: "bookings", felt: "brugerId", vaerdi: brugerId)
        // Ventelister
        await sletDokumenter(collection: "venteliste", felt: "brugerId", vaerdi: brugerId)
        // Brugerens kommentarer
        await sletDokumenter(collection: "kommentarer", felt: "brugerId", vaerdi: brugerId)
        // Vurderinger
        await sletDokumenter(collection: "vurderinger", felt: "brugerId", vaerdi: brugerId)
        
        // Opslag og deres kommentarer
        do {
            let opslag = try await db.collection("opslag")
                .whereField("brugerId", isEqualTo: brugerId).getDocuments()
            for doc in opslag.documents {
                let kommentarer = try? await db.collection("kommentarer")
                    .whereField("opslagId", isEqualTo: doc.documentID).getDocuments()
                if let kommentarer = kommentarer {
                    for k in kommentarer.documents { try? await k.reference.delete() }
                }
                try? await doc.reference.delete()
            }
        } catch {
            print("Kunne ikke slette opslag: \(error)")
        }
    }
    
    private func sletDokumenter(collection: String, felt: String, vaerdi: String) async {
        do {
            let snapshot = try await db.collection(collection)
                .whereField(felt, isEqualTo: vaerdi).getDocuments()
            for doc in snapshot.documents { try? await doc.reference.delete() }
        } catch {
            print("Kunne ikke slette fra \(collection): \(error)")
        }
    }
    
    // MARK: - Favoritter (US 49)
    func toggleFavorit(eventId: String) async {
        guard let brugerId = currentUser?.id else { return }
        
        var nyeFavoritter = currentUser?.favoritEventIds ?? []
        if nyeFavoritter.contains(eventId) {
            nyeFavoritter.removeAll { $0 == eventId }
        } else {
            nyeFavoritter.append(eventId)
        }
        
        do {
            try await db.collection("users").document(brugerId).updateData([
                "favoritEventIds": nyeFavoritter
            ])
            currentUser?.favoritEventIds = nyeFavoritter
        } catch {
            print("Fejl: \(error)")
        }
    }
    
    func erFavorit(_ eventId: String) -> Bool {
        currentUser?.favoritEventIds.contains(eventId) ?? false
    }
    
    // MARK: - Opdater profilbillede (US 47)
    func opdaterProfilBillede(url: String) async -> Bool {
        guard let brugerId = currentUser?.id else { return false }
        do {
            try await db.collection("users").document(brugerId).updateData([
                "profilBilledUrl": url
            ])
            currentUser?.profilBilledUrl = url
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Opdater profil (navn, alder)
    func opdaterProfil(navn: String, alder: Int?) async -> Bool {
        guard let brugerId = currentUser?.id else { return false }
        do {
            var update: [String: Any] = ["navn": navn]
            if let a = alder { update["alder"] = a }
            
            try await db.collection("users").document(brugerId).updateData(update)
            currentUser?.navn = navn
            currentUser?.alder = alder
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Markér onboarding som set (US 48)
    func markerOnboardingSet() async {
        guard let brugerId = currentUser?.id else { return }
        do {
            try await db.collection("users").document(brugerId).updateData([
                "harSetOnboarding": true
            ])
            currentUser?.harSetOnboarding = true
        } catch {
            print("Fejl: \(error)")
        }
    }
    
    // MARK: - Notifikationsindstillinger (US 59)
    func opdaterNotifikationsIndstillinger(_ indstillinger: NotifikationsIndstillinger) async {
        guard let brugerId = currentUser?.id else { return }
        do {
            let data: [String: Any] = [
                "notifikationer": [
                    "nyeEvents": indstillinger.nyeEvents,
                    "eventAendringer": indstillinger.eventAendringer,
                    "eventAflysning": indstillinger.eventAflysning,
                    "reminders": indstillinger.reminders,
                    "newsfeedLikes": indstillinger.newsfeedLikes,
                    "newsfeedKommentarer": indstillinger.newsfeedKommentarer
                ]
            ]
            try await db.collection("users").document(brugerId).updateData(data)
            currentUser?.notifikationer = indstillinger
        } catch {
            print("Fejl: \(error)")
        }
    }
    
    // MARK: - Gem device token til FCM (US 40)
    func gemDeviceToken(_ token: String) async {
        guard let brugerId = currentUser?.id else { return }
        do {
            try await db.collection("users").document(brugerId).updateData([
                "deviceToken": token
            ])
            currentUser?.deviceToken = token
        } catch {
            print("Fejl: \(error)")
        }
    }
    
    // MARK: - Hent bruger
    private func fetchUser() async {
        guard let uid = userSession?.uid else { return }
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            self.currentUser = try snapshot.data(as: AppUser.self)
        } catch {
            print("Fejl: \(error)")
        }
    }
    
    private func oversaetFejl(_ error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case AuthErrorCode.wrongPassword.rawValue:    return "Forkert adgangskode"
        case AuthErrorCode.invalidEmail.rawValue:     return "Ugyldig email-adresse"
        case AuthErrorCode.userNotFound.rawValue:     return "Brugeren findes ikke"
        case AuthErrorCode.emailAlreadyInUse.rawValue: return "Email-adressen er allerede i brug"
        case AuthErrorCode.weakPassword.rawValue:     return "Adgangskoden er for svag (min. 6 tegn)"
        case AuthErrorCode.networkError.rawValue:     return "Netværksfejl - tjek din internetforbindelse"
        default: return "Der opstod en fejl: \(error.localizedDescription)"
        }
    }
}

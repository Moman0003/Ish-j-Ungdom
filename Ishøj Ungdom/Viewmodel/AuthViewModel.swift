//
//  AuthViewModel.swift
//  IshojUngdom
//
//  ViewModel: Håndterer authentication state og kommunikation med Firebase Auth
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
    
    // Published properties som View'et kan reagere på
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: AppUser?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    private let db = Firestore.firestore()
    
    init() {
        // Tjek om der allerede er en aktiv session ved app-start
        self.userSession = Auth.auth().currentUser
        
        // Hent brugerdata hvis der er en session
        Task {
            await fetchUser()
        }
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
    func opretBruger(email: String, password: String, navn: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Opret bruger i Firebase Auth
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            
            // 2. Gem brugeroplysninger i Firestore
            let nyBruger = AppUser(
                id: result.user.uid,
                email: email,
                navn: navn,
                oprettetDato: Date()
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
            self.errorMessage = "Kunne ikke logge ud: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Hent brugerdata fra Firestore
    private func fetchUser() async {
        guard let uid = userSession?.uid else { return }
        
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            self.currentUser = try snapshot.data(as: AppUser.self)
        } catch {
            print("Fejl ved hentning af bruger: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Oversæt Firebase fejl til danske beskeder
    private func oversaetFejl(_ error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Forkert adgangskode"
        case AuthErrorCode.invalidEmail.rawValue:
            return "Ugyldig email-adresse"
        case AuthErrorCode.userNotFound.rawValue:
            return "Brugeren findes ikke"
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "Email-adressen er allerede i brug"
        case AuthErrorCode.weakPassword.rawValue:
            return "Adgangskoden er for svag (min. 6 tegn)"
        case AuthErrorCode.networkError.rawValue:
            return "Netværksfejl - tjek din internetforbindelse"
        default:
            return "Der opstod en fejl: \(error.localizedDescription)"
        }
    }
}

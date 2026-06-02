//
//  MainTabView.swift
//  IshojUngdom
//
//  View: Hovedtab-navigation med 5 tabs
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var visOnboarding: Bool = false
    
    var body: some View {
        TabView {
            ForsideView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Forside")
                }
                .environmentObject(authViewModel)
            
            SoegView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Søg")
                }
                .environmentObject(authViewModel)
            
            EventsView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Events")
                }
                .environmentObject(authViewModel)
            
            NewsfeedView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Feed")
                }
                .environmentObject(authViewModel)
            
            ProfilView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profil")
                }
                .environmentObject(authViewModel)
        }
        .tint(.white)
        .onAppear {
            // Vis onboarding for nye brugere (US 48)
            if let bruger = authViewModel.currentUser, !bruger.harSetOnboarding {
                visOnboarding = true
            }
            
            // Anmod om notifikationstilladelse (US 40)
            Task {
                let status = await NotifikationService.shared.tjekTilladelse()
                if status == .notDetermined {
                    _ = await NotifikationService.shared.anmodOmTilladelse()
                }
            }
        }
        .fullScreenCover(isPresented: $visOnboarding) {
            OnboardingView().environmentObject(authViewModel)
        }
    }
}

//
//  MainTabView.swift
//  IshojUngdom
//
//  View: Hovedstruktur med tab bar (Forside, Søg, Events, Profil)
//

import SwiftUI

struct MainTabView: View {
    @State private var valgtTab: Int = 0
    
    var body: some View {
        TabView(selection: $valgtTab) {
            // Tab 1: Forside
            ForsideView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Forside")
                }
                .tag(0)
            
            // Tab 2: Søg
            SoegView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Søg")
                }
                .tag(1)
            
            // Tab 3: Events
            EventsView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Events")
                }
                .tag(2)
            
            // Tab 4: Min Profil
            ProfilView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Min profil")
                }
                .tag(3)
        }
        .tint(.white)  // Aktivt tab ikon farve
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}

//
//  RootView.swift
//  IshojUngdom
//
//  Root view: Styrer navigation baseret på authentication state
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.userSession != nil {
                // Bruger er logget ind - vis tab bar med alle hovedsider
                MainTabView()
            } else {
                // Bruger er ikke logget ind - vis login/opret bruger
                WelcomeView()
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthViewModel())
}

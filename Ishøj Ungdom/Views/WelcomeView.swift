//
//  WelcomeView.swift
//  IshojUngdom
//
//  View: Velkomstskærmen med logo + Login og Opret bruger knapper
//  Bruger Liquid Glass effekt (iOS 26+)
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Mørk baggrund
                Color(red: 0.10, green: 0.10, blue: 0.12)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Logo
                    Image("ishoj_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                    
                    Spacer()
                    
                    // Knapper med Liquid Glass effekt
                    VStack(spacing: 20) {
                        NavigationLink(destination: LoginView()) {
                            Text("Login")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 240, height: 58)
                                .glassEffect(.regular.interactive(), in: Capsule())
                        }
                        
                        NavigationLink(destination: SignUpView()) {
                            Text("Opret bruger")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 240, height: 58)
                                .glassEffect(.regular.interactive(), in: Capsule())
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthViewModel())
}

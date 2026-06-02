//
//  ProfilView.swift
//  IshojUngdom
//
//  View: Profilside med billede, menu, favoritter
//

import SwiftUI

struct ProfilView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var visRedigerSheet: Bool = false
    @State private var visMineTilmeldinger: Bool = false
    @State private var visMineFavoritter: Bool = false
    @State private var visIndstillinger: Bool = false
    @State private var visLogUdAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        profilHeader
                        
                        VStack(spacing: 12) {
                            menuRow(icon: "person.crop.circle", titel: "Rediger profil") {
                                visRedigerSheet = true
                            }
                            menuRow(icon: "calendar", titel: "Mine tilmeldinger") {
                                visMineTilmeldinger = true
                            }
                            menuRow(icon: "heart.fill", titel: "Mine favoritter") {
                                visMineFavoritter = true
                            }
                            menuRow(icon: "gearshape", titel: "Indstillinger") {
                                visIndstillinger = true
                            }
                        }
                        
                        Spacer().frame(height: 20)
                        
                        Button(action: { visLogUdAlert = true }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Log ud")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .glassEffect(.regular.interactive().tint(.red.opacity(0.2)), in: Capsule())
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Min profil")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $visRedigerSheet) {
                RedigerProfilView().environmentObject(authViewModel)
            }
            .sheet(isPresented: $visMineTilmeldinger) {
                MineTilmeldingerView().environmentObject(authViewModel)
            }
            .sheet(isPresented: $visMineFavoritter) {
                MineFavoritterView().environmentObject(authViewModel)
            }
            .sheet(isPresented: $visIndstillinger) {
                IndstillingerView().environmentObject(authViewModel)
            }
            .alert("Log ud?", isPresented: $visLogUdAlert) {
                Button("Annuller", role: .cancel) {}
                Button("Log ud", role: .destructive) { authViewModel.logUd() }
            } message: {
                Text("Er du sikker på at du vil logge ud?")
            }
        }
    }
    
    private var profilHeader: some View {
        VStack(spacing: 14) {
            ProfilBillede(
                url: authViewModel.currentUser?.profilBilledUrl,
                initialer: authViewModel.currentUser?.initialer ?? "?",
                stoerrelse: 100
            )
            
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Text(authViewModel.currentUser?.navn ?? "Bruger")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    if authViewModel.currentUser?.erAdmin == true {
                        Text("ADMIN")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .glassEffect(.regular.tint(.orange.opacity(0.5)), in: Capsule())
                    }
                }
                
                Text(authViewModel.currentUser?.email ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                
                if let alder = authViewModel.currentUser?.alder {
                    Text("\(alder) år")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(.vertical, 16)
    }
    
    @ViewBuilder
    private func menuRow(icon: String, titel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 28)
                Text(titel)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 18).padding(.vertical, 16)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
        }
        .accessibilityLabel(titel)
    }
}

//
//  ProfilView.swift
//  IshojUngdom
//
//  View: Brugerens profilside med redigeringsmuligheder
//

import SwiftUI

struct ProfilView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var visRedigerSheet: Bool = false
    @State private var visLogUdAlert: Bool = false
    
    private var initialer: String {
        guard let navn = authViewModel.currentUser?.navn else { return "?" }
        let dele = navn.components(separatedBy: " ")
        let foersteBogstav = dele.first?.first.map(String.init) ?? ""
        let andetBogstav = dele.count > 1 ? (dele.last?.first.map(String.init) ?? "") : ""
        return (foersteBogstav + andetBogstav).uppercased()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profil header
                        profilHeader
                        
                        // Indstillinger
                        VStack(spacing: 12) {
                            menuRow(icon: "person.crop.circle", titel: "Rediger profil", action: {
                                visRedigerSheet = true
                            })
                            
                            menuRow(icon: "calendar", titel: "Mine tilmeldinger", action: {})
                            
                            menuRow(icon: "bell", titel: "Notifikationer", action: {})
                            
                            menuRow(icon: "lock", titel: "Privatliv & sikkerhed", action: {})
                            
                            menuRow(icon: "questionmark.circle", titel: "Hjælp & support", action: {})
                        }
                        
                        Spacer().frame(height: 20)
                        
                        // Log ud knap
                        Button(action: {
                            visLogUdAlert = true
                        }) {
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
                RedigerProfilView()
                    .environmentObject(authViewModel)
            }
            .alert("Log ud?", isPresented: $visLogUdAlert) {
                Button("Annuller", role: .cancel) {}
                Button("Log ud", role: .destructive) {
                    authViewModel.logUd()
                }
            } message: {
                Text("Er du sikker på at du vil logge ud?")
            }
        }
    }
    
    // MARK: - Profil header
    private var profilHeader: some View {
        VStack(spacing: 14) {
            // Initialer i cirkel
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .glassEffect(.regular.tint(.blue.opacity(0.4)), in: Circle())
                
                Text(initialer)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(authViewModel.currentUser?.navn ?? "Bruger")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text(authViewModel.currentUser?.email ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Menu row
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
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    ProfilView()
        .environmentObject(AuthViewModel())
}

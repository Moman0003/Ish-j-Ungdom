//
//  SletKontoView.swift
//  IshojUngdom
//
//  View: Slet konto med adgangskode-bekræftelse (US 46 - GDPR)
//

import SwiftUI

struct SletKontoView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var password: String = ""
    @State private var bekraefter: Bool = false
    @State private var fejlBesked: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Advarsel ikon
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                            .padding(.top, 30)
                        
                        Text("Slet din konto")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 14) {
                            advarselsPunkt("Alle dine personlige oplysninger slettes permanent.")
                            advarselsPunkt("Alle dine tilmeldinger og favoritter slettes.")
                            advarselsPunkt("Alle dine opslag og kommentarer slettes.")
                            advarselsPunkt("Denne handling kan ikke fortrydes.")
                        }
                        .padding(20)
                        .glassEffect(.regular.tint(.red.opacity(0.15)), in: RoundedRectangle(cornerRadius: 16))
                        
                        // Password felt
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Indtast din adgangskode for at bekræfte")
                                .foregroundColor(.white.opacity(0.85))
                                .font(.subheadline)
                            
                            SecureField("", text: $password,
                                        prompt: Text("Adgangskode").foregroundColor(.white.opacity(0.4)))
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .tint(.white)
                                .textContentType(.none)
                                .padding(.horizontal, 18).padding(.vertical, 16)
                                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                        }
                        
                        if let fejl = fejlBesked {
                            Text(fejl).foregroundColor(.red).font(.footnote)
                        }
                        
                        Spacer().frame(height: 10)
                        
                        // Slet knap
                        Button(action: { bekraefter = true }) {
                            if authViewModel.isLoading {
                                ProgressView().tint(.white)
                                    .frame(maxWidth: .infinity, minHeight: 56)
                                    .glassEffect(.regular.interactive(), in: Capsule())
                            } else {
                                Text("Slet min konto permanent")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 56)
                                    .glassEffect(.regular.interactive().tint(.red.opacity(0.5)), in: Capsule())
                            }
                        }
                        .disabled(password.isEmpty || authViewModel.isLoading)
                        .opacity(password.isEmpty ? 0.5 : 1.0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Slet konto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuller") { dismiss() }.foregroundColor(.white)
                }
            }
            .alert("Er du HELT sikker?", isPresented: $bekraefter) {
                Button("Annuller", role: .cancel) {}
                Button("Ja, slet min konto", role: .destructive) {
                    Task { await sletKonto() }
                }
            } message: {
                Text("Dette kan ikke fortrydes. Alle dine data forsvinder for altid.")
            }
        }
    }
    
    @ViewBuilder
    private func advarselsPunkt(_ tekst: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.red.opacity(0.8))
                .padding(.top, 2)
            Text(tekst)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.85))
        }
    }
    
    private func sletKonto() async {
        let ok = await authViewModel.sletKonto(password: password)
        if !ok {
            fejlBesked = authViewModel.errorMessage ?? "Kunne ikke slette konto"
        }
    }
}

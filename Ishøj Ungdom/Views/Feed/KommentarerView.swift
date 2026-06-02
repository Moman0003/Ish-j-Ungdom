//
//  KommentarerView.swift
//  IshojUngdom
//
//  View: Kommentar tråd på et opslag (US 53)
//

import SwiftUI

struct KommentarerView: View {
    let opslag: Opslag
    @ObservedObject var viewModel: NewsfeedViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var kommentarer: [Kommentar] = []
    @State private var nyKommentar: String = ""
    @State private var sender: Bool = false
    
    private let maxTegn = 250
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 12) {
                            if kommentarer.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "bubble.right")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.4))
                                    Text("Ingen kommentarer endnu")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.6))
                                    Text("Vær den første til at kommentere!")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                .padding(.top, 80)
                            } else {
                                ForEach(kommentarer) { k in
                                    kommentarRaekke(k)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    
                    // Input felt nederst
                    HStack(spacing: 10) {
                        ProfilBillede(
                            url: authViewModel.currentUser?.profilBilledUrl,
                            initialer: authViewModel.currentUser?.initialer ?? "?",
                            stoerrelse: 36
                        )
                        
                        HStack {
                            TextField("", text: $nyKommentar,
                                      prompt: Text("Skriv en kommentar...")
                                .foregroundColor(.white.opacity(0.4)))
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .tint(.white)
                                .textContentType(.none)
                                .onChange(of: nyKommentar) { _, ny in
                                    if ny.count > maxTegn {
                                        nyKommentar = String(ny.prefix(maxTegn))
                                    }
                                }
                            
                            if !nyKommentar.isEmpty {
                                Button(action: { Task { await sendKommentar() } }) {
                                    if sender {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .disabled(sender)
                            }
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .glassEffect(.regular, in: Capsule())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.08, green: 0.08, blue: 0.10))
                }
            }
            .navigationTitle("Kommentarer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Luk") { dismiss() }.foregroundColor(.white)
                }
            }
            .task {
                await hentKommentarer()
            }
        }
    }
    
    @ViewBuilder
    private func kommentarRaekke(_ k: Kommentar) -> some View {
        let kanSlette: Bool = {
            guard let brugerId = authViewModel.currentUser?.id else { return false }
            return k.brugerId == brugerId || authViewModel.currentUser?.erAdmin == true
        }()
        
        HStack(alignment: .top, spacing: 10) {
            ProfilBillede(
                url: k.brugerProfilBilledUrl,
                initialer: k.brugerInitialer,
                stoerrelse: 36
            )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(k.brugerNavn)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(relativDato(k.oprettetDato))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                    
                    if kanSlette {
                        Menu {
                            Button(role: .destructive) {
                                Task { await sletKommentar(k) }
                            } label: {
                                Label("Slet", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                
                Text(k.tekst)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func hentKommentarer() async {
        guard let opslagId = opslag.id else { return }
        kommentarer = await viewModel.hentKommentarer(opslagId: opslagId)
    }
    
    private func sendKommentar() async {
        guard let opslagId = opslag.id,
              let bruger = authViewModel.currentUser else { return }
        
        sender = true
        let tekst = nyKommentar.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !tekst.isEmpty {
            _ = await viewModel.opretKommentar(opslagId: opslagId, tekst: tekst, bruger: bruger)
            nyKommentar = ""
            await hentKommentarer()
        }
        sender = false
    }
    
    private func sletKommentar(_ k: Kommentar) async {
        guard let brugerId = authViewModel.currentUser?.id else { return }
        _ = await viewModel.sletKommentar(
            kommentar: k,
            currentUserId: brugerId,
            erAdmin: authViewModel.currentUser?.erAdmin ?? false
        )
        await hentKommentarer()
    }
}

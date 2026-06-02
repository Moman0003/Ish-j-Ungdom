//
//  OpslagCard.swift
//  IshojUngdom
//
//  Component: Individuelt opslag i newsfeed med likes, kommentarer
//

import SwiftUI

struct OpslagCard: View {
    let opslag: Opslag
    @ObservedObject var viewModel: NewsfeedViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var visKommentarer = false
    @State private var visSletDialog = false
    @State private var visBilledIndex: Int = 0
    
    private var brugerHarLiket: Bool {
        guard let id = authViewModel.currentUser?.id else { return false }
        return opslag.brugerHarLiket(id)
    }
    
    private var kanSlette: Bool {
        guard let brugerId = authViewModel.currentUser?.id else { return false }
        return opslag.brugerId == brugerId || authViewModel.currentUser?.erAdmin == true
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header med bruger
            HStack(spacing: 12) {
                ProfilBillede(
                    url: opslag.brugerProfilBilledUrl,
                    initialer: opslag.brugerInitialer,
                    stoerrelse: 44
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(opslag.brugerNavn)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if opslag.erOfficiel {
                            Text("Officiel")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 7).padding(.vertical, 2)
                                .glassEffect(.regular.tint(.orange.opacity(0.6)), in: Capsule())
                        }
                    }
                    Text(relativDato(opslag.oprettetDato))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                if opslag.erPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.orange.opacity(0.8))
                }
                
                if kanSlette {
                    Menu {
                        Button(role: .destructive) {
                            visSletDialog = true
                        } label: {
                            Label("Slet opslag", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 32, height: 32)
                    }
                }
            }
            
            // Tekst (tryk åbner kommentarer)
            if !opslag.tekst.isEmpty {
                Text(opslag.tekst)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture { visKommentarer = true }
            }
            
            // Billeder (US 51 - multi-image carousel)
            if !opslag.billedUrls.isEmpty {
                TabView(selection: $visBilledIndex) {
                    ForEach(Array(opslag.billedUrls.enumerated()), id: \.offset) { idx, url in
                        AsyncImage(url: URL(string: url)) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle().fill(Color.white.opacity(0.1))
                                .overlay(ProgressView().tint(.white))
                        }
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .tag(idx)
                    }
                }
                .frame(height: 240)
                .tabViewStyle(.page(indexDisplayMode: opslag.billedUrls.count > 1 ? .always : .never))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
            
            // Like + kommentar knapper
            HStack(spacing: 20) {
                Button(action: handleLike) {
                    HStack(spacing: 6) {
                        Image(systemName: brugerHarLiket ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundColor(brugerHarLiket ? .red : .white.opacity(0.7))
                            .scaleEffect(brugerHarLiket ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3), value: brugerHarLiket)
                        Text("\(opslag.antalLikes)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .accessibilityLabel(brugerHarLiket ? "Fjern like" : "Like")
                
                Button(action: { visKommentarer = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(opslag.antalKommentarer)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .accessibilityLabel("Vis kommentarer")
                
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(
            opslag.erOfficiel
                ? .regular.tint(.orange.opacity(0.2))
                : .regular,
            in: RoundedRectangle(cornerRadius: 18)
        )
        .sheet(isPresented: $visKommentarer) {
            KommentarerView(opslag: opslag, viewModel: viewModel)
                .environmentObject(authViewModel)
        }
        .alert("Slet opslag?", isPresented: $visSletDialog) {
            Button("Annuller", role: .cancel) {}
            Button("Slet", role: .destructive) {
                Task {
                    guard let brugerId = authViewModel.currentUser?.id else { return }
                    _ = await viewModel.sletOpslag(
                        opslag: opslag,
                        currentUserId: brugerId,
                        erAdmin: authViewModel.currentUser?.erAdmin ?? false
                    )
                }
            }
        } message: {
            Text("Dette kan ikke fortrydes.")
        }
    }
    
    private func handleLike() {
        guard let opslagId = opslag.id,
              let brugerId = authViewModel.currentUser?.id else { return }
        Task {
            await viewModel.toggleLike(opslagId: opslagId, brugerId: brugerId)
        }
    }
}

// Hjælper: relativ dato (f.eks. "2 timer siden")
func relativDato(_ dato: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.locale = Locale(identifier: "da_DK")
    formatter.unitsStyle = .full
    return formatter.localizedString(for: dato, relativeTo: Date())
}

//
//  SoegView.swift
//  IshojUngdom
//
//  View: Søg blandt events
//

import SwiftUI

struct SoegView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var eventViewModel = EventViewModel()
    @State private var soegeTekst: String = ""
    
    private var resultater: [Event] {
        if soegeTekst.isEmpty { return [] }
        let tekst = soegeTekst.lowercased()
        return eventViewModel.events.filter { event in
            event.titel.lowercased().contains(tekst) ||
            event.beskrivelse.lowercased().contains(tekst) ||
            event.lokation.lowercased().contains(tekst) ||
            (event.kategori?.lowercased().contains(tekst) ?? false)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Søgefelt
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.5))
                        TextField("", text: $soegeTekst,
                                  prompt: Text("Søg events, lokationer, kategorier...")
                                    .foregroundColor(.white.opacity(0.4)))
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .tint(.white)
                            .textContentType(.none)
                            .autocapitalization(.none)
                        
                        if !soegeTekst.isEmpty {
                            Button(action: { soegeTekst = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .accessibilityLabel("Ryd søgning")
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    if soegeTekst.isEmpty {
                        VStack(spacing: 14) {
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Søg blandt alle events")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            Text("Find aktiviteter, lokationer eller kategorier")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                if resultater.isEmpty {
                                    TomTilstand.ingenSoegeResultater.padding(.top, 60)
                                } else {
                                    HStack {
                                        Text("\(resultater.count) resultater")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.6))
                                        Spacer()
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.top, 8)
                                    
                                    ForEach(resultater) { event in
                                        NavigationLink(destination: EventDetailView(event: event)) {
                                            EventCard(
                                                event: event,
                                                erFavorit: authViewModel.erFavorit(event.id ?? ""),
                                                paaToggleFavorit: {
                                                    Task {
                                                        if let id = event.id {
                                                            await authViewModel.toggleFavorit(eventId: id)
                                                        }
                                                    }
                                                }
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationTitle("Søg")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await eventViewModel.hentEvents()
            }
        }
    }
}

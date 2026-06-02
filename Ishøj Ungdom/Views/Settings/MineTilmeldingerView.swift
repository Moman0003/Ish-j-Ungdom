//
//  MineTilmeldingerView.swift
//  IshojUngdom
//
//  View: Brugerens egne tilmeldinger (US 26, 27)
//

import SwiftUI

struct MineTilmeldingerView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var eventViewModel = EventViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var mineEvents: [Event] = []
    @State private var isLoading: Bool = false
    @State private var afmeldEvent: Event? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView().tint(.white).padding(.top, 80)
                        } else if mineEvents.isEmpty {
                            TomTilstand.ingenTilmeldinger.padding(.top, 80)
                        } else {
                            ForEach(mineEvents) { event in
                                tilmeldingsRaekke(event)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Mine tilmeldinger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Luk") { dismiss() }.foregroundColor(.white)
                }
            }
            .task {
                await indlaesData()
            }
            .refreshable {
                await indlaesData()
            }
            .alert("Afmeld event?", isPresented: Binding(
                get: { afmeldEvent != nil },
                set: { if !$0 { afmeldEvent = nil } }
            )) {
                Button("Annuller", role: .cancel) { afmeldEvent = nil }
                Button("Afmeld", role: .destructive) {
                    if let event = afmeldEvent { Task { await afmeld(event) } }
                }
            } message: {
                if let event = afmeldEvent {
                    Text("Vil du afmelde dig \(event.titel)?")
                }
            }
        }
    }
    
    @ViewBuilder
    private func tilmeldingsRaekke(_ event: Event) -> some View {
        NavigationLink(destination: EventDetailView(event: event)) {
            HStack(spacing: 12) {
                EventCard(event: event)
                    .overlay(alignment: .topTrailing) {
                        if event.erAflyst {
                            Text("AFLYST")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.red)
                                .clipShape(Capsule())
                                .padding(12)
                        }
                    }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                afmeldEvent = event
            } label: {
                Label("Afmeld", systemImage: "xmark.circle")
            }
        }
    }
    
    private func indlaesData() async {
        guard let brugerId = authViewModel.currentUser?.id else { return }
        isLoading = true
        mineEvents = await eventViewModel.hentMineTilmeldinger(brugerId: brugerId)
        isLoading = false
    }
    
    private func afmeld(_ event: Event) async {
        guard let eventId = event.id,
              let brugerId = authViewModel.currentUser?.id else { return }
        _ = await eventViewModel.afmeldBruger(eventId: eventId, brugerId: brugerId)
        afmeldEvent = nil
        await indlaesData()
    }
}

//
//  MineFavoritterView.swift
//  IshojUngdom
//
//  View: Brugerens favorit events (US 50)
//

import SwiftUI

struct MineFavoritterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var eventViewModel = EventViewModel()
    @Environment(\.dismiss) private var dismiss
    
    private var favoritEvents: [Event] {
        let ids = authViewModel.currentUser?.favoritEventIds ?? []
        return eventViewModel.events.filter { event in
            guard let id = event.id else { return false }
            return ids.contains(id)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if eventViewModel.isLoading {
                            ProgressView().tint(.white).padding(.top, 80)
                        } else if favoritEvents.isEmpty {
                            TomTilstand.ingenFavoritter.padding(.top, 80)
                        } else {
                            ForEach(favoritEvents) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    EventCard(
                                        event: event,
                                        erFavorit: true,
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
            .navigationTitle("Mine favoritter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Luk") { dismiss() }.foregroundColor(.white)
                }
            }
            .task {
                await eventViewModel.hentEvents()
            }
        }
    }
}

//
//  EventsView.swift
//  IshojUngdom
//
//  View: Alle events med filtre (US 32, 33, 34)
//

import SwiftUI

struct EventsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var eventViewModel = EventViewModel()
    
    @State private var visOpretEvent: Bool = false
    @State private var opretEventSheetId = UUID()
    @State private var visFilter: Bool = false
    
    private var filtreredeEvents: [Event] {
        eventViewModel.filtreredeEvents(brugerAlder: authViewModel.currentUser?.alder)
    }
    
    private var harAktivFilter: Bool {
        eventViewModel.filterAldersgruppe ||
        eventViewModel.filterDato != .alle ||
        !eventViewModel.filterKategorier.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Aktive filter-chips
                        if harAktivFilter {
                            aktiveFiltre
                        }
                        
                        if eventViewModel.isLoading && eventViewModel.events.isEmpty {
                            ProgressView().tint(.white).padding(.top, 100)
                        } else if filtreredeEvents.isEmpty {
                            if harAktivFilter {
                                TomTilstand.ingenSoegeResultater.padding(.top, 80)
                            } else {
                                TomTilstand(
                                    ikon: "calendar",
                                    titel: "Ingen events lige nu",
                                    undertekst: authViewModel.currentUser?.erAdmin == true
                                        ? "Tryk på + for at oprette det første event"
                                        : "Kom tilbage senere"
                                ).padding(.top, 80)
                            }
                        } else {
                            ForEach(filtreredeEvents) { event in
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
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Events")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { visFilter = true }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            
                            if harAktivFilter {
                                Circle().fill(Color.orange).frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .accessibilityLabel("Filtrer events")
                }
                
                if authViewModel.currentUser?.erAdmin == true {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            opretEventSheetId = UUID()
                            visOpretEvent = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .accessibilityLabel("Opret nyt event")
                    }
                }
            }
            .sheet(isPresented: $visOpretEvent) {
                AdminEventFormView(eksisterendeEvent: nil)
                    .id(opretEventSheetId)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $visFilter) {
                FilterView(viewModel: eventViewModel)
            }
            .task {
                await eventViewModel.hentEvents()
            }
            .refreshable {
                await eventViewModel.hentEvents()
            }
        }
    }
    
    private var aktiveFiltre: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if eventViewModel.filterAldersgruppe {
                    filterChip("Min aldersgruppe") {
                        eventViewModel.filterAldersgruppe = false
                    }
                }
                if eventViewModel.filterDato != .alle {
                    filterChip(eventViewModel.filterDato.rawValue) {
                        eventViewModel.filterDato = .alle
                    }
                }
                ForEach(Array(eventViewModel.filterKategorier), id: \.self) { kategori in
                    filterChip(kategori) {
                        eventViewModel.filterKategorier.remove(kategori)
                    }
                }
                
                Button("Nulstil") {
                    eventViewModel.nulstilFiltre()
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.orange)
                .padding(.horizontal, 12).padding(.vertical, 6)
            }
            .padding(.horizontal, 4)
        }
    }
    
    @ViewBuilder
    private func filterChip(_ tekst: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(tekst)
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .glassEffect(.regular.tint(.blue.opacity(0.4)), in: Capsule())
        }
    }
}

//
//  EventsView.swift
//  IshojUngdom
//
//  View: Alle events + admin "+" knap i toolbar
//

import SwiftUI

struct EventsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var eventViewModel = EventViewModel()
    
    @State private var visOpretEvent: Bool = false
    @State private var opretEventSheetId = UUID()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if eventViewModel.isLoading && eventViewModel.events.isEmpty {
                            ProgressView()
                                .tint(.white)
                                .padding(.top, 100)
                        } else if eventViewModel.events.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.4))
                                Text("Ingen events lige nu")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(authViewModel.currentUser?.erAdmin == true
                                     ? "Tryk på + for at oprette det første event"
                                     : "Kom tilbage senere")
                                    .font(.footnote)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.top, 100)
                        } else {
                            ForEach(eventViewModel.events) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    EventCard(event: event)
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
                if authViewModel.currentUser?.erAdmin == true {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        // Simpel knap uden glassEffect - den sidder allerede i toolbar
                        Button(action: {
                            opretEventSheetId = UUID()
                            visOpretEvent = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $visOpretEvent) {
                AdminEventFormView(eksisterendeEvent: nil)
                    .id(opretEventSheetId)
                    .environmentObject(authViewModel)
            }
            .task {
                await eventViewModel.hentEvents()
            }
            .refreshable {
                await eventViewModel.hentEvents()
            }
        }
    }
}

#Preview {
    EventsView()
        .environmentObject(AuthViewModel())
}

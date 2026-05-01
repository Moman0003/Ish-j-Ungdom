//
//  SoegView.swift
//  IshojUngdom
//
//  View: Søgeside hvor man kan søge efter events fra Firestore
//

import SwiftUI

struct SoegView: View {
    @StateObject private var eventViewModel = EventViewModel()
    @State private var soegeTekst: String = ""
    
    private var filtreredeEvents: [Event] {
        if soegeTekst.isEmpty {
            return eventViewModel.events
        }
        return eventViewModel.events.filter { event in
            event.titel.localizedCaseInsensitiveContains(soegeTekst) ||
            event.beskrivelse.localizedCaseInsensitiveContains(soegeTekst) ||
            event.lokation.localizedCaseInsensitiveContains(soegeTekst)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Søgefelt
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.5))
                        
                        TextField("", text: $soegeTekst,
                                  prompt: Text("Søg efter events...")
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
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    // Resultater
                    if filtreredeEvents.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.4))
                            Text(soegeTekst.isEmpty ? "Søg efter events" : "Ingen resultater")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(filtreredeEvents) { event in
                                    NavigationLink(destination: EventDetailView(event: event)) {
                                        EventCard(event: event)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
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

#Preview {
    SoegView()
}

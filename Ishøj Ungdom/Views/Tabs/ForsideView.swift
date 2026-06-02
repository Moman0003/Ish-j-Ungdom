//
//  ForsideView.swift
//  IshojUngdom
//
//  View: Forside med velkomst, kommende events og admin dashboard
//

import SwiftUI

struct ForsideView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var eventViewModel = EventViewModel()
    @State private var visDashboard: Bool = false
    
    private var kommendeEvents: [Event] {
        eventViewModel.events
            .filter { !$0.erAflyst && $0.startDato > Date() }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header med logo (som forrige version)
                        headerMedLogo
                        
                        // Admin badge / dashboard knap
                        if authViewModel.currentUser?.erAdmin == true {
                            adminPanel
                        }
                        
                        // Kommende events
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Kommende events")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                            
                            if eventViewModel.isLoading && eventViewModel.events.isEmpty {
                                ProgressView().tint(.white).padding(.top, 60)
                                    .frame(maxWidth: .infinity)
                            } else if kommendeEvents.isEmpty {
                                TomTilstand(
                                    ikon: "calendar",
                                    titel: "Ingen kommende events",
                                    undertekst: "Kom tilbage senere for at se nye aktiviteter"
                                )
                                .padding(.top, 30)
                            } else {
                                ForEach(kommendeEvents) { event in
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
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Forside")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $visDashboard) {
                AdminDashboardView()
            }
            .task {
                await eventViewModel.hentEvents()
            }
            .refreshable {
                await eventViewModel.hentEvents()
            }
        }
    }
    
    private var headerMedLogo: some View {
        HStack(alignment: .center, spacing: 14) {
            Image("ishoj_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Hej, \(fornavn)")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    
                    if authViewModel.currentUser?.erAdmin == true {
                        Text("ADMIN")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .glassEffect(.regular.tint(.orange.opacity(0.5)), in: Capsule())
                    }
                }
                
                Text("Velkommen tilbage")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var fornavn: String {
        authViewModel.currentUser?.navn.split(separator: " ").first.map(String.init) ?? "ven"
    }
    
    private var adminPanel: some View {
        Button(action: { visDashboard = true }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("ADMIN")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Color.orange)
                            .clipShape(Capsule())
                        Text("Dashboard")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text("Statistikker og overblik")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange.opacity(0.8))
            }
            .padding(16)
            .glassEffect(.regular.interactive().tint(.orange.opacity(0.2)), in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private func tidPaaDagen() -> String {
        let time = Calendar.current.component(.hour, from: Date())
        switch time {
        case 5..<10: return "Godmorgen,"
        case 10..<14: return "Goddag,"
        case 14..<18: return "God eftermiddag,"
        case 18..<22: return "God aften,"
        default: return "Hej,"
        }
    }
}

// (tidPaaDagen bevares hvis du vil bruge den senere)

//
//  AdminDashboardView.swift
//  IshojUngdom
//
//  View: Admin dashboard med statistikker (US 54)
//

import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var antalEvents: Int = 0
    @Published var tilmeldingerDenneMaaned: Int = 0
    @Published var antalBrugere: Int = 0
    @Published var topEvents: [(titel: String, antal: Int)] = []
    @Published var isLoading: Bool = true
    
    private let db = Firestore.firestore()
    
    func hentDashboard() async {
        isLoading = true
        
        // Antal aktive events
        do {
            let eventSnap = try await db.collection("events").getDocuments()
            self.antalEvents = eventSnap.documents.count
            
            // Top 5 mest populære - læs felter manuelt så ét dårligt
            // dokument ikke vælter hele decoding
            var medTilmeldte: [(titel: String, antal: Int)] = []
            for doc in eventSnap.documents {
                let data = doc.data()
                let titel = data["titel"] as? String ?? "Uden titel"
                let antal = data["antalTilmeldte"] as? Int ?? 0
                if antal > 0 {
                    medTilmeldte.append((titel: titel, antal: antal))
                }
            }
            let topFem = medTilmeldte
                .sorted { $0.antal > $1.antal }
                .prefix(5)
            self.topEvents = Array(topFem)
        } catch {
            print("Fejl events: \(error)")
        }
        
        // Tilmeldinger denne måned - hent alle og filtrér i kode
        // for at undgå index-krav på tilmeldtDato
        do {
            let kalender = Calendar.current
            let nu = Date()
            guard let maanedStart = kalender.date(from: kalender.dateComponents([.year, .month], from: nu)) else {
                isLoading = false
                return
            }
            
            let bookingsSnap = try await db.collection("bookings").getDocuments()
            let antal = bookingsSnap.documents.filter { doc in
                if let ts = doc.data()["tilmeldtDato"] as? Timestamp {
                    return ts.dateValue() >= maanedStart
                }
                return false
            }.count
            self.tilmeldingerDenneMaaned = antal
        } catch {
            print("Fejl bookings: \(error)")
        }
        
        // Antal brugere
        do {
            let usersSnap = try await db.collection("users").getDocuments()
            self.antalBrugere = usersSnap.documents.count
        } catch {
            print("Fejl users: \(error)")
        }
        
        isLoading = false
    }
}

struct AdminDashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if viewModel.isLoading {
                            ProgressView().tint(.white).padding(.top, 60)
                        } else {
                            // Statistikker
                            HStack(spacing: 12) {
                                statKort(
                                    ikon: "calendar",
                                    tal: "\(viewModel.antalEvents)",
                                    label: "Events",
                                    farve: .blue
                                )
                                statKort(
                                    ikon: "ticket.fill",
                                    tal: "\(viewModel.tilmeldingerDenneMaaned)",
                                    label: "Tilmeldinger denne måned",
                                    farve: .orange
                                )
                            }
                            
                            statKort(
                                ikon: "person.3.fill",
                                tal: "\(viewModel.antalBrugere)",
                                label: "Registrerede brugere",
                                farve: .green
                            )
                            .frame(maxWidth: .infinity)
                            
                            // Top 5 events
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Mest populære events")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                if viewModel.topEvents.isEmpty {
                                    Text("Ingen tilmeldinger endnu")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.5))
                                        .padding(16)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                                } else {
                                    VStack(spacing: 0) {
                                        ForEach(Array(viewModel.topEvents.enumerated()), id: \.offset) { idx, event in
                                            HStack {
                                                ZStack {
                                                    Circle().fill(rangFarve(idx).opacity(0.3))
                                                        .frame(width: 32, height: 32)
                                                    Text("\(idx + 1)")
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(rangFarve(idx))
                                                }
                                                
                                                Text(event.titel)
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                
                                                Spacer()
                                                
                                                Text("\(event.antal)")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.white.opacity(0.7))
                                                Image(systemName: "person.2.fill")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                            .padding(.horizontal, 14).padding(.vertical, 12)
                                            
                                            if idx < viewModel.topEvents.count - 1 {
                                                Divider().background(Color.white.opacity(0.1))
                                                    .padding(.leading, 14)
                                            }
                                        }
                                    }
                                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Dashboard")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await viewModel.hentDashboard() } }) {
                        Image(systemName: "arrow.clockwise").foregroundColor(.white)
                    }
                }
            }
            .task { await viewModel.hentDashboard() }
        }
    }
    
    private func rangFarve(_ idx: Int) -> Color {
        switch idx {
        case 0: return .yellow
        case 1: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 2: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .blue
        }
    }
    
    @ViewBuilder
    private func statKort(ikon: String, tal: String, label: String, farve: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: ikon)
                .font(.system(size: 22))
                .foregroundColor(farve)
            
            Text(tal)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(farve.opacity(0.15)), in: RoundedRectangle(cornerRadius: 16))
    }
}

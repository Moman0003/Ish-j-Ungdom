//
//  ForsideView.swift
//  IshojUngdom
//
//  View: Forside - ingen + knap, den er kun på Events siden
//

import SwiftUI

struct ForsideView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var eventViewModel = EventViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        headerSection
                        
                        HStack {
                            Text("Kommende events")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                        
                        if eventViewModel.isLoading && eventViewModel.events.isEmpty {
                            ProgressView()
                                .tint(.white)
                                .padding(.top, 40)
                        } else if eventViewModel.events.isEmpty {
                            emptyStateView
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
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .task {
                await eventViewModel.hentEvents()
                if let brugerId = authViewModel.currentUser?.id {
                    await eventViewModel.hentBrugerensBookings(brugerId: brugerId)
                }
            }
            .refreshable {
                await eventViewModel.hentEvents()
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            Image("ishoj_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("Hej, \(fornavn)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    if authViewModel.currentUser?.erAdmin == true {
                        Text("ADMIN")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .glassEffect(.regular.tint(.orange.opacity(0.5)), in: Capsule())
                    }
                }
                Text("Velkommen tilbage")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 4)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.4))
            Text("Ingen events lige nu")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            Text("Kom tilbage senere for at se nye events")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    private var fornavn: String {
        authViewModel.currentUser?.navn.components(separatedBy: " ").first ?? "der"
    }
}

#Preview {
    ForsideView()
        .environmentObject(AuthViewModel())
}

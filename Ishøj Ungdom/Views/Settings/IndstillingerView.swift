//
//  IndstillingerView.swift
//  IshojUngdom
//
//  View: App-indstillinger med notifikationer (US 59)
//

import SwiftUI

struct IndstillingerView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var indstillinger = NotifikationsIndstillinger()
    @State private var gemmer: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        sektion(titel: "Event-notifikationer") {
                            indstilingsToggle(
                                titel: "Nye events",
                                undertekst: "Få besked når der oprettes events for din aldersgruppe",
                                value: $indstillinger.nyeEvents
                            )
                            indstilingsToggle(
                                titel: "Ændringer af events",
                                undertekst: "Få besked når et event du er tilmeldt ændres",
                                value: $indstillinger.eventAendringer
                            )
                            indstilingsToggle(
                                titel: "Aflysninger",
                                undertekst: "Få straks besked hvis et event aflyses",
                                value: $indstillinger.eventAflysning
                            )
                            indstilingsToggle(
                                titel: "Reminders",
                                undertekst: "Få påmindelser før events starter",
                                value: $indstillinger.reminders
                            )
                        }
                        
                        sektion(titel: "Newsfeed") {
                            indstilingsToggle(
                                titel: "Likes",
                                undertekst: "Få besked når nogen liker dit opslag",
                                value: $indstillinger.newsfeedLikes
                            )
                            indstilingsToggle(
                                titel: "Kommentarer",
                                undertekst: "Få besked når nogen kommenterer på dit opslag",
                                value: $indstillinger.newsfeedKommentarer
                            )
                        }
                        
                        sektion(titel: "Om appen") {
                            infoRow(titel: "Version", vaerdi: "1.0")
                            infoRow(titel: "Udvikler", vaerdi: "Datamatiker hovedopgave")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Indstillinger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Luk") {
                        Task {
                            await authViewModel.opdaterNotifikationsIndstillinger(indstillinger)
                            dismiss()
                        }
                    }.foregroundColor(.white)
                }
            }
            .onAppear {
                indstillinger = authViewModel.currentUser?.notifikationer ?? NotifikationsIndstillinger()
            }
        }
    }
    
    @ViewBuilder
    private func sektion<Content: View>(titel: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titel)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 4)
                .textCase(.uppercase)
            
            VStack(spacing: 0) {
                content()
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func indstilingsToggle(titel: String, undertekst: String, value: Binding<Bool>) -> some View {
        Toggle(isOn: value) {
            VStack(alignment: .leading, spacing: 3) {
                Text(titel)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                Text(undertekst)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .tint(.blue)
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
    
    @ViewBuilder
    private func infoRow(titel: String, vaerdi: String) -> some View {
        HStack {
            Text(titel)
                .font(.system(size: 15))
                .foregroundColor(.white)
            Spacer()
            Text(vaerdi)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

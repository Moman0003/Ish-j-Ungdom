//
//  OnboardingView.swift
//  IshojUngdom
//
//  View: Onboarding tour til nye brugere (US 48)
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var aktuelSide: Int = 0
    
    let sider: [(ikon: String, titel: String, undertekst: String, farve: Color)] = [
        ("calendar.badge.plus",
         "Find spændende events",
         "Browse alle de aktiviteter Ishøj Ungdomsskole tilbyder, og find lige det der passer dig.",
         .blue),
        ("ticket.fill",
         "Tilmeld dig med ét tryk",
         "Sikr dig en plads til events med et enkelt tryk på 'Tilmeld dig' knappen. Lige så nemt at afmelde.",
         .purple),
        ("bell.badge.fill",
         "Aldrig glemme et event",
         "Få besked når nye events oprettes, og reminders før dit event starter.",
         .orange),
        ("heart.fill",
         "Vær en del af fællesskabet",
         "Del oplevelser i newsfeeden, like og kommenter på andres opslag.",
         .pink)
    ]
    
    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
            
            VStack {
                // Skip knap
                HStack {
                    Spacer()
                    Button("Spring over") {
                        Task {
                            await authViewModel.markerOnboardingSet()
                            dismiss()
                        }
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Pages
                TabView(selection: $aktuelSide) {
                    ForEach(Array(sider.enumerated()), id: \.offset) { idx, side in
                        VStack(spacing: 24) {
                            Image(systemName: side.ikon)
                                .font(.system(size: 90))
                                .foregroundColor(side.farve)
                                .padding(40)
                                .background(
                                    Circle().fill(side.farve.opacity(0.15))
                                        .frame(width: 200, height: 200)
                                )
                            
                            Text(side.titel)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(side.undertekst)
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .lineSpacing(5)
                        }
                        .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                Spacer()
                
                // Indikator
                HStack(spacing: 8) {
                    ForEach(0..<sider.count, id: \.self) { idx in
                        Capsule()
                            .fill(aktuelSide == idx ? Color.white : Color.white.opacity(0.3))
                            .frame(width: aktuelSide == idx ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: aktuelSide)
                    }
                }
                .padding(.bottom, 20)
                
                // Action knap
                Button(action: nesteHandling) {
                    Text(aktuelSide == sider.count - 1 ? "Kom i gang" : "Næste")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .glassEffect(.regular.interactive().tint(.blue.opacity(0.5)), in: Capsule())
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
    }
    
    private func nesteHandling() {
        if aktuelSide < sider.count - 1 {
            withAnimation {
                aktuelSide += 1
            }
        } else {
            Task {
                await authViewModel.markerOnboardingSet()
                dismiss()
            }
        }
    }
}

//
//  RedigerProfilView.swift
//  IshojUngdom
//
//  View: Sheet til at redigere brugerens profil
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RedigerProfilView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var navn: String = ""
    @State private var email: String = ""
    @State private var visGemmer: Bool = false
    @State private var fejlBesked: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 8)
                        
                        // Navn
                        glassInputField(label: "Navn", placeholder: "Dit navn", text: $navn)
                        
                        // Email (læs-kun for nu, da det kræver re-auth at ændre)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .foregroundColor(.white.opacity(0.85))
                                .font(.subheadline)
                            
                            HStack {
                                Text(email)
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                        }
                        
                        Text("Email kan ikke ændres her - kontakt support hvis du har brug for at ændre den.")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if let fejl = fejlBesked {
                            Text(fejl)
                                .foregroundColor(.red)
                                .font(.footnote)
                        }
                        
                        Spacer().frame(height: 20)
                        
                        // Gem knap
                        Button(action: {
                            Task { await gemAendringer() }
                        }) {
                            if visGemmer {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity, minHeight: 58)
                                    .glassEffect(.regular.interactive(), in: Capsule())
                            } else {
                                Text("Gem ændringer")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 58)
                                    .glassEffect(.regular.interactive().tint(.blue.opacity(0.4)), in: Capsule())
                            }
                        }
                        .disabled(navn.isEmpty || visGemmer)
                        .opacity(navn.isEmpty ? 0.5 : 1.0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Rediger profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuller") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                navn = authViewModel.currentUser?.navn ?? ""
                email = authViewModel.currentUser?.email ?? ""
            }
        }
    }
    
    // MARK: - Gem ændringer i Firestore
    private func gemAendringer() async {
        guard let uid = authViewModel.currentUser?.id else { return }
        
        visGemmer = true
        fejlBesked = nil
        
        do {
            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .updateData(["navn": navn])
            
            // Opdater også local state
            authViewModel.currentUser?.navn = navn
            
            visGemmer = false
            dismiss()
        } catch {
            fejlBesked = "Kunne ikke gemme: \(error.localizedDescription)"
            visGemmer = false
        }
    }
    
    @ViewBuilder
    private func glassInputField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .foregroundColor(.white.opacity(0.85))
                .font(.subheadline)
            
            TextField("", text: text, prompt: Text(placeholder)
                .foregroundColor(.white.opacity(0.4)))
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .tint(.white)
                .textContentType(.none)
                .autocapitalization(.words)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

#Preview {
    RedigerProfilView()
        .environmentObject(AuthViewModel())
}

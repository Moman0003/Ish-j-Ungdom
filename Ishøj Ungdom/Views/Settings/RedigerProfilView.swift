//
//  RedigerProfilView.swift
//  IshojUngdom
//
//  View: Rediger profil med billede upload + slet konto (US 46, 47)
//

import SwiftUI
import PhotosUI

struct RedigerProfilView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var navn: String = ""
    @State private var alder: String = ""
    @State private var email: String = ""
    
    @State private var valgtItem: PhotosPickerItem? = nil
    @State private var nytProfilBillede: UIImage? = nil
    
    @State private var visGemmer: Bool = false
    @State private var uploadStatus: String = ""
    @State private var fejlBesked: String? = nil
    
    @State private var visSletKontoSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profilbillede
                        VStack(spacing: 12) {
                            ZStack(alignment: .bottomTrailing) {
                                if let nyt = nytProfilBillede {
                                    Image(uiImage: nyt)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    ProfilBillede(
                                        url: authViewModel.currentUser?.profilBilledUrl,
                                        initialer: authViewModel.currentUser?.initialer ?? "?",
                                        stoerrelse: 120
                                    )
                                }
                                
                                PhotosPicker(selection: $valgtItem, matching: .images) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .frame(width: 38, height: 38)
                                        .background(Circle().fill(Color.blue))
                                        .overlay(Circle().stroke(Color(red: 0.10, green: 0.10, blue: 0.12), lineWidth: 3))
                                }
                                .accessibilityLabel("Skift profilbillede")
                            }
                        }
                        .padding(.top, 8)
                        
                        glassInputField(label: "Navn", placeholder: "Dit navn", text: $navn)
                        
                        glassInputField(
                            label: "Alder",
                            placeholder: "F.eks. 15",
                            text: $alder,
                            keyboardType: .numberPad
                        )
                        
                        // Email (læs-kun)
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
                            .padding(.horizontal, 18).padding(.vertical, 16)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                        }
                        
                        if !uploadStatus.isEmpty {
                            HStack(spacing: 8) {
                                ProgressView().tint(.white.opacity(0.7))
                                Text(uploadStatus)
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.footnote)
                            }
                        }
                        
                        if let fejl = fejlBesked {
                            Text(fejl).foregroundColor(.red).font(.footnote)
                        }
                        
                        // Gem
                        Button(action: { Task { await gemAendringer() } }) {
                            if visGemmer {
                                ProgressView().tint(.white)
                                    .frame(maxWidth: .infinity, minHeight: 56)
                                    .glassEffect(.regular.interactive(), in: Capsule())
                            } else {
                                Text("Gem ændringer")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 56)
                                    .glassEffect(.regular.interactive().tint(.blue.opacity(0.4)), in: Capsule())
                            }
                        }
                        .disabled(navn.isEmpty || visGemmer)
                        
                        Spacer().frame(height: 30)
                        
                        // Slet konto (GDPR)
                        Button(action: { visSletKontoSheet = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Slet min konto")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .glassEffect(.regular.interactive().tint(.red.opacity(0.15)), in: Capsule())
                        }
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
                    Button("Annuller") { dismiss() }.foregroundColor(.white)
                }
            }
            .onAppear { indlaesData() }
            .onChange(of: valgtItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        nytProfilBillede = img
                    }
                }
            }
            .sheet(isPresented: $visSletKontoSheet) {
                SletKontoView().environmentObject(authViewModel)
            }
        }
    }
    
    private func indlaesData() {
        navn = authViewModel.currentUser?.navn ?? ""
        alder = authViewModel.currentUser?.alder.map { String($0) } ?? ""
        email = authViewModel.currentUser?.email ?? ""
    }
    
    private func gemAendringer() async {
        visGemmer = true
        fejlBesked = nil
        
        // Upload nyt profilbillede hvis valgt
        if let nyt = nytProfilBillede {
            uploadStatus = "Uploader profilbillede..."
            if let url = await CloudinaryService.uploadBillede(billede: nyt, mappe: "profilbilleder") {
                _ = await authViewModel.opdaterProfilBillede(url: url)
            }
        }
        
        uploadStatus = "Gemmer..."
        let alderInt = Int(alder)
        let ok = await authViewModel.opdaterProfil(navn: navn, alder: alderInt)
        
        visGemmer = false
        uploadStatus = ""
        
        if ok {
            dismiss()
        } else {
            fejlBesked = "Kunne ikke gemme ændringer"
        }
    }
    
    @ViewBuilder
    private func glassInputField(label: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .foregroundColor(.white.opacity(0.85))
                .font(.subheadline)
            TextField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .tint(.white)
                .textContentType(.none)
                .keyboardType(keyboardType)
                .padding(.horizontal, 18).padding(.vertical, 16)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

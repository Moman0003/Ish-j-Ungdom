//
//  NytOpslagView.swift
//  IshojUngdom
//
//  View: Opret nyt opslag (US 29, 30, 51)
//

import SwiftUI
import PhotosUI

struct NytOpslagView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = NewsfeedViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var tekst: String = ""
    @State private var valgteItems: [PhotosPickerItem] = []
    @State private var valgteBilleder: [UIImage] = []
    @State private var erOfficiel: Bool = false
    @State private var uploadStatus: String = ""
    @State private var visGemmer: Bool = false
    @State private var fejlBesked: String?
    
    private let maxBilleder = 5
    private let maxTegn = 500
    
    private var formularGyldig: Bool {
        !tekst.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !valgteBilleder.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 18) {
                        // Bruger info
                        HStack(spacing: 12) {
                            ProfilBillede(
                                url: authViewModel.currentUser?.profilBilledUrl,
                                initialer: authViewModel.currentUser?.initialer ?? "?",
                                stoerrelse: 44
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(authViewModel.currentUser?.navn ?? "")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                if authViewModel.currentUser?.erAdmin == true && erOfficiel {
                                    Text("Officielt opslag")
                                        .font(.system(size: 12))
                                        .foregroundColor(.orange)
                                }
                            }
                            Spacer()
                        }
                        .padding(.top, 8)
                        
                        // Tekstfelt
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $tekst)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .foregroundColor(.white)
                                .tint(.white)
                                .frame(minHeight: 140)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .onChange(of: tekst) { _, ny in
                                    if ny.count > maxTegn {
                                        tekst = String(ny.prefix(maxTegn))
                                    }
                                }
                            
                            if tekst.isEmpty {
                                Text("Hvad sker der i dag?")
                                    .foregroundColor(.white.opacity(0.4))
                                    .padding(.horizontal, 22)
                                    .padding(.vertical, 18)
                                    .allowsHitTesting(false)
                            }
                        }
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                        
                        // Tegn-tæller
                        HStack {
                            Spacer()
                            Text("\(tekst.count) / \(maxTegn)")
                                .font(.system(size: 12))
                                .foregroundColor(tekst.count > maxTegn - 50 ? .orange : .white.opacity(0.5))
                        }
                        
                        // Billeder
                        if !valgteBilleder.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Array(valgteBilleder.enumerated()), id: \.offset) { idx, img in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: img)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 120, height: 120)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            
                                            Button(action: { fjernBillede(idx) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.white)
                                                    .background(Circle().fill(Color.black.opacity(0.5)))
                                            }
                                            .padding(6)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Tilføj billede knap
                        if valgteBilleder.count < maxBilleder {
                            PhotosPicker(
                                selection: $valgteItems,
                                maxSelectionCount: maxBilleder - valgteBilleder.count,
                                matching: .images
                            ) {
                                HStack(spacing: 10) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 18))
                                    Text("Tilføj billede (\(valgteBilleder.count)/\(maxBilleder))")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        
                        // Officielt opslag toggle (kun admin)
                        if authViewModel.currentUser?.erAdmin == true {
                            Toggle(isOn: $erOfficiel) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Officielt opslag")
                                        .foregroundColor(.white.opacity(0.85))
                                        .font(.subheadline)
                                    Text("Pinnes øverst i 24 timer")
                                        .foregroundColor(.white.opacity(0.5))
                                        .font(.caption)
                                }
                            }
                            .tint(.orange)
                            .padding(.horizontal, 18).padding(.vertical, 14)
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
                                .multilineTextAlignment(.center)
                        }
                        
                        // Send knap
                        Button(action: { Task { await sendOpslag() } }) {
                            if visGemmer {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity, minHeight: 56)
                                    .glassEffect(.regular.interactive(), in: Capsule())
                            } else {
                                Text("Send opslag")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 56)
                                    .glassEffect(.regular.interactive().tint(.blue.opacity(0.4)), in: Capsule())
                            }
                        }
                        .disabled(!formularGyldig || visGemmer)
                        .opacity(formularGyldig ? 1.0 : 0.5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Nyt opslag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuller") { dismiss() }.foregroundColor(.white)
                }
            }
            .onChange(of: valgteItems) { _, newItems in
                Task { await indlaesBilleder(newItems) }
            }
        }
    }
    
    private func indlaesBilleder(_ items: [PhotosPickerItem]) async {
        valgteBilleder = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                valgteBilleder.append(img)
            }
        }
    }
    
    private func fjernBillede(_ idx: Int) {
        if idx < valgteBilleder.count {
            valgteBilleder.remove(at: idx)
            if idx < valgteItems.count {
                valgteItems.remove(at: idx)
            }
        }
    }
    
    private func sendOpslag() async {
        guard let bruger = authViewModel.currentUser else { return }
        
        visGemmer = true
        fejlBesked = nil
        
        // Upload billeder først
        var urls: [String] = []
        for (idx, billede) in valgteBilleder.enumerated() {
            uploadStatus = "Uploader billede \(idx + 1) af \(valgteBilleder.count)..."
            if let url = await CloudinaryService.uploadBillede(billede: billede, mappe: "opslag") {
                urls.append(url)
            }
        }
        
        uploadStatus = "Sender opslag..."
        let success = await viewModel.opretOpslag(
            tekst: tekst.trimmingCharacters(in: .whitespacesAndNewlines),
            billedUrls: urls,
            bruger: bruger,
            erOfficiel: erOfficiel && bruger.erAdmin
        )
        
        visGemmer = false
        uploadStatus = ""
        
        if success {
            dismiss()
        } else {
            fejlBesked = "Kunne ikke sende opslag. Prøv igen."
        }
    }
}

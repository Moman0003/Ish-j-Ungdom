//
//  AdminViews.swift
//  IshojUngdom
//
//  Samlefil med admin-views: tilmeldte liste, send besked, vurder, deltagere, dashboard
//

import SwiftUI

// MARK: - TilmeldteListView (US 55, 57)
struct TilmeldteListView: View {
    let event: Event
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var eventViewModel = EventViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var tilmeldte: [(navn: String, email: String, alder: Int?, tilmeldt: Date)] = []
    @State private var isLoading = true
    @State private var sortering: Sortering = .navn
    @State private var visExportShare = false
    @State private var exportUrl: URL? = nil
    
    enum Sortering: String {
        case navn = "Navn"
        case tid = "Tidspunkt"
    }
    
    private var sorteret: [(navn: String, email: String, alder: Int?, tilmeldt: Date)] {
        switch sortering {
        case .navn: return tilmeldte.sorted { $0.navn < $1.navn }
        case .tid:  return tilmeldte.sorted { $0.tilmeldt < $1.tilmeldt }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Sorter-vælger
                    Picker("", selection: $sortering) {
                        Text("Navn").tag(Sortering.navn)
                        Text("Tidspunkt").tag(Sortering.tid)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    
                    if isLoading {
                        ProgressView().tint(.white).padding(.top, 80)
                        Spacer()
                    } else if tilmeldte.isEmpty {
                        Spacer()
                        Text("Ingen tilmeldte endnu")
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(Array(sorteret.enumerated()), id: \.offset) { _, t in
                                    tilmeldtRaekke(t)
                                }
                            }
                            .padding(.horizontal, 16).padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationTitle("Tilmeldte (\(tilmeldte.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Luk") { dismiss() }.foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: eksporter) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Eksportér til CSV")
                    .disabled(tilmeldte.isEmpty)
                }
            }
            .task {
                guard let eventId = event.id else { return }
                tilmeldte = await eventViewModel.hentTilmeldte(eventId: eventId)
                isLoading = false
            }
            .sheet(isPresented: $visExportShare) {
                if let url = exportUrl {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    @ViewBuilder
    private func tilmeldtRaekke(_ t: (navn: String, email: String, alder: Int?, tilmeldt: Date)) -> some View {
        HStack(spacing: 12) {
            ProfilBillede(
                url: nil,
                initialer: t.navn.split(separator: " ").compactMap { $0.first }.prefix(2).map(String.init).joined().uppercased(),
                stoerrelse: 44
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(t.navn)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(t.email)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                if let alder = t.alder {
                    Text("\(alder) år")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
    }
    
    private func eksporter() {
        if let url = ExportService.eksporterTilmeldteCSV(eventTitel: event.titel, tilmeldte: sorteret) {
            exportUrl = url
            visExportShare = true
        }
    }
}

// MARK: - ShareSheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - SendBeskedView (US 56)
struct SendBeskedView: View {
    let event: Event
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var beskedViewModel = BeskedViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var besked: String = ""
    @State private var sender: Bool = false
    @State private var sendt: Bool = false
    @State private var fejlBesked: String? = nil
    
    private let maxTegn = 500
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                if sendt {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.green)
                            .padding(.top, 60)
                        Text("Besked sendt!")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Text("Alle tilmeldte har modtaget din besked.")
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        Spacer()
                        Button(action: { dismiss() }) {
                            Text("OK")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .glassEffect(.regular.interactive().tint(.blue.opacity(0.4)), in: Capsule())
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Sender besked til")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text("\(event.antalTilmeldte) tilmeldte til \(event.titel)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                            
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $besked)
                                    .scrollContentBackground(.hidden).background(Color.clear)
                                    .foregroundColor(.white).tint(.white)
                                    .frame(minHeight: 180)
                                    .padding(.horizontal, 14).padding(.vertical, 10)
                                    .onChange(of: besked) { _, ny in
                                        if ny.count > maxTegn { besked = String(ny.prefix(maxTegn)) }
                                    }
                                
                                if besked.isEmpty {
                                    Text("Skriv din besked...")
                                        .foregroundColor(.white.opacity(0.4))
                                        .padding(.horizontal, 22).padding(.vertical, 18)
                                        .allowsHitTesting(false)
                                }
                            }
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                            
                            HStack {
                                Spacer()
                                Text("\(besked.count) / \(maxTegn)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            if let fejl = fejlBesked {
                                Text(fejl).foregroundColor(.red).font(.footnote)
                            }
                            
                            Button(action: { Task { await send() } }) {
                                if sender {
                                    ProgressView().tint(.white)
                                        .frame(maxWidth: .infinity, minHeight: 56)
                                        .glassEffect(.regular.interactive(), in: Capsule())
                                } else {
                                    HStack {
                                        Image(systemName: "paperplane.fill")
                                        Text("Send besked")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 56)
                                    .glassEffect(.regular.interactive().tint(.blue.opacity(0.4)), in: Capsule())
                                }
                            }
                            .disabled(besked.isEmpty || sender)
                            .opacity(besked.isEmpty ? 0.5 : 1.0)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Send besked")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuller") { dismiss() }.foregroundColor(.white)
                }
            }
        }
    }
    
    private func send() async {
        guard let eventId = event.id,
              let afsenderNavn = authViewModel.currentUser?.navn else { return }
        
        sender = true
        let ok = await beskedViewModel.sendBesked(
            eventId: eventId,
            eventTitel: event.titel,
            afsenderNavn: afsenderNavn,
            tekst: besked
        )
        sender = false
        
        if ok {
            sendt = true
        } else {
            fejlBesked = "Kunne ikke sende besked"
        }
    }
}

// MARK: - AfgivVurderingView (US 35)
struct AfgivVurderingView: View {
    let event: Event
    @ObservedObject var vurderingViewModel: VurderingViewModel
    let onSucces: () -> Void
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var stjerner: Int = 0
    @State private var kommentar: String = ""
    @State private var sender: Bool = false
    @State private var fejlBesked: String? = nil
    
    private let maxTegn = 250
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Hvordan var \(event.titel)?")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                        
                        StjerneVurdering(stjerner: $stjerner, stoerrelse: 40)
                            .padding(.vertical, 20)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kommentar (valgfri)")
                                .foregroundColor(.white.opacity(0.85))
                                .font(.subheadline)
                            
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $kommentar)
                                    .scrollContentBackground(.hidden).background(Color.clear)
                                    .foregroundColor(.white).tint(.white)
                                    .frame(minHeight: 100)
                                    .padding(.horizontal, 14).padding(.vertical, 10)
                                    .onChange(of: kommentar) { _, ny in
                                        if ny.count > maxTegn { kommentar = String(ny.prefix(maxTegn)) }
                                    }
                                if kommentar.isEmpty {
                                    Text("Del din oplevelse...")
                                        .foregroundColor(.white.opacity(0.4))
                                        .padding(.horizontal, 22).padding(.vertical, 18)
                                        .allowsHitTesting(false)
                                }
                            }
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                        }
                        
                        if let fejl = fejlBesked {
                            Text(fejl).foregroundColor(.red).font(.footnote)
                        }
                        
                        Button(action: { Task { await afgiv() } }) {
                            if sender {
                                ProgressView().tint(.white)
                                    .frame(maxWidth: .infinity, minHeight: 56)
                                    .glassEffect(.regular.interactive(), in: Capsule())
                            } else {
                                Text("Afgiv vurdering")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 56)
                                    .glassEffect(.regular.interactive().tint(.yellow.opacity(0.4)), in: Capsule())
                            }
                        }
                        .disabled(stjerner == 0 || sender)
                        .opacity(stjerner == 0 ? 0.5 : 1.0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Vurder event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuller") { dismiss() }.foregroundColor(.white)
                }
            }
        }
    }
    
    private func afgiv() async {
        guard let eventId = event.id,
              let bruger = authViewModel.currentUser,
              let brugerId = bruger.id else { return }
        
        sender = true
        let fornavn = bruger.navn.components(separatedBy: " ").first ?? bruger.navn
        let ok = await vurderingViewModel.afgivVurdering(
            eventId: eventId,
            brugerId: brugerId,
            brugerFornavn: fornavn,
            stjerner: stjerner,
            kommentar: kommentar.isEmpty ? nil : kommentar
        )
        sender = false
        
        if ok {
            onSucces()
            dismiss()
        } else {
            fejlBesked = "Kunne ikke afgive vurdering. Du har måske allerede vurderet."
        }
    }
}

// MARK: - DeltagerListView (US 31)
struct DeltagerListView: View {
    let event: Event
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var eventViewModel = EventViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var deltagere: [(navn: String, email: String, alder: Int?, tilmeldt: Date)] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        if isLoading {
                            ProgressView().tint(.white).padding(.top, 80)
                        } else if deltagere.isEmpty {
                            Text("Ingen tilmeldte endnu")
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 80)
                        } else {
                            // GDPR: Vis kun navne (ikke email)
                            ForEach(Array(deltagere.enumerated()), id: \.offset) { _, d in
                                HStack(spacing: 12) {
                                    ProfilBillede(
                                        url: nil,
                                        initialer: d.navn.split(separator: " ").compactMap { $0.first }
                                            .prefix(2).map(String.init).joined().uppercased(),
                                        stoerrelse: 44
                                    )
                                    Text(d.navn)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Deltagere")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Luk") { dismiss() }.foregroundColor(.white)
                }
            }
            .task {
                guard let eventId = event.id else { return }
                deltagere = await eventViewModel.hentTilmeldte(eventId: eventId)
                isLoading = false
            }
        }
    }
}

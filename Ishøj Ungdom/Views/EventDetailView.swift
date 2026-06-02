//
//  EventDetailView.swift
//  IshojUngdom
//
//  View: Event detaljer - alle Sprint 3-6 features
//  - Pakkeliste (US 25)
//  - Deltagere (US 31)
//  - Vurdering (US 35, 36)
//  - Status badge (US 39)
//  - Venteliste (US 58)
//  - Admin: send besked, eksporter, vis tilmeldte
//

import SwiftUI

struct EventDetailView: View {
    let event: Event
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var eventViewModel = EventViewModel()
    @StateObject private var vurderingViewModel = VurderingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var visBekraeftelse = false
    @State private var bekraeftelsesTekst = ""
    @State private var visRedigerSheet = false
    @State private var redigerSheetId = UUID()
    @State private var visSletAlert = false
    @State private var visAfgivVurdering = false
    @State private var visTilmeldte = false
    @State private var visSendBesked = false
    @State private var visDeltagere = false
    @State private var harAfgivetVurdering = false
    
    private var farve: Color {
        switch event.farveTag {
        case "blue":   return .blue.opacity(0.4)
        case "purple": return .purple.opacity(0.4)
        case "teal":   return .teal.opacity(0.4)
        case "orange": return .orange.opacity(0.4)
        case "pink":   return .pink.opacity(0.4)
        default:       return .gray.opacity(0.4)
        }
    }
    
    private var erTilmeldt: Bool {
        guard let id = event.id else { return false }
        return eventViewModel.erTilmeldt(eventId: id)
    }
    
    private var erPaaVenteliste: Bool {
        guard let id = event.id else { return false }
        return eventViewModel.erPaaVenteliste(eventId: id)
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerBillede
                    
                    HStack {
                        Text(event.titel)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .strikethrough(event.erAflyst, color: .red)
                        
                        Spacer()
                        
                        // Favorit knap
                        Button(action: {
                            Task {
                                if let id = event.id {
                                    await authViewModel.toggleFavorit(eventId: id)
                                }
                            }
                        }) {
                            Image(systemName: authViewModel.erFavorit(event.id ?? "") ? "heart.fill" : "heart")
                                .font(.system(size: 22))
                                .foregroundColor(authViewModel.erFavorit(event.id ?? "") ? .red : .white.opacity(0.7))
                        }
                        .accessibilityLabel("Favorit")
                    }
                    
                    statusBadge
                    
                    infoSektion
                    
                    // Beskrivelse
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Beskrivelse")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text(event.beskrivelse)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Pakkeliste (US 25)
                    if let pakkeliste = event.pakkeliste, !pakkeliste.isEmpty {
                        pakkelisteSektion(pakkeliste)
                    }
                    
                    praktiskInfo
                    
                    // Underviser
                    if let navn = event.underviserNavn, !navn.isEmpty {
                        underviserSektion(navn: navn)
                    }
                    
                    // Deltagere (US 31)
                    if event.kraeverTilmelding && event.antalTilmeldte > 0 {
                        deltagereSektion
                    }
                    
                    // Vurdering (US 35, 36)
                    if event.erFaerdigtAfholdt {
                        vurderingSektion
                    }
                    
                    Spacer().frame(height: 8)
                    
                    // Admin actions
                    if authViewModel.currentUser?.erAdmin == true {
                        adminActions
                        Spacer().frame(height: 4)
                    }
                    
                    // Tilmeldingsknap
                    tilmeldingsKnap
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert(bekraeftelsesTekst, isPresented: $visBekraeftelse) {
            Button("OK") {}
        }
        .sheet(isPresented: $visRedigerSheet) {
            AdminEventFormView(eksisterendeEvent: event)
                .id(redigerSheetId)
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $visAfgivVurdering) {
            AfgivVurderingView(event: event, vurderingViewModel: vurderingViewModel) {
                harAfgivetVurdering = true
            }
            .environmentObject(authViewModel)
        }
        .sheet(isPresented: $visTilmeldte) {
            TilmeldteListView(event: event).environmentObject(authViewModel)
        }
        .sheet(isPresented: $visSendBesked) {
            SendBeskedView(event: event).environmentObject(authViewModel)
        }
        .sheet(isPresented: $visDeltagere) {
            DeltagerListView(event: event).environmentObject(authViewModel)
        }
        .alert("Slet event?", isPresented: $visSletAlert) {
            Button("Annuller", role: .cancel) {}
            Button("Slet", role: .destructive) {
                Task { await sletEvent() }
            }
        } message: {
            Text("Er du sikker? Alle tilmeldinger slettes også.")
        }
        .task {
            if let brugerId = authViewModel.currentUser?.id, let eventId = event.id {
                await eventViewModel.hentBrugerensBookings(brugerId: brugerId)
                await vurderingViewModel.hentVurderinger(eventId: eventId)
                harAfgivetVurdering = await vurderingViewModel.harBrugerAfgivetVurdering(
                    eventId: eventId, brugerId: brugerId
                )
            }
        }
    }
    
    // MARK: - Header billede
    private var headerBillede: some View {
        Group {
            if let url = event.billedUrl, !url.isEmpty, let imgUrl = URL(string: url) {
                AsyncImage(url: imgUrl) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholderView
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            } else {
                placeholderView.frame(height: 220)
            }
        }
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(farve)
            .overlay(
                Image(systemName: "calendar.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.5))
            )
    }
    
    // MARK: - Status badge
    private var statusBadge: some View {
        Group {
            if event.eventStatus != .aaben {
                HStack(spacing: 8) {
                    Circle().fill(statusFarve).frame(width: 10, height: 10)
                    Text(event.eventStatus.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(statusFarve)
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .glassEffect(.regular.tint(statusFarve.opacity(0.2)), in: Capsule())
            }
        }
    }
    
    private var statusFarve: Color {
        switch event.eventStatus {
        case .aaben:      return .green
        case .faaPladser: return .orange
        case .lukket:     return .gray
        case .aflyst:     return .red
        }
    }
    
    // MARK: - Info sektion
    private var infoSektion: some View {
        VStack(spacing: 12) {
            let startF = DateFormatter()
            let _ = { startF.locale = Locale(identifier: "da_DK"); startF.dateFormat = "EEEE d. MMMM yyyy" }()
            
            infoRow(icon: "calendar", titel: "Startdato",
                    vaerdi: startF.string(from: event.startDato).capitalized)
            
            if let slut = event.slutDato {
                infoRow(icon: "calendar.badge.clock", titel: "Slutdato",
                        vaerdi: startF.string(from: slut).capitalized)
            }
            
            infoRow(icon: "person.crop.rectangle", titel: "Aldersgruppe", vaerdi: event.aldersgruppeTekst)
            
            if let kategori = event.kategori, !kategori.isEmpty {
                infoRow(icon: "tag", titel: "Kategori", vaerdi: kategori)
            }
            
            if event.kraeverTilmelding {
                infoRow(icon: "person.2.fill", titel: "Tilmeldte",
                        vaerdi: "\(event.antalTilmeldte) / \(event.maxDeltagere)")
            }
        }
        .padding(20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Pakkeliste
    private func pakkelisteSektion(_ punkter: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pakkeliste")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(punkter, id: \.self) { punkt in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green.opacity(0.8))
                        Text(punkt)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.85))
                        Spacer()
                    }
                }
            }
            .padding(16)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Praktisk info
    private var praktiskInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Praktisk")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                if let ugedag = event.ugedag, !ugedag.isEmpty {
                    praktiskRow(icon: "calendar",
                                tekst: ugedag + (event.tidspunkt.map { " kl. \($0)" } ?? ""))
                } else if let tid = event.tidspunkt, !tid.isEmpty {
                    praktiskRow(icon: "clock", tekst: tid)
                }
                praktiskRow(icon: "location.fill", tekst: event.lokation)
                if !event.kraeverTilmelding {
                    praktiskRow(icon: "checkmark.circle.fill",
                                tekst: "Kræver ingen tilmelding – bare mød op!")
                }
            }
        }
    }
    
    @ViewBuilder
    private func praktiskRow(icon: String, tekst: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 22)
            Text(tekst)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
        }
    }
    
    // MARK: - Underviser
    private func underviserSektion(navn: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Underviser")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            HStack(alignment: .top, spacing: 14) {
                ProfilBillede(
                    url: event.underviserBilledUrl,
                    initialer: initialer(navn),
                    stoerrelse: 80
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(navn)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    if let bio = event.underviserBeskrivelse, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
            }
            .padding(16)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Deltagere (US 31)
    private var deltagereSektion: some View {
        Button(action: { visDeltagere = true }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Deltagere")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Text("\(event.antalTilmeldte) tilmeldte - tryk for at se alle")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Vurdering
    private var vurderingSektion: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Vurderinger")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                if !vurderingViewModel.vurderinger.isEmpty {
                    StjerneSnit(
                        snit: vurderingViewModel.gennemsnit,
                        antalVurderinger: vurderingViewModel.vurderinger.count
                    )
                }
            }
            
            if erTilmeldt && event.kanGivesFeedback && !harAfgivetVurdering {
                Button(action: { visAfgivVurdering = true }) {
                    HStack {
                        Image(systemName: "star")
                        Text("Vurder dette event")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .glassEffect(.regular.interactive().tint(.yellow.opacity(0.3)), in: Capsule())
                }
            }
            
            if vurderingViewModel.vurderinger.isEmpty {
                Text("Ingen vurderinger endnu")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
            } else {
                ForEach(vurderingViewModel.vurderinger.prefix(3)) { v in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(v.brugerFornavn)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { i in
                                    Image(systemName: i <= v.stjerner ? "star.fill" : "star")
                                        .font(.system(size: 11))
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        if let kommentar = v.kommentar, !kommentar.isEmpty {
                            Text(kommentar)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    // MARK: - Admin actions
    private var adminActions: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                adminKnap(icon: "pencil", tekst: "Rediger", tint: .orange) {
                    redigerSheetId = UUID()
                    visRedigerSheet = true
                }
                adminKnap(icon: "trash", tekst: "Slet", tint: .red) {
                    visSletAlert = true
                }
            }
            HStack(spacing: 10) {
                adminKnap(icon: "person.2", tekst: "Tilmeldte", tint: .blue) {
                    visTilmeldte = true
                }
                adminKnap(icon: "paperplane", tekst: "Send besked", tint: .green) {
                    visSendBesked = true
                }
            }
        }
    }
    
    @ViewBuilder
    private func adminKnap(icon: String, tekst: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13))
                Text(tekst).font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .glassEffect(.regular.interactive().tint(tint.opacity(0.4)), in: Capsule())
        }
    }
    
    // MARK: - Tilmeldingsknap
    private var tilmeldingsKnap: some View {
        Group {
            if event.erAflyst {
                statusInfoBoks(tekst: "Dette event er aflyst", farve: .red, icon: "xmark.circle.fill")
            } else if !event.kraeverTilmelding {
                statusInfoBoks(tekst: "Ingen tilmelding nødvendig – mød bare op!",
                              farve: .green, icon: "checkmark.circle.fill")
            } else if erTilmeldt {
                Button(action: { Task { await afmeld() } }) {
                    Text("Afmeld")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .glassEffect(.regular.interactive().tint(.red.opacity(0.4)), in: Capsule())
                }
            } else if erPaaVenteliste {
                VStack(spacing: 10) {
                    statusInfoBoks(tekst: "Du er på ventelisten", farve: .orange, icon: "clock.fill")
                    Button(action: { Task { await forladVenteliste() } }) {
                        Text("Forlad venteliste")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .glassEffect(.regular.interactive().tint(.orange.opacity(0.2)), in: Capsule())
                    }
                }
            } else if event.erFuldtBooket {
                // Tilbyd venteliste (US 58)
                Button(action: { Task { await tilmeldVenteliste() } }) {
                    HStack {
                        Image(systemName: "clock")
                        Text("Tilmeld venteliste")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .glassEffect(.regular.interactive().tint(.orange.opacity(0.4)), in: Capsule())
                }
            } else {
                Button(action: { Task { await tilmeld() } }) {
                    Text("Tilmeld dig")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .glassEffect(.regular.interactive().tint(farve), in: Capsule())
                }
            }
        }
    }
    
    @ViewBuilder
    private func statusInfoBoks(tekst: String, farve: Color, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(tekst).font(.system(size: 15, weight: .medium))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, minHeight: 58)
        .glassEffect(.regular.tint(farve.opacity(0.3)), in: Capsule())
    }
    
    // MARK: - Actions
    private func tilmeld() async {
        guard let eventId = event.id, let brugerId = authViewModel.currentUser?.id else { return }
        if await eventViewModel.tilmeldBruger(eventId: eventId, brugerId: brugerId) {
            bekraeftelsesTekst = "Du er nu tilmeldt!"
            visBekraeftelse = true
            // Planlæg reminders
            NotifikationService.shared.planlaegReminder(
                eventId: eventId, eventTitel: event.titel, eventStart: event.startDato
            )
        }
    }
    
    private func afmeld() async {
        guard let eventId = event.id, let brugerId = authViewModel.currentUser?.id else { return }
        if await eventViewModel.afmeldBruger(eventId: eventId, brugerId: brugerId) {
            bekraeftelsesTekst = "Du er nu afmeldt"
            visBekraeftelse = true
            NotifikationService.shared.annullerReminder(eventId: eventId)
        }
    }
    
    private func tilmeldVenteliste() async {
        guard let eventId = event.id,
              let bruger = authViewModel.currentUser,
              let brugerId = bruger.id else { return }
        if await eventViewModel.tilmeldVenteliste(eventId: eventId, brugerId: brugerId, brugerNavn: bruger.navn) {
            bekraeftelsesTekst = "Du er nu på ventelisten"
            visBekraeftelse = true
        }
    }
    
    private func forladVenteliste() async {
        guard let eventId = event.id, let brugerId = authViewModel.currentUser?.id else { return }
        _ = await eventViewModel.forladVenteliste(eventId: eventId, brugerId: brugerId)
    }
    
    private func sletEvent() async {
        guard let eventId = event.id else { return }
        if await eventViewModel.sletEvent(eventId: eventId) { dismiss() }
    }
    
    // MARK: - Hjælpere
    @ViewBuilder
    private func infoRow(icon: String, titel: String, vaerdi: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(titel).font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                Text(vaerdi).font(.system(size: 15, weight: .medium)).foregroundColor(.white)
            }
            Spacer()
        }
    }
    
    private func initialer(_ navn: String) -> String {
        navn.split(separator: " ").compactMap { $0.first }.prefix(2).map(String.init).joined().uppercased()
    }
}

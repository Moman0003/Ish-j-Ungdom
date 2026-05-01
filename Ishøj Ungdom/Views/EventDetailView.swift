//
//  EventDetailView.swift
//  IshojUngdom
//
//  View: Event detaljer matcher info fra ishojungdom.dk
//

import SwiftUI

struct EventDetailView: View {
    let event: Event
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var eventViewModel = EventViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var visBekraeftelse: Bool = false
    @State private var bekraeftelsesTekst: String = ""
    @State private var visRedigerSheet: Bool = false
    @State private var visSletAlert: Bool = false
    
    private var farve: Color {
        switch event.farveTag {
        case "blue":   return Color.blue.opacity(0.4)
        case "purple": return Color.purple.opacity(0.4)
        case "teal":   return Color.teal.opacity(0.4)
        case "orange": return Color.orange.opacity(0.4)
        case "pink":   return Color.pink.opacity(0.4)
        default:       return Color.gray.opacity(0.4)
        }
    }
    
    private var formateretStartDato: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "da_DK")
        f.dateFormat = "d. MMMM yyyy"
        return f.string(from: event.startDato)
    }
    
    private var formateretSlutDato: String? {
        guard let slut = event.slutDato else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "da_DK")
        f.dateFormat = "d. MMMM yyyy"
        return f.string(from: slut)
    }
    
    private var erTilmeldt: Bool {
        guard let id = event.id else { return false }
        return eventViewModel.erTilmeldt(eventId: id)
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.10, blue: 0.12)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header billede
                    headerBillede
                    
                    // Titel
                    Text(event.titel)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Info kort
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
                    .padding(.top, 4)
                    
                    // Praktisk info (ugedag, sted)
                    praktiskInfo
                    
                    // Underviser sektion (kun hvis udfyldt)
                    if let navn = event.underviserNavn, !navn.isEmpty {
                        underviserSektion(navn: navn)
                    }
                    
                    Spacer().frame(height: 16)
                    
                    // Admin actions
                    if authViewModel.currentUser?.erAdmin == true {
                        adminActions
                        Spacer().frame(height: 8)
                    }
                    
                    // Tilmeldingsknap (kun hvis tilmelding kræves)
                    if event.kraeverTilmelding {
                        tilmeldingsKnap
                    } else {
                        ikkeTilmeldingPaakraevet
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert(bekraeftelsesTekst, isPresented: $visBekraeftelse) {
            Button("OK") { dismiss() }
        }
        .sheet(isPresented: $visRedigerSheet) {
            AdminEventFormView(eksisterendeEvent: event)
                .environmentObject(authViewModel)
        }
        .alert("Slet event?", isPresented: $visSletAlert) {
            Button("Annuller", role: .cancel) {}
            Button("Slet", role: .destructive) {
                Task { await sletEvent() }
            }
        } message: {
            Text("Er du sikker på at du vil slette \(event.titel)? Alle tilmeldinger slettes også.")
        }
        .task {
            if let brugerId = authViewModel.currentUser?.id {
                await eventViewModel.hentBrugerensBookings(brugerId: brugerId)
            }
        }
    }
    
    // MARK: - Header billede
    private var headerBillede: some View {
        ZStack {
            if let url = event.billedUrl, !url.isEmpty, let imgUrl = URL(string: url) {
                AsyncImage(url: imgUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    placeholderBillede
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            } else {
                placeholderBillede
                    .frame(height: 220)
            }
        }
    }
    
    private var placeholderBillede: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(farve)
            .overlay(
                Image(systemName: "calendar.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.5))
            )
            .glassEffect(.regular.tint(farve), in: RoundedRectangle(cornerRadius: 24))
    }
    
    // MARK: - Info sektion (kompakt overblik)
    private var infoSektion: some View {
        VStack(spacing: 12) {
            infoRow(icon: "calendar", titel: "Startdato", vaerdi: formateretStartDato)
            
            if let slut = formateretSlutDato {
                infoRow(icon: "calendar.badge.clock", titel: "Slutdato", vaerdi: slut)
            }
            
            infoRow(icon: "person.crop.rectangle", titel: "Aldersgruppe", vaerdi: event.aldersgruppeTekst)
            
            if event.kraeverTilmelding {
                infoRow(
                    icon: "person.2.fill",
                    titel: "Tilmeldte",
                    vaerdi: "\(event.antalTilmeldte) / \(event.maxDeltagere)"
                )
            }
        }
        .padding(20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Praktisk info
    private var praktiskInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Praktisk")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                if let ugedag = event.ugedag, !ugedag.isEmpty {
                    praktiskRow(icon: "calendar", tekst: ugedag + (event.tidspunkt.map { " kl. \($0)" } ?? ""))
                } else if let tidspunkt = event.tidspunkt, !tidspunkt.isEmpty {
                    praktiskRow(icon: "clock", tekst: tidspunkt)
                }
                
                praktiskRow(icon: "location.fill", tekst: event.lokation)
                
                if !event.kraeverTilmelding {
                    praktiskRow(icon: "checkmark.circle.fill", tekst: "Kræver ingen tilmelding - bare mød op!")
                }
            }
        }
        .padding(.top, 4)
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
    
    // MARK: - Underviser sektion
    private func underviserSektion(navn: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Underviser")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            HStack(alignment: .top, spacing: 14) {
                // Underviser billede
                if let url = event.underviserBilledUrl, !url.isEmpty, let imgUrl = URL(string: url) {
                    AsyncImage(url: imgUrl) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        underviserPlaceholder(navn: navn)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                } else {
                    underviserPlaceholder(navn: navn)
                        .frame(width: 80, height: 80)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(navn)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let beskrivelse = event.underviserBeskrivelse, !beskrivelse.isEmpty {
                        Text(beskrivelse)
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
        .padding(.top, 4)
    }
    
    private func underviserPlaceholder(navn: String) -> some View {
        let initialer = navn.split(separator: " ").compactMap { $0.first }.prefix(2).map(String.init).joined().uppercased()
        return Circle()
            .fill(farve)
            .overlay(
                Text(initialer)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            )
    }
    
    // MARK: - Admin actions
    private var adminActions: some View {
        HStack(spacing: 12) {
            Button(action: { visRedigerSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                    Text("Rediger")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .glassEffect(.regular.interactive().tint(.orange.opacity(0.4)), in: Capsule())
            }
            
            Button(action: { visSletAlert = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                    Text("Slet")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .glassEffect(.regular.interactive().tint(.red.opacity(0.4)), in: Capsule())
            }
        }
    }
    
    // MARK: - Tilmeldingsknap
    private var tilmeldingsKnap: some View {
        Button(action: handleTilmelding) {
            Text(knapTekst)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 58)
                .glassEffect(.regular.interactive().tint(knapFarve), in: Capsule())
        }
        .disabled(event.erFuldtBooket && !erTilmeldt)
    }
    
    private var ikkeTilmeldingPaakraevet: some View {
        HStack {
            Image(systemName: "info.circle.fill")
            Text("Ingen tilmelding nødvendig - mød bare op!")
                .font(.system(size: 15, weight: .medium))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, minHeight: 58)
        .glassEffect(.regular.tint(.green.opacity(0.3)), in: Capsule())
    }
    
    private var knapTekst: String {
        if erTilmeldt { return "Afmeld" }
        if event.erFuldtBooket { return "Fuldt booket" }
        return "Tilmeld dig"
    }
    
    private var knapFarve: Color {
        if erTilmeldt { return .red.opacity(0.4) }
        if event.erFuldtBooket { return .gray.opacity(0.4) }
        return farve
    }
    
    // MARK: - Actions
    private func handleTilmelding() {
        Task {
            guard let eventId = event.id,
                  let brugerId = authViewModel.currentUser?.id else { return }
            
            if erTilmeldt {
                let ok = await eventViewModel.afmeldBruger(eventId: eventId, brugerId: brugerId)
                if ok {
                    bekraeftelsesTekst = "Du er nu afmeldt"
                    visBekraeftelse = true
                }
            } else {
                let ok = await eventViewModel.tilmeldBruger(eventId: eventId, brugerId: brugerId)
                if ok {
                    bekraeftelsesTekst = "Du er nu tilmeldt \(event.titel)!"
                    visBekraeftelse = true
                }
            }
        }
    }
    
    private func sletEvent() async {
        guard let eventId = event.id else { return }
        let ok = await eventViewModel.sletEvent(eventId: eventId)
        if ok { dismiss() }
    }
    
    // MARK: - Hjælper
    @ViewBuilder
    private func infoRow(icon: String, titel: String, vaerdi: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(titel)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                Text(vaerdi)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
    }
}

//
//  AdminEventFormView.swift
//  IshojUngdom
//
//  View: Admin formular med pakkeliste (US 24), kategori (US 34), status (US 38)
//

import SwiftUI
import PhotosUI

struct AdminEventFormView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var eventViewModel = EventViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let eksisterendeEvent: Event?
    
    // Grundlæggende
    @State private var titel: String = ""
    @State private var beskrivelse: String = ""
    @State private var lokation: String = ""
    @State private var valgtFarve: String = "blue"
    @State private var valgtKategori: String = "Andet"
    
    // Event billede
    @State private var valgtEventItem: PhotosPickerItem? = nil
    @State private var eventBillede: UIImage? = nil
    @State private var eksisterendeEventBilledUrl: String = ""
    
    // Tid
    @State private var startDato: Date = Date().addingTimeInterval(86400)
    @State private var harSlutDato: Bool = false
    @State private var slutDato: Date = Date().addingTimeInterval(86400 * 30)
    @State private var ugedag: String = ""
    @State private var tidspunkt: String = ""
    @State private var harFeedbackLukker: Bool = false
    @State private var feedbackLukkerDato: Date = Date().addingTimeInterval(86400 * 7)
    
    // Deltagere
    @State private var maxDeltagere: Int = 20
    @State private var aldersgruppeMin: Int = 10
    @State private var aldersgruppeMax: Int = 18
    @State private var kraeverTilmelding: Bool = true
    
    // Status
    @State private var valgtStatus: EventStatus = .aaben
    
    // Underviser
    @State private var underviserNavn: String = ""
    @State private var underviserBeskrivelse: String = ""
    @State private var valgtUnderviserItem: PhotosPickerItem? = nil
    @State private var underviserBillede: UIImage? = nil
    @State private var eksisterendeUnderviserBilledUrl: String = ""
    
    // Pakkeliste
    @State private var pakkeliste: [String] = []
    @State private var nytPakkePunkt: String = ""
    
    @State private var visGemmer = false
    @State private var uploadStatus = ""
    @State private var fejlBesked: String? = nil
    
    private let farveValg = ["blue", "purple", "teal", "orange", "pink"]
    private var erRedigering: Bool { eksisterendeEvent != nil }
    private var formularGyldig: Bool {
        !titel.isEmpty && !beskrivelse.isEmpty && !lokation.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 22) {
                        Spacer().frame(height: 4)
                        
                        // Grundlæggende
                        sektion(titel: "Grundlæggende info") {
                            inputField(label: "Titel", placeholder: "F.eks. CykelVærested", text: $titel)
                            textEditor(label: "Beskrivelse", placeholder: "Beskriv eventet...", text: $beskrivelse)
                            inputField(label: "Lokation", placeholder: "F.eks. Østergården 31", text: $lokation)
                            kategoriVaelger
                            billedeVaelger(
                                label: "Event-billede",
                                billede: $eventBillede,
                                valgtItem: $valgtEventItem,
                                eksisterendeUrl: eksisterendeEventBilledUrl
                            )
                            farveVaelger
                        }
                        
                        // Tid
                        sektion(titel: "Tid og periode") {
                            datoFelt(label: "Startdato", dato: $startDato)
                            
                            Toggle(isOn: $harSlutDato) {
                                Text("Har slutdato").foregroundColor(.white.opacity(0.85)).font(.subheadline)
                            }
                            .tint(.blue)
                            .padding(.horizontal, 18).padding(.vertical, 14)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                            
                            if harSlutDato {
                                datoFelt(label: "Slutdato", dato: $slutDato)
                            }
                            
                            inputField(label: "Ugedag (valgfri)", placeholder: "F.eks. Hver onsdag", text: $ugedag)
                            inputField(label: "Tidspunkt (valgfri)", placeholder: "F.eks. 15:30 - 18:30", text: $tidspunkt)
                            
                            Toggle(isOn: $harFeedbackLukker) {
                                Text("Lukke for feedback efter dato")
                                    .foregroundColor(.white.opacity(0.85)).font(.subheadline)
                            }
                            .tint(.blue)
                            .padding(.horizontal, 18).padding(.vertical, 14)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                            
                            if harFeedbackLukker {
                                datoFelt(label: "Feedback lukker", dato: $feedbackLukkerDato)
                            }
                        }
                        
                        // Deltagere
                        sektion(titel: "Deltagere") {
                            Toggle(isOn: $kraeverTilmelding) {
                                Text("Kræver tilmelding").foregroundColor(.white.opacity(0.85)).font(.subheadline)
                            }
                            .tint(.blue)
                            .padding(.horizontal, 18).padding(.vertical, 14)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                            
                            if kraeverTilmelding {
                                stepperFelt(label: "Max deltagere", vaerdi: $maxDeltagere, range: 1...100)
                            }
                            HStack(spacing: 12) {
                                stepperFelt(label: "Min. alder", vaerdi: $aldersgruppeMin, range: 0...30)
                                stepperFelt(label: "Max. alder", vaerdi: $aldersgruppeMax, range: 0...30)
                            }
                        }
                        
                        // Status (kun ved redigering)
                        if erRedigering {
                            sektion(titel: "Status") {
                                statusVaelger
                            }
                        }
                        
                        // Pakkeliste (US 24)
                        sektion(titel: "Pakkeliste (valgfri)") {
                            pakkelisteSektion
                        }
                        
                        // Underviser
                        sektion(titel: "Underviser (valgfri)") {
                            inputField(label: "Navn", placeholder: "F.eks. Christian Genz", text: $underviserNavn)
                            textEditor(label: "Om underviseren", placeholder: "Kort beskrivelse...", text: $underviserBeskrivelse)
                            billedeVaelger(
                                label: "Billede af underviser",
                                billede: $underviserBillede,
                                valgtItem: $valgtUnderviserItem,
                                eksisterendeUrl: eksisterendeUnderviserBilledUrl
                            )
                        }
                        
                        if !uploadStatus.isEmpty {
                            HStack(spacing: 8) {
                                ProgressView().tint(.white.opacity(0.7))
                                Text(uploadStatus).foregroundColor(.white.opacity(0.7)).font(.footnote)
                            }
                        }
                        
                        if let fejl = fejlBesked {
                            Text(fejl).foregroundColor(.red).font(.footnote)
                        }
                        
                        Button(action: { Task { await gemEvent() } }) {
                            if visGemmer {
                                HStack(spacing: 10) {
                                    ProgressView().tint(.white)
                                    Text(uploadStatus.isEmpty ? "Gemmer..." : uploadStatus)
                                        .foregroundColor(.white).font(.system(size: 16))
                                }
                                .frame(maxWidth: .infinity, minHeight: 58)
                                .glassEffect(.regular.interactive(), in: Capsule())
                            } else {
                                Text(erRedigering ? "Gem ændringer" : "Opret event")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 58)
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
            .navigationTitle(erRedigering ? "Rediger event" : "Nyt event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuller") { dismiss() }.foregroundColor(.white)
                }
            }
            .onAppear {
                if let e = eksisterendeEvent { indlaesEventData(e) }
            }
        }
    }
    
    // MARK: - Kategori vælger
    private var kategoriVaelger: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kategori").foregroundColor(.white.opacity(0.85)).font(.subheadline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EventKategori.alle, id: \.self) { kategori in
                        Button(action: { valgtKategori = kategori }) {
                            Text(kategori)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(valgtKategori == kategori ? .white : .white.opacity(0.7))
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .glassEffect(
                                    valgtKategori == kategori
                                        ? .regular.tint(.blue.opacity(0.5))
                                        : .regular,
                                    in: Capsule()
                                )
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
    
    // MARK: - Status vælger
    private var statusVaelger: some View {
        VStack(spacing: 0) {
            ForEach(EventStatus.allCases, id: \.self) { status in
                Button(action: { valgtStatus = status }) {
                    HStack(spacing: 10) {
                        Circle().fill(statusColor(status)).frame(width: 10, height: 10)
                        Text(status.rawValue)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                        Spacer()
                        if valgtStatus == status {
                            Image(systemName: "checkmark").foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                }
                if status != EventStatus.allCases.last {
                    Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                }
            }
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
    }
    
    private func statusColor(_ s: EventStatus) -> Color {
        switch s {
        case .aaben: return .green
        case .faaPladser: return .orange
        case .lukket: return .gray
        case .aflyst: return .red
        }
    }
    
    // MARK: - Pakkeliste sektion (US 24)
    private var pakkelisteSektion: some View {
        VStack(spacing: 12) {
            // Eksisterende punkter
            if !pakkeliste.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(pakkeliste.enumerated()), id: \.offset) { idx, punkt in
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green.opacity(0.7))
                                .font(.system(size: 14))
                            Text(punkt)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { pakkeliste.remove(at: idx) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red.opacity(0.7))
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        if idx < pakkeliste.count - 1 {
                            Divider().background(Color.white.opacity(0.1)).padding(.leading, 14)
                        }
                    }
                }
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
            }
            
            // Nyt punkt
            HStack(spacing: 10) {
                TextField("", text: $nytPakkePunkt,
                          prompt: Text("F.eks. Madpakke, badetøj...")
                            .foregroundColor(.white.opacity(0.4)))
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .tint(.white)
                    .textContentType(.none)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                
                Button(action: tilfojPunkt) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
                .disabled(nytPakkePunkt.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
    
    private func tilfojPunkt() {
        let punkt = nytPakkePunkt.trimmingCharacters(in: .whitespaces)
        if !punkt.isEmpty {
            pakkeliste.append(punkt)
            nytPakkePunkt = ""
        }
    }
    
    // MARK: - Billede vælger
    @ViewBuilder
    private func billedeVaelger(
        label: String,
        billede: Binding<UIImage?>,
        valgtItem: Binding<PhotosPickerItem?>,
        eksisterendeUrl: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).foregroundColor(.white.opacity(0.85)).font(.subheadline)
            
            if let img = billede.wrappedValue {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(maxWidth: .infinity).frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    HStack(spacing: 8) {
                        PhotosPicker(selection: valgtItem, matching: .images) {
                            Text("Skift")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .glassEffect(.regular.tint(.blue.opacity(0.4)), in: Capsule())
                        }
                        Button(action: {
                            billede.wrappedValue = nil
                            valgtItem.wrappedValue = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22)).foregroundColor(.white)
                        }
                    }
                    .padding(10)
                }
            } else if !eksisterendeUrl.isEmpty {
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: eksisterendeUrl)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.white.opacity(0.1))
                            .overlay(ProgressView().tint(.white))
                    }
                    .frame(maxWidth: .infinity).frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    PhotosPicker(selection: valgtItem, matching: .images) {
                        Text("Skift billede")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .glassEffect(.regular.tint(.blue.opacity(0.4)), in: Capsule())
                            .padding(10)
                    }
                }
            } else {
                PhotosPicker(selection: valgtItem, matching: .images) {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.badge.plus").font(.system(size: 22))
                        Text("Vælg billede").font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 70)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .onChange(of: valgtItem.wrappedValue) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    billede.wrappedValue = img
                }
            }
        }
    }
    
    // MARK: - UI helpers
    @ViewBuilder
    private func sektion<Content: View>(titel: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(titel).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                .padding(.horizontal, 4)
            content()
        }
    }
    
    private var farveVaelger: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Farve-tag").foregroundColor(.white.opacity(0.85)).font(.subheadline)
            HStack(spacing: 12) {
                ForEach(farveValg, id: \.self) { farve in
                    Button(action: { valgtFarve = farve }) {
                        Circle().fill(farveTilColor(farve)).frame(width: 44, height: 44)
                            .overlay(Circle().stroke(Color.white, lineWidth: valgtFarve == farve ? 3 : 0))
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
        }
    }
    
    @ViewBuilder
    private func datoFelt(label: String, dato: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).foregroundColor(.white.opacity(0.85)).font(.subheadline)
            DatePicker("", selection: dato, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact).colorScheme(.dark).labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18).padding(.vertical, 12)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
        }
    }
    
    @ViewBuilder
    private func stepperFelt(label: String, vaerdi: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label).foregroundColor(.white.opacity(0.85)).font(.subheadline)
                Spacer()
                Text("\(vaerdi.wrappedValue)").foregroundColor(.white).font(.system(size: 16, weight: .semibold))
            }
            HStack(spacing: 12) {
                Button(action: { if vaerdi.wrappedValue > range.lowerBound { vaerdi.wrappedValue -= 1 } }) {
                    Image(systemName: "minus").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                        .frame(width: 38, height: 38).glassEffect(.regular.interactive(), in: Circle())
                }
                Slider(value: Binding(get: { Double(vaerdi.wrappedValue) }, set: { vaerdi.wrappedValue = Int($0) }),
                       in: Double(range.lowerBound)...Double(range.upperBound), step: 1).tint(.blue)
                Button(action: { if vaerdi.wrappedValue < range.upperBound { vaerdi.wrappedValue += 1 } }) {
                    Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                        .frame(width: 38, height: 38).glassEffect(.regular.interactive(), in: Circle())
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
        }
    }
    
    @ViewBuilder
    private func inputField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).foregroundColor(.white.opacity(0.85)).font(.subheadline)
            TextField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
                .textFieldStyle(.plain).foregroundColor(.white).tint(.white).textContentType(.none)
                .padding(.horizontal, 18).padding(.vertical, 16)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
        }
    }
    
    @ViewBuilder
    private func textEditor(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).foregroundColor(.white.opacity(0.85)).font(.subheadline)
            ZStack(alignment: .topLeading) {
                TextEditor(text: text)
                    .scrollContentBackground(.hidden).background(Color.clear)
                    .foregroundColor(.white).tint(.white).frame(minHeight: 100)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                if text.wrappedValue.isEmpty {
                    Text(placeholder).foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 22).padding(.vertical, 18).allowsHitTesting(false)
                }
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
        }
    }
    
    // MARK: - Indlæs data
    private func indlaesEventData(_ event: Event) {
        titel = event.titel
        beskrivelse = event.beskrivelse
        lokation = event.lokation
        valgtFarve = event.farveTag
        valgtKategori = event.kategori ?? "Andet"
        eksisterendeEventBilledUrl = event.billedUrl ?? ""
        startDato = event.startDato
        if let slut = event.slutDato { harSlutDato = true; slutDato = slut }
        ugedag = event.ugedag ?? ""
        tidspunkt = event.tidspunkt ?? ""
        if let fl = event.feedbackLukkerDato { harFeedbackLukker = true; feedbackLukkerDato = fl }
        maxDeltagere = event.maxDeltagere
        aldersgruppeMin = event.aldersgruppeMin
        aldersgruppeMax = event.aldersgruppeMax
        kraeverTilmelding = event.kraeverTilmelding
        valgtStatus = event.eventStatus
        underviserNavn = event.underviserNavn ?? ""
        underviserBeskrivelse = event.underviserBeskrivelse ?? ""
        eksisterendeUnderviserBilledUrl = event.underviserBilledUrl ?? ""
        pakkeliste = event.pakkeliste ?? []
    }
    
    // MARK: - Gem
    private func gemEvent() async {
        visGemmer = true
        fejlBesked = nil
        
        var eventBilledUrl = eksisterendeEventBilledUrl
        if let billede = eventBillede {
            uploadStatus = "Uploader event-billede..."
            if let url = await CloudinaryService.uploadBillede(billede: billede, mappe: "events") {
                eventBilledUrl = url
            }
        }
        
        var uBilledUrl = eksisterendeUnderviserBilledUrl
        if let billede = underviserBillede {
            uploadStatus = "Uploader billede af underviser..."
            if let url = await CloudinaryService.uploadBillede(billede: billede, mappe: "undervisere") {
                uBilledUrl = url
            }
        }
        
        uploadStatus = erRedigering ? "Gemmer ændringer..." : "Opretter event..."
        
        let event = Event(
            id: eksisterendeEvent?.id,
            titel: titel,
            beskrivelse: beskrivelse,
            lokation: lokation,
            farveTag: valgtFarve,
            billedUrl: eventBilledUrl.isEmpty ? nil : eventBilledUrl,
            kategori: valgtKategori,
            startDato: startDato,
            slutDato: harSlutDato ? slutDato : nil,
            ugedag: ugedag.isEmpty ? nil : ugedag,
            tidspunkt: tidspunkt.isEmpty ? nil : tidspunkt,
            feedbackLukkerDato: harFeedbackLukker ? feedbackLukkerDato : nil,
            maxDeltagere: maxDeltagere,
            antalTilmeldte: eksisterendeEvent?.antalTilmeldte ?? 0,
            aldersgruppeMin: aldersgruppeMin,
            aldersgruppeMax: aldersgruppeMax,
            kraeverTilmelding: kraeverTilmelding,
            underviserNavn: underviserNavn.isEmpty ? nil : underviserNavn,
            underviserBeskrivelse: underviserBeskrivelse.isEmpty ? nil : underviserBeskrivelse,
            underviserBilledUrl: uBilledUrl.isEmpty ? nil : uBilledUrl,
            pakkeliste: pakkeliste.isEmpty ? nil : pakkeliste,
            status: erRedigering ? valgtStatus.rawValue : nil
        )
        
        let success = erRedigering
            ? await eventViewModel.opdaterEvent(event)
            : await eventViewModel.opretEvent(event)
        
        visGemmer = false
        uploadStatus = ""
        
        if success { dismiss() }
        else { fejlBesked = eventViewModel.errorMessage ?? "Noget gik galt" }
    }
    
    private func farveTilColor(_ tag: String) -> Color {
        switch tag {
        case "blue": return .blue
        case "purple": return .purple
        case "teal": return .teal
        case "orange": return .orange
        case "pink": return .pink
        default: return .gray
        }
    }
}

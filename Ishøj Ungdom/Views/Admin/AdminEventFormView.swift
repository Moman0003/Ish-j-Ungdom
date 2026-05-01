//
//  AdminEventFormView.swift
//  IshojUngdom
//
//  View: Admin formular med Cloudinary billedupload
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
    
    // Deltagere
    @State private var maxDeltagere: Int = 20
    @State private var aldersgruppeMin: Int = 10
    @State private var aldersgruppeMax: Int = 18
    @State private var kraeverTilmelding: Bool = true
    
    // Underviser
    @State private var underviserNavn: String = ""
    @State private var underviserBeskrivelse: String = ""
    @State private var valgtUnderviserItem: PhotosPickerItem? = nil
    @State private var underviserBillede: UIImage? = nil
    @State private var eksisterendeUnderviserBilledUrl: String = ""
    
    @State private var visGemmer: Bool = false
    @State private var uploadStatus: String = ""
    @State private var fejlBesked: String?
    
    private let farveValg = ["blue", "purple", "teal", "orange", "pink"]
    private var erRedigering: Bool { eksisterendeEvent != nil }
    private var formularGyldig: Bool {
        !titel.isEmpty && !beskrivelse.isEmpty && !lokation.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 22) {
                        Spacer().frame(height: 4)
                        
                        // Sektion 1: Grundlæggende
                        sektion(titel: "Grundlæggende info") {
                            inputField(label: "Titel", placeholder: "F.eks. CykelVærested", text: $titel)
                            textEditor(label: "Beskrivelse", placeholder: "Beskriv eventet...", text: $beskrivelse)
                            inputField(label: "Lokation", placeholder: "F.eks. Østergården 31", text: $lokation)
                            billedeVaelger(
                                label: "Event-billede",
                                billede: $eventBillede,
                                valgtItem: $valgtEventItem,
                                eksisterendeUrl: eksisterendeEventBilledUrl
                            )
                            farveVaelger
                        }
                        
                        // Sektion 2: Tid
                        sektion(titel: "Tid og periode") {
                            datoFelt(label: "Startdato", dato: $startDato)
                            
                            Toggle(isOn: $harSlutDato) {
                                Text("Har slutdato")
                                    .foregroundColor(.white.opacity(0.85))
                                    .font(.subheadline)
                            }
                            .tint(.blue)
                            .padding(.horizontal, 18).padding(.vertical, 14)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                            
                            if harSlutDato {
                                datoFelt(label: "Slutdato", dato: $slutDato)
                            }
                            inputField(label: "Ugedag (valgfri)", placeholder: "F.eks. Hver onsdag", text: $ugedag)
                            inputField(label: "Tidspunkt (valgfri)", placeholder: "F.eks. 15:30 - 18:30", text: $tidspunkt)
                        }
                        
                        // Sektion 3: Deltagere
                        sektion(titel: "Deltagere") {
                            Toggle(isOn: $kraeverTilmelding) {
                                Text("Kræver tilmelding")
                                    .foregroundColor(.white.opacity(0.85))
                                    .font(.subheadline)
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
                        
                        // Sektion 4: Underviser
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
                        
                        // Status og fejl
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
                        
                        // Gem knap
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
    
    // MARK: - Billede vælger
    @ViewBuilder
    private func billedeVaelger(
        label: String,
        billede: Binding<UIImage?>,
        valgtItem: Binding<PhotosPickerItem?>,
        eksisterendeUrl: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .foregroundColor(.white.opacity(0.85))
                .font(.subheadline)
            
            if let img = billede.wrappedValue {
                // Nyt billede valgt - vis preview
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
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
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(10)
                }
            } else if !eksisterendeUrl.isEmpty {
                // Eksisterende Cloudinary billede
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: eksisterendeUrl)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.white.opacity(0.1))
                            .overlay(ProgressView().tint(.white))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
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
                // Intet billede endnu
                PhotosPicker(selection: valgtItem, matching: .images) {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 22))
                        Text("Vælg billede")
                            .font(.system(size: 16, weight: .medium))
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
    
    // MARK: - Gem event med Cloudinary upload
    private func gemEvent() async {
        visGemmer = true
        fejlBesked = nil
        
        // Upload event-billede hvis nyt er valgt
        var eventBilledUrl = eksisterendeEventBilledUrl
        if let billede = eventBillede {
            uploadStatus = "Uploader event-billede..."
            if let url = await CloudinaryService.uploadBillede(billede: billede, mappe: "events") {
                eventBilledUrl = url
            } else {
                fejlBesked = "Kunne ikke uploade event-billede - tjek din internetforbindelse"
                visGemmer = false
                uploadStatus = ""
                return
            }
        }
        
        // Upload underviser-billede hvis nyt er valgt
        var uBilledUrl = eksisterendeUnderviserBilledUrl
        if let billede = underviserBillede {
            uploadStatus = "Uploader billede af underviser..."
            if let url = await CloudinaryService.uploadBillede(billede: billede, mappe: "undervisere") {
                uBilledUrl = url
            } else {
                fejlBesked = "Kunne ikke uploade underviser-billede"
                visGemmer = false
                uploadStatus = ""
                return
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
            startDato: startDato,
            slutDato: harSlutDato ? slutDato : nil,
            ugedag: ugedag.isEmpty ? nil : ugedag,
            tidspunkt: tidspunkt.isEmpty ? nil : tidspunkt,
            maxDeltagere: maxDeltagere,
            antalTilmeldte: eksisterendeEvent?.antalTilmeldte ?? 0,
            aldersgruppeMin: aldersgruppeMin,
            aldersgruppeMax: aldersgruppeMax,
            kraeverTilmelding: kraeverTilmelding,
            underviserNavn: underviserNavn.isEmpty ? nil : underviserNavn,
            underviserBeskrivelse: underviserBeskrivelse.isEmpty ? nil : underviserBeskrivelse,
            underviserBilledUrl: uBilledUrl.isEmpty ? nil : uBilledUrl
        )
        
        let success = erRedigering
            ? await eventViewModel.opdaterEvent(event)
            : await eventViewModel.opretEvent(event)
        
        visGemmer = false
        uploadStatus = ""
        
        if success { dismiss() }
        else { fejlBesked = eventViewModel.errorMessage ?? "Noget gik galt" }
    }
    
    // MARK: - Indlæs eksisterende data
    private func indlaesEventData(_ event: Event) {
        titel = event.titel
        beskrivelse = event.beskrivelse
        lokation = event.lokation
        valgtFarve = event.farveTag
        eksisterendeEventBilledUrl = event.billedUrl ?? ""
        startDato = event.startDato
        if let slut = event.slutDato { harSlutDato = true; slutDato = slut }
        ugedag = event.ugedag ?? ""
        tidspunkt = event.tidspunkt ?? ""
        maxDeltagere = event.maxDeltagere
        aldersgruppeMin = event.aldersgruppeMin
        aldersgruppeMax = event.aldersgruppeMax
        kraeverTilmelding = event.kraeverTilmelding
        underviserNavn = event.underviserNavn ?? ""
        underviserBeskrivelse = event.underviserBeskrivelse ?? ""
        eksisterendeUnderviserBilledUrl = event.underviserBilledUrl ?? ""
    }
    
    // MARK: - UI komponenter
    @ViewBuilder
    private func sektion<Content: View>(titel: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(titel).font(.system(size: 18, weight: .bold)).foregroundColor(.white).padding(.horizontal, 4)
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

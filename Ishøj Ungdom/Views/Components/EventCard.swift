//
//  EventCard.swift
//  IshojUngdom
//
//  Component: Event-kort med status, kategori og favorit-knap
//

import SwiftUI

struct EventCard: View {
    let event: Event
    var erFavorit: Bool = false
    var paaToggleFavorit: (() -> Void)? = nil
    
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
    
    private var statusFarve: Color {
        switch event.eventStatus {
        case .aaben:      return .green
        case .faaPladser: return .orange
        case .lukket:     return .gray
        case .aflyst:     return .red
        }
    }
    
    private var formateretDato: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "da_DK")
        f.dateFormat = "d. MMM"
        return f.string(from: event.startDato)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Billede header
            if let url = event.billedUrl, !url.isEmpty, let imgUrl = URL(string: url) {
                AsyncImage(url: imgUrl) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(farve)
                }
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.bottom, 14)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Top: dato + aldersgruppe + favorit
                HStack {
                    Text(formateretDato)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .glassEffect(.regular.tint(farve), in: Capsule())
                    
                    Text(event.aldersgruppeTekst)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .glassEffect(.regular, in: Capsule())
                    
                    Spacer()
                    
                    if let paaToggleFavorit = paaToggleFavorit {
                        Button(action: { paaToggleFavorit() }) {
                            Image(systemName: erFavorit ? "heart.fill" : "heart")
                                .font(.system(size: 18))
                                .foregroundColor(erFavorit ? .red : .white.opacity(0.7))
                        }
                    }
                }
                
                // Status-badge (kun hvis ikke åben)
                if event.eventStatus != .aaben {
                    HStack(spacing: 6) {
                        Circle().fill(statusFarve).frame(width: 8, height: 8)
                        Text(event.eventStatus.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(statusFarve)
                    }
                }
                
                // Titel (streget over hvis aflyst)
                Text(event.titel)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .strikethrough(event.erAflyst, color: .red)
                    .lineLimit(2)
                
                // Kategori
                if let kategori = event.kategori, !kategori.isEmpty {
                    Text(kategori)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                Text(event.beskrivelse)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    Text(event.lokation)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                    
                    if let ugedag = event.ugedag, !ugedag.isEmpty {
                        Text("•").foregroundColor(.white.opacity(0.4))
                        Text(ugedag)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(farve.opacity(0.3)), in: RoundedRectangle(cornerRadius: 20))
    }
}

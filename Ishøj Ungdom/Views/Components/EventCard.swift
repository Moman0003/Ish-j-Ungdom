//
//  EventCard.swift
//  IshojUngdom
//
//  Component: Event-boks med Liquid Glass effekt
//

import SwiftUI

struct EventCard: View {
    let event: Event
    
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
    
    private var formateretDato: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "da_DK")
        f.dateFormat = "d. MMM"
        return f.string(from: event.startDato)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Billede header (hvis URL findes)
            if let url = event.billedUrl, !url.isEmpty, let imgUrl = URL(string: url) {
                AsyncImage(url: imgUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
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
                HStack {
                    Text(formateretDato)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .glassEffect(.regular.tint(farve), in: Capsule())
                    
                    // Aldersgruppe tag
                    Text(event.aldersgruppeTekst)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .glassEffect(.regular, in: Capsule())
                    
                    Spacer()
                    
                    // Status
                    if event.kraeverTilmelding {
                        if event.erFuldtBooket {
                            Text("Fuldt booket")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.red.opacity(0.9))
                        } else {
                            Text("\(event.ledigPladser) pladser")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    } else {
                        Text("Bare mød op")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green.opacity(0.9))
                    }
                }
                
                Text(event.titel)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
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
                        Text("•")
                            .foregroundColor(.white.opacity(0.4))
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

//
//  TomTilstand.swift
//  IshojUngdom
//
//  Component: Hjælpsomme tomme tilstande (US 61)
//

import SwiftUI

struct TomTilstand: View {
    let ikon: String
    let titel: String
    let undertekst: String
    
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: ikon)
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.35))
            
            Text(titel)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
            
            Text(undertekst)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

// Foruddefinerede tom-tilstande
extension TomTilstand {
    static var ingenEvents: TomTilstand {
        TomTilstand(
            ikon: "calendar.badge.exclamationmark",
            titel: "Ingen events lige nu",
            undertekst: "Hold øje for nye spændende aktiviteter!"
        )
    }
    
    static var ingenTilmeldinger: TomTilstand {
        TomTilstand(
            ikon: "ticket",
            titel: "Du er ikke tilmeldt noget endnu",
            undertekst: "Find et event og tilmeld dig - der er masser at vælge imellem!"
        )
    }
    
    static var ingenSoegeResultater: TomTilstand {
        TomTilstand(
            ikon: "magnifyingglass",
            titel: "Ingen resultater",
            undertekst: "Prøv et andet søgeord eller fjern filtrene."
        )
    }
    
    static var tomNewsfeed: TomTilstand {
        TomTilstand(
            ikon: "bubble.left.and.bubble.right",
            titel: "Tomt newsfeed",
            undertekst: "Bliv den første til at dele en oplevelse!"
        )
    }
    
    static var ingenFavoritter: TomTilstand {
        TomTilstand(
            ikon: "heart",
            titel: "Ingen favoritter endnu",
            undertekst: "Tryk på hjertet ved et event for at gemme det her."
        )
    }
    
    static var ingenBeskeder: TomTilstand {
        TomTilstand(
            ikon: "envelope",
            titel: "Ingen beskeder",
            undertekst: "Beskeder fra ungdomsskolen dukker op her."
        )
    }
}

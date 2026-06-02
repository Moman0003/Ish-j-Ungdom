//
//  ExportService.swift
//  IshojUngdom
//
//  Service: Eksporterer data til CSV (US 57)
//

import Foundation
import UIKit

class ExportService {
    
    /// Eksporterer tilmeldte til CSV og returnerer fil-URL
    static func eksporterTilmeldteCSV(
        eventTitel: String,
        tilmeldte: [(navn: String, email: String, alder: Int?, tilmeldt: Date)]
    ) -> URL? {
        
        // CSV header
        var csv = "Navn,Email,Alder,Tilmeldingstidspunkt\n"
        
        let datoFormatter = DateFormatter()
        datoFormatter.locale = Locale(identifier: "da_DK")
        datoFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for t in tilmeldte {
            let navn = escapeCSV(t.navn)
            let email = escapeCSV(t.email)
            let alder = t.alder.map { String($0) } ?? ""
            let tilmeldt = datoFormatter.string(from: t.tilmeldt)
            csv += "\(navn),\(email),\(alder),\(tilmeldt)\n"
        }
        
        // Skriv til temp-fil
        let filnavn = "tilmeldte-\(reneFilNavn(eventTitel)).csv"
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(filnavn)
        
        do {
            try csv.write(to: tempUrl, atomically: true, encoding: .utf8)
            return tempUrl
        } catch {
            print("CSV fejl: \(error)")
            return nil
        }
    }
    
    private static func escapeCSV(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            let escaped = s.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return s
    }
    
    private static func reneFilNavn(_ s: String) -> String {
        return s.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .components(separatedBy: CharacterSet.alphanumerics.union(.init(charactersIn: "-")).inverted)
            .joined()
    }
}

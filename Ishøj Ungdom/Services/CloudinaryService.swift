//
//  CloudinaryService.swift
//  IshojUngdom
//
//  Service: Håndterer upload af billeder til Cloudinary
//  Bruger unsigned upload preset - ingen API secret eksponeres
//

import Foundation
import UIKit

class CloudinaryService {
    
    // ⚠️ UDFYLD JERES EGNE VÆRDIER HER:
    static let cloudName = "dppd2lrpn"      // F.eks. "dxyz1234"
    static let uploadPreset = "ishoj_ungdom"     // Det preset I oprettede
    
    // Cloudinary upload URL
    private static var uploadUrl: String {
        "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload"
    }
    
    // MARK: - Upload billede til Cloudinary
    /// Uploader et UIImage og returnerer den offentlige URL
    static func uploadBillede(
        billede: UIImage,
        mappe: String = "events",
        fremgang: @escaping (String) -> Void = { _ in }
    ) async -> String? {
        
        // 1. Komprimer og skaler billede ned
        fremgang("Forbereder billede...")
        guard let komprimeret = komprimerBillede(billede) else {
            print("Cloudinary: Kunne ikke komprimere billede")
            return nil
        }
        
        // 2. Byg multipart form-data request
        fremgang("Uploader billede...")
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: uploadUrl)!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Upload preset felt
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(uploadPreset)\r\n".data(using: .utf8)!)
        
        // Mappe felt (organiserer billeder i Cloudinary)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"folder\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(mappe)\r\n".data(using: .utf8)!)
        
        // Selve billedet
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"billede.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(komprimeret)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // 3. Send request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Cloudinary: HTTP fejl - \(String(data: data, encoding: .utf8) ?? "ukendt")")
                return nil
            }
            
            // 4. Parse URL fra svar
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let secureUrl = json["secure_url"] as? String {
                fremgang("Upload fuldført!")
                return secureUrl
            }
            
        } catch {
            print("Cloudinary upload fejl: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // MARK: - Komprimer billede
    private static func komprimerBillede(_ billede: UIImage) -> Data? {
        // Skaler ned til max 1000px på longest side
        let skaleret = skalerBillede(billede, maxDimension: 1000)
        
        // Prøv progressive komprimeringsgrader
        for kvalitet in [0.7, 0.5, 0.3] {
            if let data = skaleret.jpegData(compressionQuality: kvalitet) {
                // Cloudinary gratis tier: ingen fil-størrelsesgrænse bekymring
                return data
            }
        }
        return billede.jpegData(compressionQuality: 0.3)
    }
    
    private static func skalerBillede(_ billede: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = billede.size
        guard size.width > maxDimension || size.height > maxDimension else { return billede }
        
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let nySize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: nySize)
        return renderer.image { _ in
            billede.draw(in: CGRect(origin: .zero, size: nySize))
        }
    }
}

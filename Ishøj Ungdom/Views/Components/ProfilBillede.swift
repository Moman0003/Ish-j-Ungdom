//
//  ProfilBillede.swift
//  IshojUngdom
//
//  Component: Cirkulært profilbillede med initialer som fallback
//

import SwiftUI

struct ProfilBillede: View {
    let url: String?
    let initialer: String
    var stoerrelse: CGFloat = 40
    var farve: Color = .blue
    
    var body: some View {
        Group {
            if let url = url, !url.isEmpty, let imgUrl = URL(string: url) {
                AsyncImage(url: imgUrl) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    initialerView
                }
                .frame(width: stoerrelse, height: stoerrelse)
                .clipShape(Circle())
            } else {
                initialerView
                    .frame(width: stoerrelse, height: stoerrelse)
            }
        }
        .accessibilityLabel("Profilbillede")
    }
    
    private var initialerView: some View {
        Circle()
            .fill(farve.opacity(0.4))
            .overlay(
                Text(initialer)
                    .font(.system(size: stoerrelse * 0.4, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}

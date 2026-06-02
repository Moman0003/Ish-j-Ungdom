//
//  StjerneVurdering.swift
//  IshojUngdom
//
//  Component: Interaktiv stjernevurdering
//

import SwiftUI

struct StjerneVurdering: View {
    @Binding var stjerner: Int
    var maxStjerner: Int = 5
    var stoerrelse: CGFloat = 30
    var laesKun: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...maxStjerner, id: \.self) { i in
                Image(systemName: i <= stjerner ? "star.fill" : "star")
                    .font(.system(size: stoerrelse))
                    .foregroundColor(i <= stjerner ? .yellow : .white.opacity(0.3))
                    .onTapGesture {
                        if !laesKun {
                            stjerner = i
                        }
                    }
                    .accessibilityLabel("\(i) ud af \(maxStjerner) stjerner")
            }
        }
    }
}

// Vises som tekst: 4.2 ★
struct StjerneSnit: View {
    let snit: Double
    let antalVurderinger: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            Text(String(format: "%.1f", snit))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Text("(\(antalVurderinger))")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

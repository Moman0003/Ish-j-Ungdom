//
//  FilterView.swift
//  IshojUngdom
//
//  View: Filter sheet med alder, dato og kategori (US 32, 33, 34)
//

import SwiftUI

struct FilterView: View {
    @ObservedObject var viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Aldersgruppe (US 32)
                        sektion(titel: "Aldersgruppe") {
                            Toggle(isOn: $viewModel.filterAldersgruppe) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Kun events for min aldersgruppe")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("Filtrer baseret på din indtastede alder")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            .tint(.blue)
                            .padding(.horizontal, 16).padding(.vertical, 14)
                        }
                        
                        // Dato (US 33)
                        sektion(titel: "Periode") {
                            VStack(spacing: 0) {
                                ForEach(DatoFilter.allCases, id: \.self) { filter in
                                    Button(action: {
                                        viewModel.filterDato = filter
                                    }) {
                                        HStack {
                                            Text(filter.rawValue)
                                                .font(.system(size: 15))
                                                .foregroundColor(.white)
                                            Spacer()
                                            if viewModel.filterDato == filter {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.horizontal, 16).padding(.vertical, 14)
                                    }
                                    if filter != DatoFilter.allCases.last {
                                        Divider().background(Color.white.opacity(0.1))
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                        }
                        
                        // Kategorier (US 34)
                        sektion(titel: "Kategorier") {
                            VStack(spacing: 0) {
                                ForEach(EventKategori.alle, id: \.self) { kategori in
                                    Button(action: {
                                        if viewModel.filterKategorier.contains(kategori) {
                                            viewModel.filterKategorier.remove(kategori)
                                        } else {
                                            viewModel.filterKategorier.insert(kategori)
                                        }
                                    }) {
                                        HStack {
                                            Text(kategori)
                                                .font(.system(size: 15))
                                                .foregroundColor(.white)
                                            Spacer()
                                            if viewModel.filterKategorier.contains(kategori) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.blue)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(.white.opacity(0.3))
                                            }
                                        }
                                        .padding(.horizontal, 16).padding(.vertical, 12)
                                    }
                                    if kategori != EventKategori.alle.last {
                                        Divider().background(Color.white.opacity(0.1))
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                        }
                        
                        // Nulstil
                        Button(action: {
                            viewModel.nulstilFiltre()
                        }) {
                            Text("Nulstil alle filtre")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .glassEffect(.regular.interactive().tint(.orange.opacity(0.15)), in: Capsule())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Filtrer events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Anvend") { dismiss() }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    @ViewBuilder
    private func sektion<Content: View>(titel: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titel)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 4)
                .textCase(.uppercase)
            
            VStack(spacing: 0) {
                content()
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.top, 8)
    }
}

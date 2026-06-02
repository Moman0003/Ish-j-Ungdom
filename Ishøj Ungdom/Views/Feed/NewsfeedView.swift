//
//  NewsfeedView.swift
//  IshojUngdom
//
//  View: Newsfeed med opslag (US 28, 29, 30, 52, 53)
//

import SwiftUI

struct NewsfeedView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = NewsfeedViewModel()
    
    @State private var visNytOpslag = false
    @State private var nytOpslagSheetId = UUID()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.12)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.isLoading && viewModel.opslag.isEmpty {
                            ProgressView()
                                .tint(.white)
                                .padding(.top, 100)
                        } else if viewModel.opslag.isEmpty {
                            TomTilstand.tomNewsfeed
                                .padding(.top, 80)
                        } else {
                            ForEach(viewModel.opslag) { opslag in
                                OpslagCard(opslag: opslag, viewModel: viewModel)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Newsfeed")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        nytOpslagSheetId = UUID()
                        visNytOpslag = true
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Nyt opslag")
                }
            }
            .sheet(isPresented: $visNytOpslag) {
                NytOpslagView()
                    .id(nytOpslagSheetId)
                    .environmentObject(authViewModel)
            }
            .task {
                await viewModel.hentOpslag()
            }
            .refreshable {
                await viewModel.hentOpslag()
            }
        }
    }
}

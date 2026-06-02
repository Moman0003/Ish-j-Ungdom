//
//  LoginView.swift
//  IshojUngdom
//
//  View: Login med Glemt adgangskode link (US 45)
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var visGlemtPassword: Bool = false
    
    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 60)
                    
                    VStack(spacing: 6) {
                        Text("Velkommen tilbage")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("Log ind på din konto")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 20)
                    
                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .foregroundColor(.white.opacity(0.85))
                            .font(.subheadline)
                        TextField("", text: $email,
                                  prompt: Text("din@email.dk").foregroundColor(.white.opacity(0.4)))
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .tint(.white)
                            .textContentType(.none)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 18).padding(.vertical, 16)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                    }
                    
                    // Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Adgangskode")
                            .foregroundColor(.white.opacity(0.85))
                            .font(.subheadline)
                        SecureField("", text: $password,
                                    prompt: Text("Min. 6 tegn").foregroundColor(.white.opacity(0.4)))
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .tint(.white)
                            .textContentType(.none)
                            .padding(.horizontal, 18).padding(.vertical, 16)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                    }
                    
                    // Glemt adgangskode link (US 45)
                    HStack {
                        Spacer()
                        Button(action: { visGlemtPassword = true }) {
                            Text("Glemt adgangskode?")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.blue.opacity(0.9))
                        }
                    }
                    
                    if let fejl = authViewModel.errorMessage {
                        Text(fejl)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: { Task { await authViewModel.login(email: email, password: password) } }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .glassEffect(.regular.interactive(), in: Capsule())
                        } else {
                            Text("Log ind")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .glassEffect(.regular.interactive().tint(.blue.opacity(0.4)), in: Capsule())
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                    .opacity((email.isEmpty || password.isEmpty) ? 0.5 : 1.0)
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $visGlemtPassword) {
            NavigationStack {
                GlemtPasswordView()
                    .environmentObject(authViewModel)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Luk") { visGlemtPassword = false }.foregroundColor(.white)
                        }
                    }
            }
        }
    }
}

//
//  LoginView.swift
//  IshojUngdom
//
//  View: Login-formular med Liquid Glass design
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.10, blue: 0.12)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Log ind")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                Spacer().frame(height: 20)
                
                // Email felt
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .foregroundColor(.white.opacity(0.85))
                        .font(.subheadline)
                    
                    TextField("", text: $email, prompt: Text("din@email.dk")
                        .foregroundColor(.white.opacity(0.4)))
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .tint(.white)
                        .keyboardType(.emailAddress)
                        .textContentType(.none)            // Slår autofill fra
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                }
                
                // Password felt
                VStack(alignment: .leading, spacing: 8) {
                    Text("Adgangskode")
                        .foregroundColor(.white.opacity(0.85))
                        .font(.subheadline)
                    
                    SecureField("", text: $password, prompt: Text("••••••••")
                        .foregroundColor(.white.opacity(0.4)))
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .tint(.white)
                        .textContentType(.none)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                }
                
                // Fejlbesked
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }
                
                // Login knap
                Button(action: {
                    Task {
                        await authViewModel.login(email: email, password: password)
                    }
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity, minHeight: 58)
                            .glassEffect(.regular.interactive(), in: Capsule())
                    } else {
                        Text("Log ind")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 58)
                            .glassEffect(.regular.interactive().tint(.blue.opacity(0.4)), in: Capsule())
                    }
                }
                .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                .opacity((email.isEmpty || password.isEmpty) ? 0.5 : 1.0)
                .padding(.top, 8)
                
                Spacer()
            }
            .padding(.horizontal, 30)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}

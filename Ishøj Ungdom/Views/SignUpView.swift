//
//  SignUpView.swift
//  IshojUngdom
//
//  View: Opret bruger-formular med Liquid Glass design
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var navn: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var bekraeftPassword: String = ""
    
    private var passwordsMatcher: Bool {
        !password.isEmpty && password == bekraeftPassword
    }
    
    private var formularGyldig: Bool {
        !navn.isEmpty && !email.isEmpty && passwordsMatcher && password.count >= 6
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.10, blue: 0.12)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("Opret bruger")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Spacer().frame(height: 8)
                    
                    // Navn
                    glassInputField(label: "Navn", placeholder: "Dit fulde navn", text: $navn)
                    
                    // Email
                    glassInputField(label: "Email", placeholder: "din@email.dk", text: $email, keyboardType: .emailAddress)
                    
                    // Password
                    glassSecureField(label: "Adgangskode", placeholder: "Min. 6 tegn", text: $password)
                    
                    // Bekræft password
                    glassSecureField(label: "Bekræft adgangskode", placeholder: "Gentag adgangskode", text: $bekraeftPassword)
                    
                    // Validering
                    if !bekraeftPassword.isEmpty && !passwordsMatcher {
                        Text("Adgangskoderne matcher ikke")
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                    
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Opret knap med Liquid Glass
                    Button(action: {
                        Task {
                            await authViewModel.opretBruger(email: email, password: password, navn: navn)
                        }
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity, minHeight: 58)
                                .glassEffect(.regular.interactive(), in: Capsule())
                        } else {
                            Text("Opret bruger")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 58)
                                .glassEffect(.regular.interactive().tint(.blue.opacity(0.4)), in: Capsule())
                        }
                    }
                    .disabled(!formularGyldig || authViewModel.isLoading)
                    .opacity(formularGyldig ? 1.0 : 0.5)
                    .padding(.top, 12)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    // Genbrugelig Liquid Glass input felt
    @ViewBuilder
    private func glassInputField(label: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .foregroundColor(.white.opacity(0.85))
                .font(.subheadline)
            
            TextField("", text: text, prompt: Text(placeholder)
                .foregroundColor(.white.opacity(0.5)))
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .tint(.white)
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                .disableAutocorrection(keyboardType == .emailAddress)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
        }
    }
    
    @ViewBuilder
    private func glassSecureField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .foregroundColor(.white.opacity(0.85))
                .font(.subheadline)
            
            SecureField("", text: text, prompt: Text(placeholder)
                .foregroundColor(.white.opacity(0.5)))
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .tint(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}

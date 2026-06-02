//
//  SignUpView.swift
//  IshojUngdom
//
//  View: Opret bruger med alder (US 32 - bruges til filter)
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var navn: String = ""
    @State private var email: String = ""
    @State private var alder: String = ""
    @State private var password: String = ""
    @State private var bekraeftPassword: String = ""
    
    private var formularGyldig: Bool {
        !navn.isEmpty && !email.isEmpty && password.count >= 6 && password == bekraeftPassword
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 18) {
                    Spacer().frame(height: 40)
                    
                    VStack(spacing: 6) {
                        Text("Opret konto")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("Bliv en del af Ishøj Ungdomsskole")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 14)
                    
                    inputFelt(label: "Navn", placeholder: "Dit fulde navn", text: $navn)
                    
                    inputFelt(
                        label: "Email",
                        placeholder: "din@email.dk",
                        text: $email,
                        keyboard: .emailAddress
                    )
                    
                    inputFelt(
                        label: "Alder",
                        placeholder: "F.eks. 15",
                        text: $alder,
                        keyboard: .numberPad
                    )
                    
                    secureFelt(label: "Adgangskode", placeholder: "Min. 6 tegn", text: $password)
                    
                    secureFelt(label: "Bekræft adgangskode", placeholder: "Gentag adgangskoden", text: $bekraeftPassword)
                    
                    // Match-indikator
                    if !bekraeftPassword.isEmpty && password != bekraeftPassword {
                        Text("Adgangskoderne matcher ikke")
                            .font(.footnote)
                            .foregroundColor(.orange)
                    }
                    
                    if let fejl = authViewModel.errorMessage {
                        Text(fejl)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        Task {
                            await authViewModel.opretBruger(
                                email: email,
                                password: password,
                                navn: navn,
                                alder: Int(alder)
                            )
                        }
                    }) {
                        if authViewModel.isLoading {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .glassEffect(.regular.interactive(), in: Capsule())
                        } else {
                            Text("Opret konto")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .glassEffect(.regular.interactive().tint(.purple.opacity(0.4)), in: Capsule())
                        }
                    }
                    .disabled(!formularGyldig || authViewModel.isLoading)
                    .opacity(formularGyldig ? 1.0 : 0.5)
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    @ViewBuilder
    private func inputFelt(label: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .foregroundColor(.white.opacity(0.85))
                .font(.subheadline)
            TextField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .tint(.white)
                .textContentType(.none)
                .keyboardType(keyboard)
                .autocapitalization(keyboard == .emailAddress ? .none : .words)
                .disableAutocorrection(keyboard == .emailAddress)
                .padding(.horizontal, 18).padding(.vertical, 16)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
        }
    }
    
    @ViewBuilder
    private func secureFelt(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .foregroundColor(.white.opacity(0.85))
                .font(.subheadline)
            SecureField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .tint(.white)
                .textContentType(.none)
                .padding(.horizontal, 18).padding(.vertical, 16)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}
